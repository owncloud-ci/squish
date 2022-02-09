#!/bin/bash
export USER=headless

/dockerstartup/vnc_startup.sh &

#maximum time to wait for licenses (before installation of squish + before running tests)
runtime="30 minute"
endtime=$(date -ud "$runtime" +%s)

result=1
echo "installing squish"

# retry installing squish if there is an issue to connect the license server
while [[ $result -ne 0 ]]
do
  if [[ $(date -u +%s) -gt $endtime ]]
  then
    echo "timeout waiting for license server"
    exit 1
  fi

  /opt/squish.run unattended=1 ide=0 targetdir=/tmp/squish licensekey=$LICENSEKEY
  result=$?

  if [[ $result -ne 0 ]]
  then
    echo "sleeping waiting for license server"
    sleep $((1 + $RANDOM % 30))
  fi
done


cp /tmp/squish/etc/paths.ini /tmp/squish/etc/paths.ini-backup
cp /dockerstartup/paths.ini /tmp/squish/etc/

mkdir -p ${HOME}/.squish/ver1/
cp ${SERVER_INI} ${HOME}/.squish/ver1/server.ini

ulimit -c unlimited
export SQUISH_NO_CRASHHANDLER=1

/tmp/squish/bin/squishserver &

# squishrunner waits itself for a license to become available, but fails with error 37 if it cannot connect to the license server
LICENSE_ERROR_RESULT_CODE=37
result=LICENSE_ERROR_RESULT_CODE
echo "starting tests"
while true
do
  if [[ $(date -u +%s) -gt $endtime ]]
  then
    echo "timeout waiting for license server"
    exit 1
  fi
  /tmp/squish/bin/squishrunner --testsuite ${CLIENT_REPO}/test/gui/ ${SQUISH_PARAMETERS} --exitCodeOnFail 1
  result=$?
  if [[ $result -eq $LICENSE_ERROR_RESULT_CODE ]]
  then
    echo "sleeping waiting for license server"
    sleep $((1 + $RANDOM % 30))
  else
    exit $result
  fi
done
