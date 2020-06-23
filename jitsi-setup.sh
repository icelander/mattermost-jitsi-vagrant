#!/bin/bash

echo "Updating and Upgrading"
apt-get update
apt-get upgrade -y

git clone https://github.com/jitsi/docker-jitsi-meet
cd docker-jitsi-meet
cp /vagrant/docker.env ./.env

mkdir -p /opt/jitsi-meet-cfg/{web/letsencrypt,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}

docker-compose up -d