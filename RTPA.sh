#!/bin/bash
#=============================================================================================================================================================================
#
# FILE NAME - RTPA.sh
#
# DESCRIPTION - Does all system monitoring checks needed for a server to be released to production. If you can read the "Proceeding." message after a check, then all is good.
#
# USAGE - ./rtpa.sh -check (to run the script). -help (for basic information (just ./rtpa.sh prints this out). 
#
# Author - bknNick
#
# Note - I am not a programmer. Functionality is what this is built for.
#
#=============================================================================================================================================================================
#
#Need to add hpasmcli, ssacli, hpacucli
#Need to add error file for summary of the script? (I.E. total number of errors, errors include:)
#App versions are static, so change from here when a change is needed as it's quicker due to them being global variables:
#hpasmxld|hpasmlited|hpasmd are running! Please check! - change this to should be running on physical servers.
#
#=============================================================================================================================================================================

ScriptVersion="RTPA.sh v1.02"
NewestOSVersion="7.9"
NewestHPOAversion="12.15"
CBLowestAcceptibleVersion="6.3.4.10012"

DiscUsageThreshold=80 #Change the number so that it matches filesystem usages above the number. I.E., if FS A is more than
#$DiscUsageThreshold, then FSUsage will do it's checks on that filesystem.

#Every check is made with functions. "Config" for the "modules" can be done from here.
#At the bottom you'll find a function, which calls all checking modules.
#If you need to disable a check, scroll down to the "LoadModules" function and comment the one which you don't need from there.

#Spit out info for the script:

Greeting(){

        printf "RTPA.sh - !THIS IS ABANDONED! OVO AND ALL OF ITS SUBSYSTEMS ARE BEING UPDATED WITH A NEW SYSTEM!\n\nRTPA checks for lazy agents. Written by dxnickd to automate the RTPA checks as much as possible. Please report any issues or suggestions to me.\n\nTo run the script use the -check option (i.e. './RTPA -check').\n\nVersion can be checked by running './RTPA.sh -version'.\n"

}

#Separates different checks in the output:

WhiteNoise(){

        printf "\n###############################################################################################################################################\n\n"

}

#Redhat release check (Note, some of the static values as $NewestOSVersion are found at the top of the script for easier edit):

OSCheck(){

        WhiteNoise

        local OSversion=$(awk '{print $7}' /etc/redhat-release)

        printf "\nChecking OS version: \n"

        #need to change below notequal to less than.

        if [ "$OSversion" != "$NewestOSVersion" ]; then
                printf "\nOS Version is not latest! Current version is: $OSversion , while latest version is $NewestOSVersion\n"
        else
                printf "\nOS version is latest. Proceeding: \n\n"
        fi

        WhiteNoise

}

#Checks the HPOA version:

HPOACheck(){

        local HPOAversion="$(opcagt -version | cut -d "." -f 1,2)"

        printf "\nChecking HPOA version: \n"

        if which opcagt &>/dev/null; then

                #need to change below if to less than
                if [ "$HPOAversion" != "$NewestHPOAversion" ]; then
                        printf "\nHPOA version is not latest! Current version is: $HPOAversion , while newest version is $NewestHPOAversion\n"
                else
                        printf "\nHPOA version is latest. Proceeding: \n\n"
                fi
        else
                printf "\nOPCagt not found. Please make sure HPOA is installed."
        fi

        WhiteNoise

}

#Displays IP addresses of the server, so we can copy paste check with ESL if they are the same:

IPCheck(){

        printf "\nIPS: \n"

        printf "\nIP addresses are (youre gonna have to manually check with ESL if these match... bare with me untill I find a fix for this please.): \n"

        ip a | grep "inet" |awk '{print $2}' | grep -v "127.0.0.1" | grep -v "^192.168" | grep -v "^10."| grep -v "^172.16" | grep -v ":" | cut -d '/' -f 1

        WhiteNoise

}

#Checks /opt/OV/bin/opcagt -status for stopped processes, or buffering.

OPC(){

        printf "\nChecking opcagt agents status: \n"

        if which opcagt &>/dev/null; then

        local OPCAGT=$(/opt/OV/bin/opcagt -status | grep -ve "Running" -ve "Message Agent is not buffering.")

                if [[ -z $OPCAGT ]]; then

                        printf "\nOPCagt is fine. Proceeding.\n"
                else
                        printf "\nOPCagt Issues detected! \n\n"
                        /opt/OV/bin/opcagt -status
                fi
        else
                printf "\nOPCagt not found. Please make sure HPOA is installed."
        fi

        WhiteNoise

}

#Checks if UXMON .cfg files exist.

uxmonCFGcheck(){

        printf "\nChecking UXMON config files. \n"

        if [ ! -d /var/opt/OV/conf/OpC/ ]; then
                printf '/var/opt/OV/conf/OpC/ not found. UXMON monitoring probably not installed.'
        else
                printf "\nThese are the available UXMON config files: \n\n"
                ls -la /var/opt/OV/conf/OpC/

                if ! ls -la /var/opt/OV/conf/OpC/ | awk '{print $9}' | grep -xq df_mon.cfg || ! ls -la /var/opt/OV/conf/OpC/ | awk '{print $9}' | grep -xq ps_mon.cfg; then
                        printf "\nPlease note that df_mon.cfg, or ps_mon.cfg are missing! \n"

                elif [[ -f /var/opt/OV/conf/OpC/df_mon.cfg && -f /var/opt/OV/conf/OpC/ps_mon.cfg ]]; then
                        printf "\nBoth df_mon.cfg and psmon_cfg are present. Proceeding.\n"

                fi
        fi

        WhiteNoise

}

#Does a check for all filesystems if they exceed $DiscUsageThreshold, if they do, then prints them out and finds the largest files in
#that filesystem. Can probably be done in fewer lines, but left it at this for now.

FSUsage(){

        tempfilez="$(grep $(logname) /etc/passwd | cut -d ":" -f 6)/temp.txt"

        ErrorsFile="$(grep $(logname) /etc/passwd | cut -d ":" -f 6)/errors.txt"

        printf "\nChecking filesystem statuses.\n"

        df -h | grep -v Mounted |awk '{print $6 "," $5}'| cut -d % -f 1 > $tempfilez

        for percentusage in $(cat $tempfilez); do
                if (( $(echo $percentusage | cut -d "," -f 2) >= $DiscUsageThreshold )); then
                        grep "$(echo $percentusage)" $tempfilez | cut -d "," -f 1 >> $ErrorsFile;
                fi;
        done

        if [ ! -f $ErrorsFile ]; then
                echo "No Disc usage issues detected. Proceeding."
        else
                printf "\nDisc Usage issues located in the following FS': \n"
                cat $ErrorsFile
                for FS in $(cat $ErrorsFile); do
                        printf "\nThe usage of $FS is currently: $(df -h $FS | grep -vi use | awk '{print $5}' | cut -d "%" -f 1)."
                        printf "\n\nFor the filesystem "$FS", the largest files can be found below: \n\n"
                                for i in $(find $FS -xdev -type f -size +1000000c -exec du -m {} \; 2>/dev/null | sort -n -k 1 | tail -20 | awk {'print ($2)'}); do
                                        ls -l --block-size=M -a $i;
                                done
                done
        fi

        rm -f $tempfilez $ErrorsFile

WhiteNoise

#can probably rewrite this to make it shorter, dno

}

#Checks if root login is disabled in /etc/ssh/sshd_config... :

RootLogin(){

        printf "\nChecking if Root login is disabled.\n"

        if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
                echo "Root login is disabled. Proceeding"
        else
                echo "PermitRootLogin is not disabled! Please check!"
        fi

        WhiteNoise

}

#Checks Carbon Black version. If it starts with 7, then proceeds with version is 7+, otherwise we need to check, as there's no suitable
#tool to check floats in bash.. or at least couldn't think of one.

CB(){

        printf "\nChecking CB version.\n"

        local CBVersion=$(echo $(cbdaemon -v) |awk '{print $3}')
        local CBRelease=$(echo $(cbdaemon -v) |awk '{print $3}' | cut -d "." -f 1)

        if [ $CBRelease -gt 6 ]; then

                printf "\nCarbon Black is version 7+. Proceeding.\n"

        else

                printf "\nCarbon Black version is: $CBVersion, $CBLowestAcceptibleVersion is the minimal.\n"

        fi

        WhiteNoise

}

#Basically ssh to the ovo server and run a super nrr.pl. Asks for your user's password when attempting to ssh to the ovo server.
#Some hosts don't recognize the ovo hostname, so if that's the case, feed it with hostnames (like i did in "grep estrella" line).
#Some servers for some reason don't have direct ssh access to OVO, need to find a work-around (For example, it tries an ssh to estrella, but times out).

OVOCheck(){

        printf "\nChecking if OVO server has connection to this server.\n"

        local OvoServer=$(ovconfget | grep -i manager= | cut -d "=" -f2)
        printf "\nThe management server is: $OvoServer \n\nAttempting connection: \n\n"
        if  echo $OvoServer | grep -qi estrella; then
                local OvoServer=192.151.66.24;
                #Add more host resolutions with elifs if needed for other monitoring servers.
        fi
        printf "\nNRR.PL From OVO server. Use your users ERM password to connect to the OVO server when prompted. \n"
        ssh $(logname)@$OvoServer "super nrr.pl -cs $(hostname) | grep 'Monitoring Status:'" 2>/dev/null || printf "\nCould not connect to server, most likely there's an isuse with DNS resolution.\n\n"

        WhiteNoise
}

#Checks for the serial number of the server, so we can check if it matches with ESL. If its virtual, skips.

SerialNumber(){

        local SN=$(dmidecode | grep "System Information" -A 8 | grep -i serial)
        printf "\nChecking Serial Number of the server: \n"
        if echo $SN | grep -q VMware; then
                printf "\nServer is virtual. Proceeding.\n"
        else
                printf "\n\nSerial Number is: $SN \n\n"
                read -p "Does it match? (y/n): " SNCheck
                if [[ $SNCheck = "y" || $SNCheck = "yes" ]]; then
                        printf "\nProceeding.\n"
                else
                        printf "\nSerial Numbers do not match.\n"
                fi

        fi

        WhiteNoise

}

#Checks if all available filesystems are being monitored by dfmon. Turns out, this isn't really needed, but already wrote it so.. :

FSMonitoring(){

#Checks if all Filesystems are being monitored by df_mon.
        printf "\nChecking if all filesystems are being monitored by dfmon.\n"

        dfmonchecks="$(grep $(logname) /etc/passwd | cut -d ":" -f 6)/dfmonchecks.txt"

        actualfs="$(grep $(logname) /etc/passwd | cut -d ":" -f 6)/actualsystemfs.txt"

        dif="$(grep $(logname) /etc/passwd | cut -d ":" -f 6)/differences.txt"

        grep -v "^#" /var/opt/OV/conf/OpC/df_mon.cfg | awk '{print $1}' | sort -u | grep -vi linux | sort > $dfmonchecks || echo "/var/opt/OV/conf/OpC/df_mon.cfg does not exist! Cannot the config with the filesystems!"

        df -h | grep -v tmpfs |awk '{print $6}' | sort | grep -vi mounted > $actualfs

        diff $dfmonchecks $actualfs > $dif

        if  echo $(cat $dif) | grep -qx '1d0 <'; then
                echo "All filesystems are being monitored. Proceeding."
        else
                echo "Not all filesystems are being monitored."
        fi

        rm -f $dfmonchecks $actualfs $dif

        WhiteNoise

}

#Runs UXMONbroker -d $module and checks for errors.

UXMON(){

        local dfmon=$(/var/opt/OV/bin/instrumentation/UXMONbroker -d dfmon | grep -i logged | grep -ve "is running" | grep -v end)
        local psmon=$(/var/opt/OV/bin/instrumentation/UXMONbroker -d psmon | grep -i logged | grep -ve "is running" | grep -v end)
        local volmon=$(/var/opt/OV/bin/instrumentation/UXMONbroker -d volmon | grep -i logged | grep -ve "is running" | grep -v end)
        local sgmon=$(/var/opt/OV/bin/instrumentation/UXMONbroker -d sgmon | grep -i logged | grep -ve "is running" | grep -v end)
        local ntmon=$(/var/opt/OV/bin/instrumentation/UXMONbroker -d ntpmon | grep -i logged | grep -ve "is running" | grep -v end)

        printf "\nChecking for any outstanding monitoring issues.\n"

        printf "\nDFMON check: \n"
        if [[ -z $dfmon ]]; then
                echo "No dfmon errors. Proceeding."
        else
                echo $dfmon
        fi

        printf "\nPSMON check: \n"
        if [[ -z $psmon ]]; then
                echo "No psmon errors. Proceeding."
        else
                echo $psmon
        fi

        printf "\nVOLMON check: \n"
        if [[ -z $volmon ]]; then
                echo "No volmon errors. Proceeding."
        else
                echo $volmon
        fi

        printf "\nSGMON check: \n"

        if [[ -z $sgmon ]]; then
                echo "No sgmon errors. Proceeding."
        else
                echo $sgmon
        fi

        printf "\nNTPMON check: \n"
        if [[ -z $ntmon ]]; then
                echo "No ntpmon errors. Proceeding."
        else
                echo $ntpmon
        fi


        WhiteNoise

}

#Checks if logrotation is enabled in cron:

LogrotateCron(){

        printf "\nChecking if Logrotate is configured as a cronjob:\n\n"

        local LR=$(grep logrotate /etc/cron.daily/* | grep -v "^#")

        if [[ -z $LR ]]; then
                echo "logrotate not set as a Cronjob!"
        else

                printf "\n\nLogrotate is configured as a cronjob. Proceeding.\n"

        fi

        WhiteNoise
}

#Checks if there's an entry for osit in crontab. No idea what this is, but was in the instructions:

OsitCron(){

        printf "\nChecking if Osit is configured as a cronjob: \n\n"

        local osit=$(crontab -l | grep -i osit | grep -v "^#")

        if [[ -z $osit ]]; then
                echo "Osit is not configured as a Cronjob!"

        else
        echo "Osit is configured as a cronjob. Proceeding."

        fi

        WhiteNoise

}

#Checks if opsware agent processes are running:

OPSWprocess(){

        local OPSW=$(ps -ef | grep opsw|grep -v grep)
        echo "Checking if OPSW process is running."

        if [[ -z OPSW ]]; then
                echo "OPSW process is not running!"
        else
                printf "\n\nOPSW is running. Proceeding."
        fi

        WhiteNoise

}

#No idea what hpasmxld, etc. are, but it was in the instructions, so.. :

HPASM(){

        local hpasm=$(ps -ef | egrep 'hpasmxld|hpasmlited|hpasmd' | grep -v grep)

        printf "\nChecking if hpasmxld|hpasmlited|hpasmd are running.\n\n"

        if [[ -z $hpasm ]]; then
                echo "Not running. Proceeding."
        else
                echo "hpasmxld|hpasmlited|hpasmd are running! Please check!"
        fi

        WhiteNoise
}

#Notes at the end, so we have a plan of action after local server checks are done.

ImportantFYI(){

        printf "\n\n\n\n!!!!!!!!!!!!!!!!!!!!!!!! DON'T FORGET TO CHECK !!!!!!!!!!!!!!!!!!!!!!!!\n\n\n\n"
        printf "Does general tab have all instructions on how to log in / from where to log in etc?\n"
        printf "\nDo the contacts have our information for support?\n"
        printf "\nDoes Security tab in ESL have our groups?\n"
        printf "\nRemote access information, is it enough?\n"
        printf "\nDo you have access to the Vcenter?\n\n"

}

#Checks if ntpd is running and if so checks if it's in sync (doesnt check for delay, as that's checked by ntpmon).

ntp(){

        printf "\nChecking if the NTP service is ok.\n\n"

        if systemctl is-active --quiet ntpd; then
                echo "NTPD is running. Checking if it's in sync."
                        if ntpq -pn | grep -q '*'; then
                                echo "NTPD is in sync'd to a server. Proceeding."
                        else
                                echo "NTPD is not in sync to a server! Please check!"
                        fi
        else
                echo "NTPD is not running!"
        fi

        WhiteNoise

}

#/opt/perf/bin/perfstat error checking:

Perfstat(){

        printf "\nChecking Perfstat agents status.\n\n"

        local Perf=$(/opt/perf/bin/perfstat | grep -i stopped)

        if [[ -z $Perf ]]; then
                echo "No stopped perfstat agents found. Proceeding."
        else
                echo "Perfstat stopped agents found!"
                /opt/perf/bin/perfstat
        fi

        WhiteNoise

}

#/opt/osit/acf/acf.sh error checking:
#acf currently throws a weird output :
#The following ACF errors were encountered!
#Mon.
#

acf(){

        printf "\nChecking ACF status.\n"

        tempfile="$(grep $(logname) /etc/passwd | cut -d ":" -f 6)/acf.txt"
        tempfile2="$(grep $(logname) /etc/passwd | cut -d ":" -f 6)/acf2.txt"

        /opt/osit/acf/acf.sh -t > $tempfile

        grep -A 20 "Module " $tempfile >> $tempfile2
        grep -B 20 "TOTAL" $tempfile >> $tempfile2

        local ACF=$(grep -ive ok -ive module -ive "-" -ive "total" $tempfile2 | sort -u)

        if [[ -z $ACF ]]; then
                echo "No ACF errors found. Proceeding."
        else
                echo "The following ACF errors were encountered!"
                printf "\n$ACF\n"
        fi

        rm -f $tempfile $tempfile2

        WhiteNoise

}

#Check if there are any read only Filesystems.. duh

RoFS(){

        printf "\nChecking for read only filesystems.\n"

        local RO=$(grep ro, /proc/mounts | grep -v tmpfs)

        if [[ -z $RO ]]; then
                printf "\nNo Read only filesystems found. Proceeding.\n"
        else
                printf "\nThe following filesystems are read only!\n\n"
                prinft "$RO \n"
        fi

        WhiteNoise

}

#Temp file cleanup on signals:

cleanup(){

rm -f $tempfile $tempfile2 $dfmonchecks $actualfs $dif $tempfilez $ErrorsFile
exit 1

}

trap cleanup 2 3 4 9 15

#Disable checks from below LoadModules by commenting out the ones which are not needed.

#Half of the below functions are using OVO which will be obsoleted soon. Will need to either rewrite the whole script after I have more information on the new system, or
#abandon this project all together :/

LoadModules(){
        OSCheck
        HPOACheck #need to fix version check from -ne to -lt
        CB
        OPC
        OPSWprocess
        Perfstat
        acf
        uxmonCFGcheck
        UXMON
        ntp
        FSMonitoring
        FSUsage
        RoFS
        RootLogin
        LogrotateCron
        OsitCron
        IPCheck
        OVOCheck
        SerialNumber
        HPASM
        ImportantFYI
}

#At some point i may want to add different options for the script (maybe '$0 -check --fssage' only does the FS usage check? Idk
#put this here as an idea. Added some generic options so it exists:

case "$1" in

        -version)
        echo $ScriptVersion
        ;;

        "-check")
        LoadModules
        ;;

        "")
        Greeting
        ;;

        "-help")
        Greeting
        ;;
        *)
        echo "Currently only the '-version' '-help' and '-check' options are supported."
        ;;
esac
