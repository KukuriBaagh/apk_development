## This script is drived from Alpine Linux Documentation: the link is here: https://wiki.alpinelinux.org/wiki/Production_LAMP_system:_Lighttpd_%2B_PHP_%2B_MySQL 

## Update The apk repository
apk update

## Lighttpd Installation
#Production env will handle only needed packages. So no doc or managers allowed: run following command

apk add lighttpd gamin

#Lighttpd pre php configuration
#
#    make the htdos public web root directories
#    change default port to production one, http is used with 80
#    use FAM style (gamin) file alteration monitor, increases performance ONLY ON 3.4 to 3.8 releases!!!
#    use linux event handler, increases performance due Alpine are linux only
#    added the service to the default runlevel, not to boot, because networking needs to be active first
#    started the web server service
#    Enable the mod_status at the config files
#    change path in the config file, we are using security by obfuscation
#    restart the service to see changes at the browser

mkdir -p /var/www/localhost/htdocs/stats /var/log/lighttpd /var/lib/lighttpd

sed -i -r 's#\#.*server.port.*=.*#server.port          = 80#g' /etc/lighttpd/lighttpd.conf

sed -i -r 's#\#.*server.event-handler = "linux-sysepoll".*#server.event-handler = "linux-sysepoll"#g' /etc/lighttpd/lighttpd.conf

chown -R lighttpd:lighttpd /var/www/localhost/

chown -R lighttpd:lighttpd /var/lib/lighttpd

chown -R lighttpd:lighttpd /var/log/lighttpd

rc-update add lighttpd default

rc-service lighttpd restart

echo "it works" > /var/www/localhost/htdocs/index.html

sed -i -r 's#\#.*mod_status.*,.*#    "mod_status",#g' /etc/lighttpd/lighttpd.conf

sed -i -r 's#.*status.status-url.*=.*#status.status-url  = "/stats/server-status"#g' /etc/lighttpd/lighttpd.conf

sed -i -r 's#.*status.config-url.*=.*#status.config-url  = "/stats/server-config"#g' /etc/lighttpd/lighttpd.conf

rc-service lighttpd restart

#For testing, open a browser and go to http://<webserveripaddres>. You will see "it works". The "webserveripaddres" is the ip address of your setup/server machine.
#There's a problem in Alpine linux, FAM (gamin)# is activated as a lighttpd only service, that makes sense in docker, but on a server, it could be a problem if FAM (gamin) is also needed for other services at the same time. # OPTIONAL: alpine packagers are a mess, removed FAM on recent, so older releases of alpine can use compiled FAM packages with sed -i -r 's#.*server.stat-cache-engine.*=.*# server.stat-cache-engine = "fam"#g' /etc/lighttpd/lighttpd.conf
#
#2. php scripting: PHP fpm

#In Alpine there are two main languages for programming dynamic web pages: PHP and LUA. Alpine is minimalist so not all PHP packages are need in most cases. Both repositories must be enabled (main and community). Here we explain the most common use in production. For PHP development, see the Alpine_newbie_developer wiki page.
#PHP Installation

#Since version v3.5, PHP 7 is available along with PHP 5.6 coexisting, until version v3.9 where the latter was removed. For Alpine 3.5+m we will assume PHP7, if you need PHP 5.6, you can still use it. That wil be covered in the special Production LAMP system: Lighttpd + PHP5 + MySQL wiki page for older Alpine systems and some specific php software.
#

apk add php7 php7-bcmath php7-bz2 php7-ctype php7-curl php7-dom php7-enchant php7-exif php7-fpm php7-gd php7-gettext php7-gmp php7-iconv php7-imap php7-intl php7-json php7-mbstring php7-opcache php7-openssl php7-phar php7-posix php7-pspell php7-recode php7-session php7-simplexml php7-sockets php7-sysvmsg php7-sysvsem php7-sysvshm php7-tidy php7-xml php7-xmlreader php7-xmlrpc php7-xmlwriter php7-xsl php7-zip php7-sqlite3

apk add php7-pgsql php7-mysqli php7-mysqlnd php7-snmp php7-soap php7-ldap php7-pcntl php7-pear php7-shmop php7-wddx php7-cgi php7-pdo php7-snmp php7-tokenizer

#Note: The packages below are only for database access using php in specific ways. Install them only if you need them (specially php--pdo ones)#.# For example, cacti and cacti-php7 depend on php7-mysqli, but you must install only the cacti package, all the dependencies like php7 and php7-mysqli must be previously installed from stable.
#

apk add php7-dba php7-sqlite3 php7-mysqli php7-mysqlnd php7-pgsql php7-pdo_dblib php7-pdo_odbc php7-pdo_pgsql php7-pdo_sqlite

#PHP Global Configuration
#
#    Use fix.pathinfo
#    Set safe mode off
#    Dont expose php code if something fails
#    Set amount of memory limit for execution to 536Mb (most servers are minimum of 1 GB of RAM)
#    Set upload size to 128Mb as maximun.
#    Set POST max size to 256Mb based on the upload max size limit.
#    Turn on the URL open method
#    Set default charset to UTF-8 for increased compatibility
#    Increase the execution time and the input time for.
#

sed -i -r 's|.*cgi.fix_pathinfo=.*|cgi.fix_pathinfo=1|g' /etc/php*/php.ini
sed -i -r 's#.*safe_mode =.*#safe_mode = Off#g' /etc/php*/php.ini
sed -i -r 's#.*expose_php =.*#expose_php = Off#g' /etc/php*/php.ini
sed -i -r 's#memory_limit =.*#memory_limit = 536M#g' /etc/php*/php.ini
sed -i -r 's#upload_max_filesize =.*#upload_max_filesize = 128M#g' /etc/php*/php.ini
sed -i -r 's#post_max_size =.*#post_max_size = 256M#g' /etc/php*/php.ini
sed -i -r 's#^file_uploads =.*#file_uploads = On#g' /etc/php*/php.ini
sed -i -r 's#^max_file_uploads =.*#max_file_uploads = 12#g' /etc/php*/php.ini
sed -i -r 's#^allow_url_fopen = .*#allow_url_fopen = On#g' /etc/php*/php.ini
sed -i -r 's#^.default_charset =.*#default_charset = "UTF-8"#g' /etc/php*/php.ini
sed -i -r 's#^.max_execution_time =.*#max_execution_time = 150#g' /etc/php*/php.ini
sed -i -r 's#^max_input_time =.*#max_input_time = 90#g' /etc/php*/php.ini

#PHP-FPM Configuration
#
#    Create directory for php socket and pid files, MUST BE EQUAL to openrc defined!
#    Set into configuration file the socket path, MUST BE EQUAL to openrc defined!
#    Set into configuration file the pid file path, MUST BE EQUAL to openrc defined!

mkdir -p /var/run/php-fpm7/

chown lighttpd:root /var/run/php-fpm7

sed -i -r 's|^.*listen =.*|listen = /run/php-fpm7/php7-fpm.sock|g' /etc/php*/php-fpm.d/www.conf

sed -i -r 's|^pid =.*|pid = /run/php-fpm7/php7-fpm.pid|g' /etc/php*/php-fpm.conf

sed -i -r 's|^.*listen.mode =.*|listen.mode = 0640|g' /etc/php*/php-fpm.d/www.conf

rc-update add php-fpm7 default

service php-fpm7 restart

#The PHP-FPM defines a master process with a process pool for each service request. By default, there's only one process pool, www.

#Default values are good for starting, but will need tuning later. The best is a static one, but testing is needed to get the right configuration. 

#Lighttpd + PHP-FPM

#The web server comes with a minimal config file, so we must handle all the required settings:
#
#   1 enable the mod_alias at the config file, a specific path is needed for cgi file security
#   2 be sure and disable the fastcgi-php module by cgi only
#   3 and then enable the fastcgi-php-fpm specific module then
#   4 write a much much better approach of the php handler in the local server using the socket
#   5 configure the php to use also the socket for direct connection locally
#   6 restart the service to see changes at the browser

mkdir -p /var/www/localhost/cgi-bin

sed -i -r 's#\#.*mod_alias.*,.*#    "mod_alias",#g' /etc/lighttpd/lighttpd.conf

sed -i -r 's#.*include "mod_cgi.conf".*#   include "mod_cgi.conf"#g' /etc/lighttpd/lighttpd.conf

sed -i -r 's#.*include "mod_fastcgi.conf".*#\#   include "mod_fastcgi.conf"#g' /etc/lighttpd/lighttpd.conf

sed -i -r 's#.*include "mod_fastcgi_fpm.conf".*#   include "mod_fastcgi_fpm.conf"#g' /etc/lighttpd/lighttpd.conf

cat > /etc/lighttpd/mod_fastcgi_fpm.conf << EOF
server.modules += ( "mod_fastcgi" )
index-file.names += ( "index.php" )
fastcgi.server = (
    ".php" => (
      "localhost" => (
        "socket"                => "/var/run/php-fpm7/php7-fpm.sock",
        "broken-scriptfilename" => "enable"
      ))
)
EOF

sed -i -r 's|^.*listen =.*|listen = /var/run/php-fpm7/php7-fpm.sock|g' /etc/php*/php-fpm.d/www.conf

sed -i -r 's|^.*listen.owner = .*|listen.owner = lighttpd|g' /etc/php*/php-fpm.d/www.conf

sed -i -r 's|^.*listen.group = .*|listen.group = lighttpd|g' /etc/php*/php-fpm.d/www.conf

sed -i -r 's|^.*listen.mode = .*|listen.mode = 0660|g' /etc/php*/php-fpm.d/www.conf

rc-service php-fpm7 restart

rc-service lighttpd restart

echo "<?php echo phpinfo(); ?>" > /var/www/localhost/htdocs/info.php

#For testing, open a browser and go to http://<webserveripaddres>/info.php. You will see the info as used in production. There's no sense givig too much information to crackers. The "webserveripaddres" is the ip address of your setup/server machine.

#After that, all the files with php will be procesed faster than used a host based. Under the /var/www/localhost/cgi-bin directory will be shown as http://localhost/cgi-bin/ path. 

#Multiple PHP-FPM cluster

#As we said, FPM is managed by process pools, but the connection can be over a network or over a direct n socket. The configuration for a typical server that can handle an average number requests is with socket and localhost. For high availability, a CAT6 wired network connection of 1000Mbps and php-fpm by network connection in roundrobin mode is needed.

#The PHP FPM pool will be on a specific machine and the web server(s)# will simply connect to these machines with PHP to serve the PHP pages. The result is a cluster of lighttpd web servers against other PHP-FPM process clusters. The PHP code can be the same on all web servers and can connect to a single database.

#At the Linux console the changes are, for example, two machines 10.10.1.10 and 10.10.2.10 both have php and lighttpd, so each will set up the php of the other: 

mkdir -p /var/www/localhost/cgi-bin

sed -i -r 's#\#.*mod_alias.*,.*#    "mod_alias",#g' /etc/lighttpd/lighttpd.conf

sed -i -r 's#.*include "mod_cgi.conf".*#   include "mod_cgi.conf"#g' /etc/lighttpd/lighttpd.conf

sed -i -r 's#.*include "mod_fastcgi.conf".*#\#   include "mod_fastcgi.conf"#g' /etc/lighttpd/lighttpd.conf

sed -i -r 's#.*include "mod_fastcgi_fpm.conf".*#   include "mod_fastcgi_fpm.conf"#g' /etc/lighttpd/lighttpd.conf

cat > /etc/lighttpd/mod_fastcgi_fpm.conf << EOF
server.modules += ( "mod_fastcgi" )
index-file.names += ( "index.php" )
fastcgi.server = ( ".php" => 
  (
    ( "host" => "10.10.1.10",
      "port" => 9000
    ),
    ( "host" => "10.10.2.10",
      "port" => 9000 )
    )
  )
EOF

sed -i -r 's|^.*listen =.*|listen = 9000|g' /etc/php*/php-fpm.d/www.conf

sed -i -r 's|^.*listen.owner = .*|listen.owner = lighttpd|g' /etc/php*/php-fpm.d/www.conf

sed -i -r 's|^.*listen.group = .*|listen.group = lighttpd|g' /etc/php*/php-fpm.d/www.conf

sed -i -r 's|^.*listen.mode = .*|listen.mode = 0660|g' /etc/php*/php-fpm.d/www.conf

rc-service php-fpm7 restart

rc-service lighttpd restart

echo "<?php echo phpinfo(); ?>" > /var/www/localhost/htdocs/info.php

#3. The DBMS part: mysql/mariadb

#Alpine Linux has dummy counterpart packages for those not changed from mysql to mariadb.Installation

#Take into consideration the user mysql was created during package instalation. In the initialization section two users will be created in database init: root and mysql, and at that point only if they are in their respective system accounts, will they be able to connect to the database service.

apk add mysql mysql-client

#Initialization

#The datadir located at /var/lib/mysql must be owned by the mysql user and group. You can modify this behavior but you must edit the service file at /etc/init.d directory. Also, you need to set datadir=<YOUR_DATADIR> under section [mysqld] at the config file.

#    Initialize the main mysql database, and the data dir as standardized to /var/lib/mysql by the rc script
#    Then initialize the service, root account and socket connection are enabled without password at this point
#    Set up the root account by asigning a proper password. This is pure paranoia. the next step does just that!
#    Set up and init the installation by running the mysql_secure_installation
#    Set up permissions for managing other users and databases
#    Run the mysql_secure_installation script and answer the questions (see section below)

mysql_install_db --user=mysql --datadir=/var/lib/mysql

rc-service mariadb start

mysqladmin -u root password toor

mysql_secure_installation

#   1.Enter current password for root (enter for none): must be provided because we set it previously. Correct response is OK, successfully used password, moving on...
    2.Switch to unix_socket authentication [Y/n] this must be disabled, so answer NO, and response will be ... skipping.
    3.Change the root password? [Y/n] Just press "n" only if you provided a good password, otherwise change it!
    4.Remove anonymous users? [Y/n] In any case, production system must remove it, so answer Y and proper respond mus be ... Success!.
    5.Disallow root login remotely? [Y/n] For sure answer Y and proper respond mus be ... Success!.
    6.Remove test database and access to it? [Y/n] Should be removed, so answer Y and proper respond mus be ... Success!.
    7.Reload privilege tables now? [Y/n] Aanswer Y and proper respond mus be ... Success!.

#After reponse all the questions.. restart the service with
rc-service mariadb restart

#Configuration

#Newer Alpine system packages can set in independent files. In any case, those commands always work and where not applicable, they'll ignore the output. For more info about that, see the MariaDB Configuration files section of the MariaDB wiki page.
#
#    On older Alpine system you must set config files for MAX ALLOWED PACKETS to minimun proper amount:
#    Only allow local connections in cases where there's only one server or no expected connections from others:
#    Set default charset to UTF8MB4
#    Add the start service process, but domn't set it as a boot process because networking needs to already be running.
#    Restart the service to apply changes.

sed -i "s|.*max_allowed_packet\s*=.*|max_allowed_packet = 100M|g" /etc/mysql/my.cnf
sed -i "s|.*max_allowed_packet\s*=.*|max_allowed_packet = 100M|g" /etc/my.cnf.d/mariadb-server.cnf

sed -i "s|.*bind-address\s*=.*|bind-address=127.0.0.1|g" /etc/mysql/my.cnf
sed -i "s|.*bind-address\s*=.*|bind-address=127.0.0.1|g" /etc/my.cnf.d/mariadb-server.cnf

cat > /etc/my.cnf.d/mariadb-server-default-charset.cnf << EOF
[client]
default-character-set = utf8mb4

[mysqld]
collation_server = utf8mb4_unicode_ci
character_set_server = utf8mb4

[mysql]
default-character-set = utf8mb4
EOF

rc-service mariadb restart

rc-update add mariadb default

#Upgrading: If you are unable to run any mysql commands after an upgrade, it's because MySQL cannot start. Try to run MySQL in safe mode with the mysqld_safe --datadir=/var/lib/mysql/ command, then run the mysql_upgrade -u root -p script. For more information see the MariaDB upgrading section of the MariaDB wiki page.
#
#adminer: Web Frontend administration

#Adminer is a simple standalone tool, tons of times faster than PhpMysqladmin that is great but has too many security issues and lots of complex settings.We need a single, simpler solution.One that's easy to manage and upgrade.

#Take into consideration this needs as a prerequisite, the previous sections of the web server, php scripting and mysql/mariadb engine configured and running:

mkdir -p /var/www/webapps/adminer

wget https://github.com/vrana/adminer/releases/download/v4.7.6/adminer-4.7.6.php -O /var/www/webapps/adminer/adminer-4.7.6.php

ln -s adminer-4.7.6.php /var/www/webapps/adminer/index.php

cat > /etc/lighttpd/mod_adminer.conf << EOF
# NOTE: this requires mod_alias
alias.url += (
     "/adminer/"	    =>	    "/var/www/webapps/adminer/"
)
$HTTP["url"] =~ "^/adminer/" {
    # disable directory listings
    dir-listing.activate = "disable"
}
EOF

sed -i -r 's#\#.*mod_alias.*,.*#    "mod_alias",#g' /etc/lighttpd/lighttpd.conf

sed -i -r 's#.*include "mod_cgi.conf".*#   include "mod_cgi.conf"#g' /etc/lighttpd/lighttpd.conf

checkssl="";checkssl=$(grep 'include "mod_adminer.conf' /etc/lighttpd/lighttpd.conf);[[ "$checkssl" != "" ]] && echo listo || sed -i -r 's#.*include "mod_cgi.conf".*#include "mod_cgi.conf"\ninclude "mod_adminer.conf"#g' /etc/lighttpd/lighttpd.conf

rc-service lighttpd restart

#The administrator must use the exact URL http://<ipaddress>/adminer/index.php There are two reasons: there's no directory listing and there's no direct PHP index reference on the web server, all because of paranoid settings. 







































