#!/bin/bash

# DBUS_ENV_FILE is used in entrypoint.sh and vnc_startup.sh files
DBUS_ENV_FILE=/tmp/dbus_env
SQUISH_INSTALL_LOG="${HOME}/squish-installation.log"

mkdir -p "${HOME}"

function install_squish() {

    # TODO nicer
    # ghostunnel stuff

    echo "Starting ghostunnel"
    /opt/ghostunnel client \
        --listen localhost:8003 \
        --target "$LICENSEKEY" \
        --cacert /drone/src/cacert \
        --key /drone/src/client-key \
        --cert /drone/src/client-cert &


    echo "[SQUISH] Installing squish..."
    echo "[SQUISH] Installation report: ${SQUISH_INSTALL_LOG}"

    /opt/squish.run unattended=1 ide=0 doc=0 examples=0 targetdir="${SQUISH_INSTALL_DIR}" licensekey="localhost:8003" >>"${SQUISH_INSTALL_LOG}" 2>&1
    result=$?

    if [[ $result -ne 0 ]]; then
        echo "[SQUISH] Failed to install squish."
        cat "$SQUISH_INSTALL_LOG"
        if [ -f "$HOME/squish/SquishConfig.log" ]; then
            echo "-----------------------------------------"
            cat "$HOME/squish/SquishConfig.log"
        fi
        return $result
    else
        echo "[SQUISH] Squish installed successfully."
    fi
}
