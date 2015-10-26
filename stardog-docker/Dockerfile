FROM java:8
##########################################################################
#
# Variant of: https://hub.docker.com/r/bluepeppers/stardog/~/dockerfile/
# Main Differences:
# - java 8 used
# - stardog 4.0 used
#
# Note: Stardog is licensed so will need to be downloaded along with the
# license key.

ENV STARDOG_VERSION=stardog-4.0-RC1
ENV STARDOG_LICENSE=stardog-license-key.bin.gz
ENV STARDOG_HOME=/${STARDOG_VERSION}

WORKDIR /

ADD ${STARDOG_VERSION}.zip /
ADD ${STARDOG_LICENSE} /

RUN apt-get update && apt-get update -yy && \
    apt-get install -yy wget unzip && \
    unzip /${STARDOG_VERSION}.zip && \
    mv /${STARDOG_LICENSE} ${STARDOG_HOME} && \
    gzip -d ${STARDOG_HOME}/*.gz && \
    apt-get autoremove

WORKDIR ${STARDOG_HOME}

EXPOSE 5820

CMD ${STARDOG_HOME}/bin/stardog-admin server start && \
    ls  ${STARDOG_HOME} && \
    sleep 1 && \
    (tail -f ${STARDOG_HOME}/stardog.log &) && \
    while (pidof java > /dev/null); do sleep 1; done
