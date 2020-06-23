# -*- mode: ruby -*-
# vi: set ft=ruby :

MATTERMOST_VERSION = "5.24.0"

ROOT_PW = 'mysql_root_password'
MMST_PW = 'really_secure_password'

Vagrant.configure("2") do |config|
  config.vm.box = 'bento/ubuntu-20.04'

  config.vm.define "mmst-jitsi" do |box|
    box.vm.provider "virtualbox" do |v|
      v.memory = 2048
      v.cpus = 4
    end

    box.vm.hostname = "jitsi.example.com"

    box.vm.network "forwarded_port", guest: 8443, host: 8443
    box.vm.network "forwarded_port", guest: 8000, host: 8000
    # box.vm.network "forwarded_port", guest: 80, host: 80
    box.vm.network "forwarded_port", guest: 8065, host: 8065
    box.vm.network "forwarded_port", guest: 3306, host: 13306

    box.vm.provision :docker

    config.vm.provision :docker_compose
    
    box.vm.provision :shell do |s|
      s.path = 'jitsi-setup.sh'
    end

    # box.vm.provision :shell do |s|
    #   s.path = 'nginx-setup.sh'
    # end

    box.vm.provision :shell do |s|
      s.path = 'mattermost-setup.sh'
      s.args = [MATTERMOST_VERSION,
                ROOT_PW, 
                MMST_PW]
    end
  end
end