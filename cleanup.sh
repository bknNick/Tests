#!/bin/bash
#uninstall all from initialization script.

read -p "input target server ip: " IPADDR
ssh $IPADDR 'yum remove fail2ban -y && yum remove mysql -y && yum remove httpd -y && yum remove zip -y && rm -rf /root/own* && rm -rf /var/www/html/wordpress || echo "breaks on removing wordpress and ends." && rm -rf /var/www/html/*  || echo "breaks on deleting * from html and ends here." && rm -rf /var/www/html/latest.zip && yum remove php -y && yum remove perl -y && yum remove php-mysqlnd -y && yum clean all'
