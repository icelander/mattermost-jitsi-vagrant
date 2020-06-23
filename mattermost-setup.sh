#!/bin/bash

printf '=%.0s' {1..80}
echo 
echo 'PROVISIONING WITH THESE ARGUMENTS:'
echo $@
printf '=%.0s' {1..80}

if [ "$1" != "" ]; then
    mattermost_version="$1"
else
	echo "Mattermost version is required"
    exit 1
fi


if [ "$2" != "" ]; then
    mysql_root_password="$2"
else
	echo "MYSQL root password is required"
    exit 1
fi

if [ "$3" != "" ]; then
    mattermost_password="$3"
else
	echo "Mattermost MySQL password is required"
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "mysql-server mysql-server/root_password password $mysql_root_password" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $mysql_root_password" | debconf-set-selections

echo "Installing MySQL and jq"
apt-get install -y -q mysql-server jq

sed -i 's/bind-address/# bind-address/' /etc/mysql/mysql.conf.d/mysqld.cnf
service mysql restart

echo "Setting up database"
cat /vagrant/db_setup.sql | sed "s/MATTERMOST_PASSWORD/$mattermost_password/g" > ./db_setup.sql
mysql -uroot -p$mysql_root_password < ./db_setup.sql


rm -rf /opt/mattermost

if [[ $mattermost_version == "4"* ]]; then
	echo "@@@ Version 4 or lower, using platform binary"
	mattermost_binary="platform"
else
	mattermost_binary="mattermost"
fi

echo /vagrant/mattermost_archives/mattermost-$mattermost_version-linux-amd64.tar.gz

if [[ ! -f /vagrant/mattermost_archives/mattermost-$mattermost_version-linux-amd64.tar.gz ]]; then
	echo "Downloading Mattermost"
	wget -q -P /vagrant/mattermost_archives/ https://releases.mattermost.com/$mattermost_version/mattermost-$mattermost_version-linux-amd64.tar.gz
fi

if [[ ! -f /vagrant/mattermost_archives/mattermost-$mattermost_version-linux-amd64.tar.gz  ]]; then
	echo "Couldn't find the Mattermost archive"
	exit 1
fi

cp /vagrant/mattermost_archives/mattermost-$mattermost_version-linux-amd64.tar.gz ./

tar -xzf mattermost*.gz

rm mattermost*.gz
mv mattermost /opt

mkdir /opt/mattermost/data
mv /opt/mattermost/config/config.json /opt/mattermost/config/config.orig.json
jq -s '.[0] * .[1]' /opt/mattermost/config/config.orig.json /vagrant/config.json > /opt/mattermost/config/config.json

cp /vagrant/e20license.txt /opt/mattermost/config/license.txt

mkdir /opt/mattermost/plugins
mkdir /opt/mattermost/client/plugins

useradd --system --user-group mattermost

cat /vagrant/mattermost.service | sed "s#/opt/mattermost/bin/mattermost#/opt/mattermost/bin/$mattermost_binary#g" > ./mattermost.service
mv ./mattermost.service /lib/systemd/system/mattermost.service
systemctl daemon-reload

cd /opt/mattermost
bin/$mattermost_binary version

# Install Jitsi Plugin
wget https://github.com/mattermost/mattermost-plugin-jitsi/releases/download/v1.3.0/jitsi-1.3.0.tar.gz
bin/$mattermost_binary plugin add jitsi-1.3.0.tar.gz
bin/$mattermost_binary plugin enable jitsi

bin/$mattermost_binary user create --email admin@example.com --username admin --password admin --system_admin
bin/$mattermost_binary user create --email user@example.com --username user --password password
bin/$mattermost_binary team create --name a-team --display_name "A Team" --email admin@example.com
bin/$mattermost_binary team add a-team admin@example.com
bin/$mattermost_binary team add a-team user@example.com
# bin/$mattermost_binary sampledata --seed 10 --teams 4 --users 30

chown -R mattermost:mattermost /opt/mattermost
chmod -R g+w /opt/mattermost

service mysql start
service mattermost start

# IP_ADDR=`/sbin/ifconfig eth0 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}'`

printf '=%.0s' {1..80}
echo 
echo '                     VAGRANT UP!'
echo "GO TO http://127.0.0.1:8065 and log in with \`admin\`"
echo
printf '=%.0s' {1..80}
