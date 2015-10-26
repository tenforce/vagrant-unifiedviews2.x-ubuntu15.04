#!/bin/bash
#########################################################################
# First install the docker service.

docker build -t="my-stardog" /vagrant/stardog-docker
cp -f /vagrant/config-files/stardog-docker.service /etc/systemd/system
chmod +x /etc/systemd/system/stardog-docker.service
# Enable the service to start at boot time
systemctl enable stardog-docker.service
systemctl start stardog-docker           # Will take a while

# Update the backend service files
service unifiedviews-backend stop
service unifiedviews-frontend stop
    
cp /vagrant/config-files/frontend-config.stardog.properties /etc/unifiedviews/frontend-config.properties
cp /vagrant/config-files/backend-config.stardog.properties /etc/unifiedviews/backend-config.properties

# Restart all necessary services
service unifiedviews-backend start
service unifiedviews-frontend start
service tomcat7 restart

echo "Update service descriptions"
