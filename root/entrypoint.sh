#!/bin/bash

MD5SUM="/usr/bin/md5sum"

DEFAULT_CONFIG="/usr/local/share/ss_config.json.default"

if [ "$SS_MODE" == "server" ]; then
  SS_BIN="/usr/local/bin/ss-server"
elif [ "$SS_MODE" == "local" -o "$SS_MODE" == "client" ]; then
  SS_BIN="/usr/local/bin/ss-local"
else
  echo "Unknown SS_MODE \"${SS_MODE}\".  Aborting."
  exit 1
fi

command -v "$SS_BIN" >/dev/null 2>&1 || { echo >&2 "I require ${SS_BIN} but it's not installed.  Aborting."; exit 1; }

if [[ "$VERBOSE_LOGGING" == "yes" ]]; then
  VERBOSE="-v"
else
  VERBOSE=""
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "No config file found at $CONFIG_FILE.  Aborting."

fi

exec "$SS_BIN" -c "$CONFIG_FILE" "$VERBOSE" -d "$DNS_SERVER_ADDR1" -d "$DNS_SERVER_ADDR2" "$@"
