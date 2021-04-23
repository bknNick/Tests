#!/bin/bash
#Initialization script for new servers


##################################### HOW TO USE
#$0 $ip (example /bin/bash /root/ownscripts/owninit*.sh 192.168.10.123)

###########################################################################################################################################################################
############################################################# CONFIGURATION LOCATED AT THE BOTTOM OF THE PAGE #############################################################
###########################################################################################################################################################################


clear
read -p "Enter the IP address: " host


#Install DIYmon

DIYmonInstallation(){

printf "\nChecking if DIYmon exists \n"
if ssh root@$host 'test -d /root/ownscripts/DIYmonitoring && test -f /root/ownscripts/DIYmonitoring/ownmon.sh && test -f /root/ownscripts/DIYmonitoring/ownmon.lib';
then
echo "Nothing to do. DIYmon already installed."
else
echo "installing DIYmon files."
ssh root@$host 'mkdir -p /root/ownscripts/DIYmonitoring/'
rsync -avz /root/ownscripts/DIYmonitoring/* root@$host:/root/ownscripts/DIYmonitoring/ >/dev/null
fi

}

################################################### Groot User ###################################################################################################################
                                                                                                                                                                                ##
#change groot user UID & GID to 0                                                                                                                                               ##
#ssh root@host "echo "$(grep -v "^groot:" /etc/passwd)" >> /var/test/psswd_test_clone && echo "groot:x:0:0:OUR ROOT USER:/home/groot:/bin/bash" >> /var/test/psswd_test_clone"  ##
                                                                                                                                                                                ##
##################################################################################################################################################################################

#Needed packets:

ZIP(){
echo "installing ZIP.."
ssh root@$host 'yum install zip -y &>/dev/null || echo "ZIP has already been installed. Nothing to do."'
}

PHP(){
echo "installing PHP.."
ssh root@$host 'yum install php -y &>/dev/null || echo "PHP has already been installed. Nothing to do."'
}

PHP-MYSQL(){
echo "installing PHP-MYSQL.."
ssh root@$host 'yum install php-mysqlnd -y &>/dev/null || echo "PHP-MYSQL has already been installed. Nothing to do."'
}

PERL(){
echo "Installing PERL.."
ssh root@$host 'yum install perl -y &>/dev/null || echo "PERL has already been installed. Nothing to do."'
}

PacketStack(){

ZIP
PHP
PHP-MYSQL
PERL

}

#initialize fail2ban

Fail2BanInstallation(){

printf "\nChecking if fail2ban is installed\n"
if ssh root@$host 'yum list installed fail2ban &> /dev/null';
then
echo "Nothing to do. fail2ban is installed. Checking status:"
ssh root@$host 'systemctl status fail2ban | grep active'
else
echo "installing fail2ban.."
#Install $Fail2ban
ssh root@$host 'yum install fail2ban -y >/dev/null'

#Enable service
ssh root@$host 'systemctl enable fail2ban >/dev/null'
ssh root@$host 'systemctl start fail2ban >/dev/null'
ssh root@$host 'systemctl status fail2ban | grep -i active'

#configure service files

        if ! ssh root@$host 'test -d /var/run/fail2ban'; then
        ssh root@$host 'mkdir /var/run/fail2ban';
        fi

fi
}


#HTTPD initialization

HTTPDInstallation(){

printf "\nChecking if HTTPD is installed\n"
if ssh root@$host 'yum list installed httpd &> /dev/null';
then
echo "Nothing to do. HTTPD is installed. Checking status:"
ssh root@$host 'systemctl status httpd | grep active'
else
echo "installing HTTPD.."
#install HTTPD
ssh root@$host 'yum install httpd -y >/dev/null'

#Enable httpd
ssh root@$host 'systemctl enable httpd'

#Configure service files (at a later point)

#start the service

ssh root@$host 'systemctl start httpd &>/dev/null'
ssh root@$host 'systemctl status httpd | grep -i active'

fi

}


#MySQL initialization

MySQLInstallation(){

printf "\nChecking if MySQL is installed\n"
if ssh root@$host 'yum list installed mysql &> /dev/null &&  yum list installed mysql-server &> /dev/null';
then
echo "Nothing to do. MySQL is installed. Checking status:"
ssh root@$host 'systemctl status mysqld | grep active'
else
echo "installing MySQL.. This may take a while :)"
#install MySQL
ssh root@$host 'yum install mysql -y >/dev/null && yum install mysql-server -y >/dev/null'

#Enable httpd
ssh root@$host 'systemctl enable mysqld >/dev/null'

#Configure service files (at a later point)

#start the service

ssh root@$host 'systemctl start mysqld >/dev/null'
ssh root@$host 'systemctl status mysqld | grep -i active'

fi

}

#install wordpress:

WordPressInstallation(){
if ! ssh root@$host 'test -d /var/www/html/wordpress/'
then
        if ssh root@$host 'yum list installed httpd &> /dev/null && yum list installed mysql &>/dev/null && yum list installed mysql-server &>/dev/null'
        then
        echo "Installing Wordpress.. This is gonna take a long while!"
        ssh root@$host 'cd /var/www/html/ && wget wordpress.org/latest.zip &> /dev/null && unzip /var/www/html/latest.zip &>/dev/null && mv /var/www/html/wordpress/* /var/www/html && rm -rf /var/www/html/wordpress && rm -rf /var/www/html/latest.zip'
        ssh root@$host 'echo "Starting HTTPD.." && service httpd start &>/dev/null || echo "Could not start HTTPD..." && echo "Starting MySQL.." && service mysqld start &>/dev/null || echo "Could not start MySQL..."'
        else
        echo "HTTPD not installed. Installing.."

        HTTPDInstallation
        MySQLInstallation
        WordPressInstallation
        ssh root@$host 'mv /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/welcome.conf.old'
        fi
else
echo "Wordpress already installed. Nothing to do."
fi
}

#Enable/Disable installation times by commenting out the functions below

PacketStack
DIYmonInstallation
Fail2BanInstallation
HTTPDInstallation
MySQLInstallation
WordPressInstallation
