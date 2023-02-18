##      PHPMYADMIN INSTALLATION & SETUP ON ALPINE LINUX WITH LIGHTTPD
# enable community repository
# apk update
# apk add lighttpd php...check other php_setup.sh script for additional packages
# Config lighttpd.conf uncomment the following line:
# include "mod_fastcgi.conf"
# Add lighttpd to runlevel default and start it.
# rc-update add lighttpd && rc-service lighttpd start
# Install MySQL:
# apk add mysql mysql-client php-mysql php-mysqli
# Config Mysql:
# /usr/bin/mysql_install_db --user=mysql
# rc-update add mysql default && /etc/init.d/mysql start
# /usr/bin/mysqladmin -u root password 'password'
#
# Create a directory named webapps
# mkdir -p /usr/share/webapps
# Download the source code
# cd /usr/share/webapps
# wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.tar.gz
# Extract tar file rename extracted phpmyadmin then delete the dlned tar file we don't need that
# tar zxvf phpMyAdmin-5.2.1-all-languages.tar.gz
# Change the Folder Permission
# chmod -R 777 /usr/share/webapps
# Create a symlink to the phpmyadmin
# ln -s /usr/share/webapps/phpmyadmin /var/www/localhost/htdocs/phpmyadmin
# Browse to: http://WEBSERVER_IP_ADDRESS/phpmyadmin and logon to phpMyAdmin using your MySQL user and password.
