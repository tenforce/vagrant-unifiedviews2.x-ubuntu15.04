#!/bin/bash
#######################################################################
# Install the sesame 4.0.0 store.

# SESAME_DOWNLOAD="http://downloads.sourceforge.net/project/sesame/Sesame%204/4.0.0/openrdf-sesame-4.0.0-onejar.jar?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fsesame%2F&ts=1445437140&use_mirror=netcologne"
# mkdir -p /vagrant/downloads
# pushd /vagrant/downloads
#   wget -N SESAME_DOWNLOAD
# popd

if [ -f "/vagrant/downloads/openrdf-sesame-2.8.6-sdk.zip" ]; then
    service tomcat7 stop
    service unifiedviews-backend stop
    service unifiedviews-frontend stop
    
    mkdir -p /vagrant/database/unifiedviews
    unzip /vagrant/downloads/openrdf-sesame-2.8.6-sdk.zip
    cp /vagrant/downloads/openrdf-sesame-2.8.6/war/*.war /var/lib/tomcat7/webapps/
    cp /vagrant/config-files/tomcat7-default.sesame /etc/default/tomcat7
    
    # Now block updating of tomcat (since config files have been updated)
    apt-mark hold tomcat7
    
    # Replace the default in-memory configuration files
    cp /vagrant/config-files/frontend-config.properties /etc/unifiedviews/
    cp /vagrant/config-files/backend-config.properties /etc/unifiedviews/

    # Restart all necessary services
    service tomcat7 start
    service unifiedviews-backend start
    service unifiedviews-frontend start
else
    echo "***** SESAME openrdf-sesame-2.8.6-sdk.zip not downloaded"
fi    
