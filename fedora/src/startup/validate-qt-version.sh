#!/bin/bash

. "${STARTUPDIR}"/common.sh

if ! install_squish; then
  exit 1
fi

# Parse package name
# E.g:
# Package Name:  squish-8.0.0-qt67x-linux64
# ...
# 
# OUTPUT:
#   67
squish_qt=$(cat "$SQUISH_INSTALL_DIR/buildinfo.txt" | grep -oP 'Package Name:  \K.*' | grep -oP 'qt\d+x' | grep -oP '\d+')

# Parse installed Qt version
# E.g:
# QMake version 3.1
# Using Qt version 6.7.0 in /usr/lib/x86_64-linux-gnu
# 
# OUTPUT:
#   67
system_qt=$(qmake -v | grep -oP 'Qt version \K\d+\.\d+' | sed 's/\.//g')

if [[ -z $system_qt ]] || [[ -z $squish_qt ]] || [[ $squish_qt -ne $system_qt ]]; then
    echo "Qt version mismatch: Squish Qt version '$squish_qt', system Qt version '$system_qt'"
    echo "Qt <major>.<minor> version must match!"
    exit 1
fi
