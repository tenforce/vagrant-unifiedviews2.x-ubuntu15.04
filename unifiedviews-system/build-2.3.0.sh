#!/bin/bash

# Get the latest files needed.

wget_n() {
    pushd ../downloads
    wget -N $1
    popd
}

if [ ! -d debs ]
then
 wget_n https://github.com/UnifiedViews/Core/archive/release/UV_Core_v2.3.0.zip
 wget_n https://github.com/UnifiedViews/Plugins/archive/release/UV_Plugins_v2.2.1.zip

 unzip ../downloads/UV_Core_*.zip
 unzip ../downloads/UV_Plugins*.zip

 # Build the debian packages as required (uses the docker OPENJDK7 though).
 pushd *Core*
   docker run -it --rm --name my-maven-project4 \
	-v "$PWD":/usr/src/mymaven -w /usr/src/mymaven maven:3.3-jdk-7 \
	mvn -f debian/pom.xml package | tee tmp.core
 popd

 pushd *Plugin*
   docker run -it --rm --name my-maven-project4 \
	-v "$PWD":/usr/src/mymaven -w /usr/src/mymaven maven:3.3-jdk-7 \
	mvn -DskipTests -f debian/pom.xml package | tee tmp.plugins
 popd

 # Replace the debian packages

 mkdir -p debs
 cp */*/target/*.deb debs
 cp */*/*/target/*.deb debs
else
 echo "packages should already exist in debs directory"
fi

dpkg-scanpackages debs /dev/null | gzip > debs/Packages.gz
rm /etc/apt/sources.list.d/odn.list

echo "deb file:/vagrant/unifiedviews-system debs/" > /etc/apt/sources.list.d/uv-update.list
echo "*** WARN: unhold the previous packages might be needed"
apt-get -y update
apt-get -y --force-yes install unifiedviews-mysql \
	unifiedviews-backend-shared \
	unifiedviews-backend-mysql \
	unifiedviews-backend \
	unifiedviews-webapp-shared \
	unifiedviews-webapp-mysql \
	unifiedviews-webapp \
	unifiedviews-plugins
apt-get -y --force-yes install

