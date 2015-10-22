#!/usr/bin/env bash
#################################################################
# Install the necessary components for unifiedviews (packages used)

export PATH="/vagrant:$PATH"

#################################################################
# This is the LATEST which has been tested (not always latest).

SESAME=yes
VERSION=2.1.3
ODN_VERSION=1.1.3

#################################################################
# Standard System Updates.
apt-get install -y dkms kernel-headers kervel-devel \
	virtualbox-guest-dkms virtualbox-guest-x11
apt-get install -y apache2 libapache2-mod-auth-cas \
	debconf-utils dpkg-dev build-essential quilt gdebi 

#################################################################
# Install docker stuff
apt-get install -y apparmor lxc cgroup-lite
apt-get install -y docker.io

#################################################################
# Now start to setup for building unified views, etc.
apt-get install -y ntp                              # Time Server
apt-get install -y openjdk-7-jre openjdk-7-jdk
apt-get install -y tomcat7 git maven bash emacs nano vim
apt-get install -y firefox dos2unix
# Make sure clean
dos2unix /vagrant/config-files/*
echo "JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64" >> /etc/default/tomcat7

echo "deb http://packages.comsode.eu/debian wheezy main" > /etc/apt/sources.list.d/odn.list
wget -O - http://packages.comsode.eu/key/odn.gpg.key | apt-key add -
apt-get update -y --force-yes

###############################################################
# http://www.oracle.com/technetwork/database/features/jdbc/default-2280470.html
# should be in this directory
mvn install:install-file -Dfile=/vagrant/ojdbc7.jar -DgroupId=com.oracle \
    -DartifactId=ojdbc7 -Dversion=12.1.0.2.0 -Dpackaging=jar

###############################################################
# Set the default values for the debconf questions
#
echo "mysql-server-5.5 mysql-server/root_password_again password root" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password password root" | debconf-set-selections
echo "mysql-server-5.5 mysql-server-5.5/root_password_again password root" | debconf-set-selections
echo "mysql-server-5.5 mysql-server-5.5/root_password password root" | debconf-set-selections

echo "mysql-server-5.6 mysql-server/root_password_again password root" | debconf-set-selections
echo "mysql-server-5.6 mysql-server/root_password password root" | debconf-set-selections
echo "mysql-server-5.6 mysql-server-5.6/root_password_again password root" | debconf-set-selections
echo "mysql-server-5.6 mysql-server-5.6/root_password password root" | debconf-set-selections

echo "unifiedviews-webapp-mysql       frontend/mysql_db_password password root"| debconf-set-selections
echo "unifiedviews-webapp-shared	frontend/mysql_dba_user	string	root" | debconf-set-selections
echo "unifiedviews-webapp-shared      frontend/mysql_dba_password password root"| debconf-set-selections
echo "unifiedviews-webapp-mysql       frontend/mysql_db_user string root" | debconf-set-selections
echo "unifiedviews-webapp-mysql       frontend/mysql_db_password password root"| debconf-set-selections
echo "unifiedviews-webapp-mysql       frontend/mysql_db_user string root"| debconf-set-selections
echo "unifiedviews-backend-mysql      backend/mysql_root password root"| debconf-set-selections
echo "unifiedviews-backend-mysql      backend/mysql_db_password password root"| debconf-set-selections
echo "unifiedviews-backend-mysql      backend/mysql_db_user string root"| debconf-set-selections

#################################################################
# DB installations, etc which have customised values.
echo "**** Create Virtuoso Docker named image"
usermod -aG docker ${USER}
systemctl start docker

#################################################################
# Make sure the docker is defined as a service
echo "**** Setup virtuoso service"
cp -f /vagrant/config-files/virtuoso-docker.service /etc/systemd/system
chmod +x /etc/systemd/system/virtuoso-docker.service
# Enable the service to start at boot time
systemctl enable virtuoso-docker.service
systemctl start virtuoso-docker           # Will take a while

#################################################################
apt-get install -y mysql-server
apt-get update -y --force-yes

###############################################################
# Unified views pulling, packaging and hopefully the installation.
apt-get -y --force-yes install unifiedviews-mysql=${VERSION} \
	unifiedviews-backend-shared=${VERSION} \
	unifiedviews-backend-mysql=${VERSION} \
	unifiedviews-backend=${VERSION} \
	unifiedviews-webapp-shared=${VERSION} \
	unifiedviews-webapp-mysql=${VERSION} \
	unifiedviews-webapp=${VERSION} \
	unifiedviews-plugins=${VERSION}
   # PREVENT UPDATING (at present)
apt-mark hold unifiedviews-mysql unifiedviews-backend-shared \
	 unifiedviews-backend-mysql unifiedviews-backend \
	 unifiedviews-webapp-shared unifiedviews-webapp-mysql \
	 unifiedviews-webapp unifiedviews-plugins 

# Some additional packages for accessing CKAN
apt-get -y --force-yes install odn-uv-plugins=${ODN_VERSION}
apt-mark hold odn-uv-plugins

# Change the env (language changed to english :-))
sed -iBAC -e 's/sk/en/g' /etc/unifiedviews/*.properties
# Make sure that the DPU's are in
bash /usr/share/unifiedviews/dist/plugins/deploy-dpus.sh

# Make sure nothing missing ...
apt-get -f -y install 

#################################################################
# Enable CORS on the virtuoso endpoint(requires running docker)
#
# Note: Building/starting up the virtuoso docker image can take a
# while, hence the wait here for it to go into a running state.
#
echo "***** Update CORS and setup YASGUI"
until [ "`/usr/bin/docker inspect -f {{.State.Running}} my-virtuoso`" == "true" ]; do
    echo -n "***** waiting for my-virtuoso to start - sleep 10"
    sleep 10;
done
sleep 1m;
# my-virtuoso should have been started now, so enable CORS
docker exec -i my-virtuoso isql-v -U dba -P root < /vagrant/config-files/CORS.sql
# YASGUI required CORS to be enables.
bootstrap-yasgui.sh

###############################################################
if [ "${SESAME}" = "yes" ]; then
    bootstrap-sesame.sh
fi

###############################################################
# Setup other services
# update-rc.d unifiedviews-backend defaults
# Allows login without password
echo "vagrant ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vagrant

###############################################################
# Change the default homepage-
echo "***** Setup homepage for browser"
echo "user_pref(\"browser.startup.homepage\", \"file:///vagrant/homepage.html\");" >> /etc/firefox/pref/syspref.js
echo "user_pref(\"browser.startup.homepage\", \"file:///vagrant/homepage.html\");" >> /etc/firefox/syspref.js

if [ ! -d "/vagrant/Plugin-DevEnv" ]; then
    ( cd /vagrant ; git clone https://github.com/UnifiedViews/Plugin-DevEnv.git )
    ( cd /vagrant/Plugin-DevEnv ; mvn install )
    ( cd /vagrant ; git clone https://github.com/tenforce/unifiedviews-dpus.git )
fi

###############################################################
# Cleanup as required.
apt-get autoclean

###############################################################
# Switch off the automatic updates message
echo "APT::Periodic::Update-Package-Lists \"0\";" > /etc/apt/apt.conf.d/10periodic
echo "****** done with bootstrap"
###############################################################
