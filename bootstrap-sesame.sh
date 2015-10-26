#!/bin/bash
#########################################################################
# Install the sesame store (2.8.1 at present - see unifiedviews installation)

SESAME_VERSION=2.8.1

if [ -f "/vagrant/downloads/openrdf-sesame-${SESAME_VERSION}-sdk.zip" ]; then
    pushd /vagrant/downloads
     service tomcat7 stop
     service unifiedviews-backend stop
     service unifiedviews-frontend stop
    
     mkdir -p /vagrant/sesame-databases
     unzip /vagrant/downloads/openrdf-sesame-${SESAME_VERSION}-sdk.zip
     cp /vagrant/downloads/openrdf-sesame-${SESAME_VERSION}/war/*.war /var/lib/tomcat7/webapps/
     cp /vagrant/config-files/tomcat7-default.sesame /etc/default/tomcat7
     cp /vagrant/config-files/proxy.properties.default /vagrant/sesame-databases/openrdf-sesame/conf

     # Now block updating of tomcat (since config files have been updated)
     apt-mark hold tomcat7
    
     # Replace the default in-memory configuration files
     cp /vagrant/config-files/frontend-config.properties /etc/unifiedviews/
     cp /vagrant/config-files/backend-config.properties /etc/unifiedviews/

     # Restart all necessary services
     service tomcat7 start
     service unifiedviews-backend start
     service unifiedviews-frontend start

     # Create the repository (requires tomcat7 to be running)
     pushd ../sesame-databases
      sleep 10;
      /vagrant/downloads/openrdf-sesame-${SESAME_VERSION}/bin/console.sh -s "http://localhost:8080/openrdf-sesame" <<EOF
create memory
unifiedviews
UnifiedViews Repository



exit
EOF
      echo "***** SESAME should be okay"
     popd
    popd
else
    echo "***** SESAME openrdf-sesame-${SESAME_VERSION}-sdk.zip not downloaded"
fi    
