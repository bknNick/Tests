#!/bin/bash

#############################################################################################################################################################
##---------------------------------------------------------------------DIY MONITORING----------------------------------------------------------------------##
#############################################################################################################################################################

#############################################################################################################################################################
## Monitoring script, does a check in real time on most monitored resources and provides feedback related to them. This is meant to be run as root until I ##
## find a work-around for sudo (as soon as I stop being lazy about it at least).                                                                           ##
##                                                                                                                                                         ##
## Obviously done by Nick D., as these lazy asses wouldn't be bothered with such things -_- (talking to you Steve & George).                               ##
##                                                                                                                                                         ##
## If no output is returned, then all is working as intended.                                                                                              ##
#############################################################################################################################################################

##THRESHOLDS IN PERCENTAGES, EDIT HERE!:
DiscUsageThreshold=70
InodeUsageThreshold=70
FreeMemThreshold=10

FSmonitoring(){
####### DISC usage monitoring - checks the filesystems, and if any usage issues are detected, provides a list with the largest files.

        for fsusage in $(df -h | awk '{print $5}' | grep -vi "use" | cut -d "%" -f 1); do
                if (( $fsusage >= $DiscUsageThreshold )); then
                        echo ""
                        echo "FS issue detected in the following FS', please review! :"
                        echo "$(df -h | grep "$fsusage"%)"
                        echo ""
                        echo "The largest files can be found below:"
                        echo ""
                        for DiscUsageFile in $(find / -type f -size +1000000c -exec du -m {} \; 2>/dev/null | sort -n -k 1 | tail -20 | awk {'print ($2)'});
                                do ls -l --block-size=M -a $DiscUsageFile
                        done
                        echo ""
                fi
        done

######## INODE usage monitoring - same as the above, but prints out a list with the directories using the most inodes.
        for iusage in $(df -i | awk '{print $5}' | grep -vi "use" | cut -d "%" -f 1); do
                if (( $iusage >= $InodeUsageThreshold )); then
                        echo ""
                        echo "Inode issue detected in the following FS', please review! :"
                        echo "$(df -i | grep "$iusage"%)"
                        echo ""
                        echo "Directories with the most inodes on the system can be found below:"
                        find / -xdev -printf '%h\n' | sort | uniq -c | sort -k 1 -n | tail -20
                        echo ""
                fi
        done

####### Read only FS check
        local RO=$(grep "ro," /proc/mounts| grep -vi tmpfs)
        if [[ $RO ]]; then
                echo ""
                echo "Read only filesystem detected!"
                echo $RO
                echo ""
        fi
}

FSmonitoring

MEMmonitoring(){
####### Free MEMORY monitoring - checks the memory usage, if above threshold, provides a list with the top memory consuming processes.

        local FreeMem=$(free -m | grep -i "mem" | awk '{print ($4 * 100 / $2)}' | cut -d "." -f 1)
        if (( $FreeMem <= $FreeMemThreshold )); then
                echo ""
                echo "Memory issue detected! Free memory is only $FreeMem%!"
                echo ""
                echo "The highest memory consuming processes can be found below:"
                ps -eo pid,ppid,stat,vsz,rss,comm --sort=rss | tail -20
        fi
}
MEMmonitoring


SvcsMonitoring(){
####### Services monitoring - checks if services are running, if not tries to start them.

#HTTPD CHECK:
        local ApacheDown=$(/bin/systemctl status httpd | grep -i "Active: inactive (dead)")
        local ApacheStart="/bin/systemctl start httpd"
        local ApacheStatus="/bin/systemctl status httpd"
        if [[ $ApacheDown ]]; then
                echo ""
                echo "HTTPD service was stopped. Trying to start it..."
                $ApacheStart > /dev/null
                wait
                local ApacheDown=$(/bin/systemctl status httpd | grep -i "Active: inactive (dead)")
                if [[ $ApacheDown ]]; then
                        echo ""
                        echo "HTTPD issue detected. Please review!"
                        echo ""
                        $ApacheStatus
                        echo ""
                elif [[ ! $ApacheDown ]]; then
                        echo "Httpd successfully started."
                        echo ""
                fi
        fi

#MySQL Check:
        local MySQLDown=$(/bin/systemctl status mysqld | grep -i "Active: inactive (dead)")
        local MySQLStart="/bin/systemctl start mysqld"
        local MySQLStatus="/bin/systemctl status mysqld"
        if [[ $MySQLDown ]]; then
                echo ""
                echo "MySQL service was stopped. Trying to start it..."
                $MySQLStart > /dev/null
                wait
                local MySQLDown=$(/bin/systemctl status mysqld | grep -i "Active: inactive (dead)")
                if [[ $MySQLDown ]]; then
                        echo ""
                        echo "MySQL issue detected. Please review!"
                        echo ""
                        $MySQLStatus
                        echo ""
                elif [[ ! $MySQLDown ]]; then
                        echo "MySQL successfully started."
                        echo ""
                fi
        fi

}

SvcsMonitoring

#SystemCheck(){
####### This will do a check of the resources and give feedback if anything needs to be maintained etc.
#}
