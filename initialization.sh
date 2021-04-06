#!/bin/bash
#Initialization script for new servers
#can add python

##################################### HOW TO USE
#$0 $ip (example /bin/bash /root/ownscripts/owninit*.sh 192.168.10.123)

clear
read -p "Enter the IP address: " host




################################################### DIYmon #######################################################################################################################
                                                                                                                                                                                ##
#Install DIYmon                                                                                                                                                                 ##
DIYmonInstallation(){                                                                                                                                                           ##
printf "\nChecking if DIYmon exists \n"                                                                                                                                         ##
if ssh root@$host 'test -d /root/ownscripts/DIYmonitoring/DIYmon && test -f /root/ownscripts/DIYmonitoring/ownmon.sh && test -f /root/ownscripts/DIYmonitoring//ownmon.lib';    ##
then                                                                                                                                                                            ##
printf "\nNothing to do. DIYmon already installed.\n"                                                                                                                           ##
else                                                                                                                                                                            ##
ssh root@$host 'mkdir -p /root/ownscripts/DIYmonitoring/'                                                                                                                       ##
rsync -avz /root/ownscripts/DIYmonitoring/* root@$host:/root/ownscripts/DIYmonitoring/;                                                                                         ##
fi                                                                                                                                                                              ##
}                                                                                                                                                                               ##
##################################################################################################################################################################################



################################################### Groot User ###################################################################################################################
                                                                                                                                                                                ##
#change groot user UID & GID to 0                                                                                                                                               ##
#ssh root@host "echo "$(grep -v "^groot:" /etc/passwd)" >> /var/test/psswd_test_clone && echo "groot:x:0:0:OUR ROOT USER:/home/groot:/bin/bash" >> /var/test/psswd_test_clone"  ##
                                                                                                                                                                                ##
##################################################################################################################################################################################


################################################## Install packets #######################################
                                                                                                        ##
#Install necessary packets:                                                                             ##
#ssh root@$1 'yum update && yum install fail2ban telnet net-tools sysstat epel-release lynis -y'        ##
                                                                                                        ##
##########################################################################################################



################################################### FAIL2BAN #############################################
                                                                                                        ##
#initialize fail2ban                                                                                    ##
                                                                                                        ##
Fail2BanInstallation(){                                                                                 ##
                                                                                                        ##
printf "\nChecking if fail2ban is installed\n"                                                          ##
if ssh root@$host 'yum list installed fail2ban > /dev/null';                                            ##
then                                                                                                    ##
printf "\nNothing to do. fail2ban is installed. Checking status:\n\n"                                   ##
ssh root@$host 'systemctl status fail2ban | grep active'                                                ##
else                                                                                                    ##
                                                                                                        ##
#Install $SERVICE                                                                                       ##
ssh root@$host 'yum install fail2ban -y'                                                                ##
                                                                                                        ##
#Enable service                                                                                         ##
ssh root@$host 'systemctl enable fail2ban'                                                              ##
                                                                                                        ##
#configure service files                                                                                ##
                                                                                                        ##
        if ! ssh root@$host 'test -d /var/run/fail2ban'; then                                           ##
        ssh root@$host 'mkdir /var/run/fail2ban';                                                       ##
        fi                                                                                              ##
                                                                                                        ##
#Start the service                                                                                      ##
ssh root@$host 'systemctl start fail2ban'                                                               ##
ssh root@$host 'systemctl status fail2ban'                                                              ##
                                                                                                        ##
fi                                                                                                      ##
                                                                                                        ##
}                                                                                                       ##
                                                                                                        ##
##########################################################################################################


#Enable/Disable installation times by commenting out the functions below

DIYmonInstallation
Fail2BanInstallation
