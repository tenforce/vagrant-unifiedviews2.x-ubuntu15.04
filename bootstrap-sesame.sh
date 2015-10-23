#!/bin/bash
#######################################################################
# Install the sesame 4.0.0 store.

if [ -f "/vagrant/downloads/openrdf-sesame-2.8.6-sdk.zip" ]; then
    pushd /vagrant/downloads
     service tomcat7 stop
     service unifiedviews-backend stop
     service unifiedviews-frontend stop
    
     mkdir -p /vagrant/sesame-databases
     unzip /vagrant/downloads/openrdf-sesame-2.8.6-sdk.zip
     cp /vagrant/downloads/openrdf-sesame-2.8.6/war/*.war /var/lib/tomcat7/webapps/
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
      /vagrant/downloads/openrdf-sesame-2.8.6/bin/console.sh <<EOF
create remote

unifiedviews
unifiedviews
UnifiedViews Repository    
exit
EOF
      echo "***** SESAME should be okay"
     popd
    popd
else
    echo "***** SESAME openrdf-sesame-2.8.6-sdk.zip not downloaded"
fi    
