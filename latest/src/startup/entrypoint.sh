#!/bin/bash
export USER=headless

/dockerstartup/vnc_startup.sh &

/opt/squish.run unattended=1 ide=0 targetdir=${HOME}/squish licensekey=$LICENSEKEY

cp ${HOME}/squish/etc/paths.ini ${HOME}/squish/etc/paths.ini-backup
cp /dockerstartup/paths.ini ${HOME}/squish/etc/

mkdir -p ${HOME}/.squish/ver1/
cp ${SERVER_INI} ${HOME}/.squish/ver1/

/home/headless/squish/bin/squishserver &

~/squish/bin/squishrunner --testsuite ${CLIENT_REPO}/test/gui/ ${SQUISH_PARAMETERS} --exitCodeOnFail 1
