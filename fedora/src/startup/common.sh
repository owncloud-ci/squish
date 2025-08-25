#!/bin/bash

# DBUS_ENV_FILE is used in entrypoint.sh and vnc_startup.sh files
DBUS_ENV_FILE=/tmp/dbus_env
SQUISH_INSTALL_DIR="${HOME}/squish"
SQUISH_INSTALL_LOG="${HOME}/squish-installation.log"

function install_squish() {
    echo "[SQUISH] Installing squish..."
    echo "[SQUISH] Installation report: ${SQUISH_INSTALL_LOG}"

    /opt/squish.run unattended=1 ide=0 doc=0 examples=0 targetdir="${SQUISH_INSTALL_DIR}" licensekey="${LICENSEKEY}" >>"${SQUISH_INSTALL_LOG}" 2>&1
    result=$?

    if [[ $result -ne 0 ]]; then
        echo "[SQUISH] Failed to install squish."
        cat "$SQUISH_INSTALL_LOG"
        if [ -f "$HOME/squish/SquishConfig.log" ]; then
            echo "-----------------------------------------"
            cat "$HOME/squish/SquishConfig.log"
        fi
        return $result
    fi
}
