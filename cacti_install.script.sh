#!/bin/sh
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
BUILD_DIR=`pwd`
MAIN_PATH="/var/www/html/cacti"
MYSQL_PATH="/usr/bin/mysql"
mysqlrootpwd="abcABC123$$$"

# install "lamp-server"
sudo apt-get install lamp-server^ -y

apt-get update
apt-get install php-xml php-simplexml php-mbstring php-ldap php-gmp php-gd php-snmp rrdtool freetype* -y

# sudo cat /etc/timezone
# Etc/UTC
echo 'date.timezone = "Etc/UTC"' >> /etc/php/7.2/apache2/php.ini

cd /tmp
# for latest git
git clone https://github.com/Cacti/cacti.git
# for latest "release"
# wget https://www.cacti.net/downloads/cacti-1.2.0.tar.gz
# mkdir cacti && tar xvzf cacti-1.2.0.tar.gz -C cacti --strip-components 1
rm /var/www/html/cacti -rf
mv ./cacti /var/www/html/
cp /var/www/html/cacti/cacti.sql /var/www/html/cacti/cacti.sql.bak
cp /var/www/html/cacti/include/config.php /var/www/html/cacti/include/config.php.bak
cp /var/www/html/cacti/include/global.php /var/www/html/cacti/include/global.php.bak

useradd cacti
echo "cacti:cacti" | chpasswd

sudo groupadd cacti
usermod -a -G cacti cacti

/usr/bin/mysql -u root -pabcABC123$$$ mysql < /usr/share/mysql/mysql_test_data_timezone.sql

/usr/bin/mysql -u root -pabcABC123$$$ -e "drop database cacti;"
/usr/bin/mysql -u root -pabcABC123$$$ -e "create database cacti;"

/usr/bin/mysql -u root -pabcABC123$$$ -e "GRANT SELECT ON mysql. time_zone_name TO 'cacti'@'localhost' IDENTIFIED BY 'cacti';"

/usr/bin/mysql -u root -pabcABC123$$$ -e "grant all on cacti.* to root@localhost;"
/usr/bin/mysql -u root -pabcABC123$$$ -e "grant all on cacti.* to root@127.0.0.1;"
/usr/bin/mysql -u root -pabcABC123$$$ -e "grant all on cacti.* to cacti@localhost identified by 'cacti';"
/usr/bin/mysql -u root -pabcABC123$$$ -e "grant all on cacti.* to cacti@127.0.0.1 identified by 'cacti';"
/usr/bin/mysql -u root -pabcABC123$$$ -e "flush privileges;"

/usr/bin/mysql -u root -pabcABC123$$$ cacti < /var/www/html/cacti/cacti.sql

# php /var/www/html/cacti/cli/repair_database.php --force

#blank os config file from github
cp /var/www/html/cacti/include/config.php.dist /var/www/html/cacti/include/config.php

# /var/www/html/cacti/include/config.php
sed -i -e 's@^$database_type.*@$database_type = "mysql";@g' /var/www/html/cacti/include/config.php
sed -i -e 's@^$database_default.*@$database_default = "cacti";@g' /var/www/html/cacti/include/config.php
sed -i -e 's@^$database_hostname.*@$database_hostname = "127.0.0.1";@g' /var/www/html/cacti/include/config.php
sed -i -e 's@^$database_username.*@$database_username = "cacti";@g' /var/www/html/cacti/include/config.php
sed -i -e 's@^$database_password.*@$database_password = "cacti";@g' /var/www/html/cacti/include/config.php
sed -i -e 's@^$database_port.*@$database_port = "3306";@g' /var/www/html/cacti/include/config.php
sed -i -e 's@^$database_ssl.*@$database_ssl = "false";@g' /var/www/html/cacti/include/config.php
sed -i -e 's@^//$url_path@$url_path@g' /var/www/html/cacti/include/config.php

# /var/www/html/cacti/include/global.php
sed -i -e 's@^$database_type.*@$database_type = "mysql";@g' /var/www/html/cacti/include/global.php
sed -i -e 's@^$database_default.*@$database_default = "cacti";@g' /var/www/html/cacti/include/global.php
sed -i -e 's@^$database_hostname.*@$database_hostname = "127.0.0.1";@g' /var/www/html/cacti/include/global.php
sed -i -e 's@^$database_username.*@$database_username = "cacti";@g' /var/www/html/cacti/include/global.php
sed -i -e 's@^$database_password.*@$database_password = "cacti";@g' /var/www/html/cacti/include/global.php
sed -i -e 's@^$database_port.*@$database_port = "3306";@g' /var/www/html/cacti/include/global.php
sed -i -e 's@^$database_ssl.*@$database_ssl = "false";@g' /var/www/html/cacti/include/global.php
sed -i -e 's@^//$url_path@$url_path@g' /var/www/html/cacti/include/global.php

# rra/ log/
chown -R cacti:cacti /var/www/html/cacti/
# chown -R cacti /var/www/html/cacti/rra/
# chown -R cacti /var/www/html/cacti/log/
# chgrp -R cacti /var/www/html/cacti/

chown -R www-data.www-data /var/www/html/cacti/resource/snmp_queries/
chown -R www-data.www-data /var/www/html/cacti/resource/script_server/
chown -R www-data.www-data /var/www/html/cacti/resource/script_queries/
chown -R www-data.www-data /var/www/html/cacti/scripts/
chown -R www-data.www-data /var/www/html/cacti/cache/boost/
chown -R www-data.www-data /var/www/html/cacti/cache/mibcache/
chown -R www-data.www-data /var/www/html/cacti/cache/realtime/
chown -R www-data.www-data /var/www/html/cacti/cache/spikekill/
chmod 777 /var/www/html/cacti/log/cacti.log
chown -R www-data.www-data /var/www/html/cacti/log/

cat /var/www/html/cacti/include/config.php
cat /var/www/html/cacti/include/global.php

croncmd=" php /var/www/html/cacti/poller.php >/var/www/html/cacti/log/pooler-error.log"
cronjob="*/1 * * * * $croncmd"
( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -
