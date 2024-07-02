#!/bin/bash
export USER=headless

/dockerstartup/vnc_startup.sh &

#maximum time to wait for licenses (before installation of squish + before running tests)
runtime="30 minute"
endtime=$(date -ud "$runtime" +%s)

result=1
echo "[SQUISH] Installing squish..."

# retry installing squish if there is an issue to connect the license server
while [[ $result -ne 0 ]]; do
  if [[ $(date -u +%s) -gt $endtime ]]; then
    echo "[SQUISH] Timeout waiting for license server"
    exit 1
  fi

  /opt/squish.run unattended=1 ide=0 targetdir="${HOME}"/squish licensekey="$LICENSEKEY" >>"${HOME}/squish-installation.log" 2>&1
  result=$?

  if [[ $result -ne 0 ]]; then
    echo "[SQUISH] Waiting for license server"
    sleep $((1 + $RANDOM % 30))
  fi
done

cp "${HOME}"/squish/etc/paths.ini "${HOME}"/squish/etc/paths.ini-backup
cp /dockerstartup/paths.ini "${HOME}"/squish/etc/

mkdir -p "${HOME}"/.squish/ver1/
cp "${SERVER_INI}" "${HOME}"/.squish/ver1/server.ini

# Set allowed core dump size to an unlimited value, needed for backtracing
ulimit -c unlimited

# Turn off the Squish crash handler by setting this environment variable
export SQUISH_NO_CRASHHANDLER=1

(/home/headless/squish/bin/squishserver >>"${GUI_TEST_REPORT_DIR}"/serverlog.log 2>&1) &

# squishrunner waits itself for a license to become available, but fails with error 37 if it cannot connect to the license server
LICENSE_ERROR_RESULT_CODE=37
result=LICENSE_ERROR_RESULT_CODE
echo "[SQUISH] Starting tests..."
while true; do
  if [[ $(date -u +%s) -gt $endtime ]]; then
    echo "[SQUISH] Timeout waiting for license server"
    exit 1
  fi

  ~/squish/bin/squishrunner ${SQUISH_PARAMETERS} --reportgen stdout --exitCodeOnFail 1
  result=$?
  if [[ $result -eq $LICENSE_ERROR_RESULT_CODE ]]; then
    echo "[SQUISH] Waiting for license server"
    sleep $((1 + $RANDOM % 30))
  else
    exit $result
  fi
done
