#!/bin/bash
#################################################################
# Install the necessary components for unifiedviews (packages used)

export PATH="/vagrant:$PATH"

#################################################################
# This is the LATEST which has been tested (not always latest).

REMOTE_RDFSTORE=sesame

VERSION=2.3.0~
ODN_VERSION=1.1.3

#################################################################
# Us to test if a package is installed or not.

package_exists () {
    return dpkg -l $1 &> /dev/null
}

#################################################################
# Standard System Updates.
apt-get -y update
apt-get install -y dkms virtualbox-guest-dkms linux-generic
apt-get install -y apache2 libapache2-mod-auth-cas \
	debconf-utils dpkg-dev build-essential quilt gdebi 

#################################################################
# Install docker stuff
apt-get install -y apparmor lxc cgroup-lite
apt-get install -y docker.io

# Add user to doker grup.
usermod -aG docker ${USER}
systemctl start docker

#################################################################
# Now start to setup for building unified views, etc.
apt-get install -y ntp                              # Time Server
apt-get install -y openjdk-7-jre openjdk-7-jdk
apt-get install -y tomcat7 git maven bash emacs nano vim dos2unix
# Make sure clean
dos2unix /vagrant/config-files/*
# echo "JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64" >> /etc/default/tomcat7

#################################################################
# Setup the repositories
#

if [ -d "/vagrant/unifiedvuews-system/Packages" ]
then
    echo "deb file://vagrant/unifiedviews-system debs/" > /etc/apt/sources.list.d/local.list
fi

if [ "${VERSION}" = "2.1.0" ]
then
    echo "deb http://packages.comsode.eu/debian wheezy main" > /etc/apt/sources.list.d/odn.list
    wget -O - http://packages.comsode.eu/key/odn.gpg.key | apt-key add -
elif [ "${VERSION}" = "2.3.0~" ]
then
    echo "deb http://packages.unifiedviews.eu/debian wheezy main" > /etc/apt/sources.list.d/unifiedviews.list
    wget -O - http://packages.unifiedviews.eu/key/unifiedviews.gpg.key | apt-key add -
else
    echo "not handled version - ${VERSION}"
    exit -1;
fi    
apt-get update -y --force-yes

###############################################################
# Install desktop (with firefox)
apt-get -y install ubuntu-gnome-desktop firefox
service gdm restart
dpkg-reconfigure gdm

###############################################################
# http://www.oracle.com/technetwork/database/features/jdbc/default-2280470.html
# should be in this directory
#
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

PLUGINS=unifiedviews-plugins
apt-get -y --force-yes install unifiedviews-mysql=${VERSION} \
	unifiedviews-backend-shared=${VERSION} \
	unifiedviews-backend-mysql=${VERSION} \
	unifiedviews-backend=${VERSION} \
	unifiedviews-webapp-shared=${VERSION} \
	unifiedviews-webapp-mysql=${VERSION} \
	unifiedviews-webapp=${VERSION} ${PLUGINS}

# PREVENT UPDATING (at present)
apt-mark hold unifiedviews-mysql unifiedviews-backend-shared \
	 unifiedviews-backend-mysql unifiedviews-backend \
	 unifiedviews-webapp-shared unifiedviews-webapp-mysql \
	 unifiedviews-webapp ${PLUGINS}

# Some additional packages for accessing CKAN

if [ "${VERSION}" = "2.1.0" ]
then
    apt-get -y --force-yes install odn-uv-plugins=${ODN_VERSION}
    apt-get -y --force-yes install unifiedviews-qa-plugins=2.2.0
    apt-mark hold odn-uv-plugins
fi

# Change the env (language changed to english :-))
sed -iBAC -e 's/sk/en/g' /etc/unifiedviews/*.properties
# Make sure that the DPU's are in
bash /usr/share/unifiedviews/dist/plugins/deploy-dpus.sh

# Make sure nothing missing ...
apt-get -f -y install

#################################################################
# Check that unifiedviews installed correctly.
# if ! package_exists ${PLUGINS} ; then
#    echo "package installation failed for "  ${PLUGINS} "!!"
#    exit -1;
# fi

#################################################################
# Enable CORS on the virtuoso endpoint(requires running docker)
#
# Note: Building/starting up the virtuoso docker image can take a
# "while", hence the wait here for it to go into a running state.

echo "***** Update CORS and setup YASGUI"
until [ "`/usr/bin/docker inspect -f {{.State.Running}} my-virtuoso`" == "true" ]; do
    echo -n "***** waiting for my-virtuoso to start - sleep 10"
    sleep 20;
done
sleep 1m;
# my-virtuoso should have been started now, so enable CORS

docker exec -i my-virtuoso isql-v -U dba -P root < /vagrant/config-files/CORS.sql
# YASGUI required CORS to be enables.
bootstrap-yasgui.sh

###############################################################
case ${REMOTE_RDFSTORE} in
      sesame) bootstrap-sesame.sh ;;
     stardog) bootstrap-stardog.sh ;;
           *) echo "**** default localRDF will be used"
esac

###############################################################
if ! hash logrotate 2>/dev/null; then
    apt-get install -y logrotate
fi
echo "INFO: setup Logrotate - not yet"

###############################################################
# Allows login without password
echo "vagrant ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vagrant

###############################################################
# Change the default homepage-
echo "***** Setup homepage for browser"
echo "user_pref(\"browser.startup.homepage\", \"file:///vagrant/homepage.html\");" >> /etc/firefox/pref/syspref.js
echo "user_pref(\"browser.startup.homepage\", \"file:///vagrant/homepage.html\");" >> /etc/firefox/syspref.js

###############################################################
# Install the plugin environment.
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
