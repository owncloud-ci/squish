#!/bin/bash

gnome-keyring-daemon --start --components=secrets
echo -n "${VNC_PW}" | gnome-keyring-daemon -r --unlock
gnome-keyring-daemon -d --login
