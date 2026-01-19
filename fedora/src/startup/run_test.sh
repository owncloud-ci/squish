#!/bin/bash

# squishrunner waits itself for a license to become available, but fails with error 37 if it cannot connect to the license server
LICENSE_ERROR_RESULT_CODE=37
result=0
echo "[SQUISH] Starting tests..."
while true; do
  if [[ $(date -u +%s) -gt $endtime ]]; then
    echo "[SQUISH] Timeout waiting for license server"
    exit 1
  fi

  ${HOME}/squish/bin/squishrunner ${SQUISH_PARAMETERS} --reportgen stdout --exitCodeOnFail 1
  result=$?
  if [[ $result -eq $LICENSE_ERROR_RESULT_CODE ]]; then
    echo "[SQUISH] Waiting for license server"
    sleep $((1 + $RANDOM % 30))
  else
    exit $result
  fi
done
