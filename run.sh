#!/bin/bash

SS_LOCAL="/usr/local/bin/ss-local"
MD5SUM="/usr/bin/md5sum"

command -v "$SS_LOCAL" >/dev/null 2>&1 || { echo >&2 "I require ss-local but it's not installed.  Aborting."; exit 1; }
command -v "$MD5SUM" >/dev/null 2>&1 || { echo >&2 "I require md5sum but it's not installed.  Aborting."; exit 1; }

if [[ "$VERBOSE_LOGGING" == "yes" ]]; then
  VERBOSE="-v"
else
  VERBOSE=""
fi

DEFAULT_CONFIG_MD5=`$MD5SUM "$DEFAULT_CONFIG" | cut -f1 -d " "`

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "No config file found, copying default"
  cp "$DEFAULT_CONFIG" "$CONFIG_FILE"
fi

CONFIG_MD5SUM=`$MD5SUM "$CONFIG_FILE" | cut -f1 -d " "`

if [[ "$CONFIG_MD5SUM" == "$DEFAULT_CONFIG_MD5" ]]; then
  echo "Config file needs to be changed from default! Please update an re-run!"
  exit 1
fi

exec "$SS_LOCAL" -c "$CONFIG_FILE" "$VERBOSE"
