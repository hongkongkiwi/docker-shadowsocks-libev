#!/bin/bash

# specify module size in dots (pixels). (default=3)
QR_ERROR_CORRECTION="L"
# specify module size in dots (pixels). (default=3)
QR_MODULE_SIZE=3
# specify the DPI of the generated PNG. (default=72)
QR_PNG_DPI=72
# specify the type of the generated image. (default=PNG)
# PNG,PNG32,EPS,SVG,XPM,ANSI,ANSI256,ASCII,ASCIIi,UTF8,ANSIUTF8}
QR_IMG_FORMAT=${QR_IMG_FORMAT:-"PNG"}
QR_IMG_FORMAT=`echo "$QR_IMG_FORMAT" | tr '[:lower:]' '[:upper:]'`
# specify the width of the margins. (default=4 (2 for Micro))
QR_MARGIN_WIDTHS=4
# specify the minimum version of the symbol. (default=auto)
QR_MINIMUM_VERSION="auto"
QR_ADDITIONAL_OPTS=""
SYSTEM_LOCALHOST="127.0.0.1"

[ $SS_MODE == "client" ] && SS_MODE="local"

SS_BIN=""
if [ "$SS_MODE" == "server" ]; then
  SS_BIN="ss-server"
elif [ "$SS_MODE" == "local" ]; then
  SS_BIN='ss-local'
else
  echo "Unknown SS_MODE \"$SS_MODE\".  Aborting."
  exit 1
fi

if [ "$VERBOSE_LOGGING" == "yes" ]; then
  VERBOSE="-v"
else
  VERBOSE=""
fi

if [ ! -f "$CONFIG_FILE" ]; then
  echo "No config file found at $CONFIG_FILE.  Aborting."
  exit 1
fi

# Output the QRCode file
if [ "$ADD_QRCODE_SUPPORT" == "yes" ]; then
  if [ "$GENERATE_QRCODE" == "yes" ]; then
    command -v "jq" >/dev/null 2>&1 || { echo >&2 "I require jq but it's not installed.  Aborting."; exit 1; }
    command -v "base64" >/dev/null 2>&1 || { echo >&2 "I require base64 but it's not installed.  Aborting."; exit 1; }
    command -v "qrencode" >/dev/null 2>&1 || { echo >&2 "I require qrencode but it's not installed.  Aborting."; exit 1; }
    SS_ENC_TYPE=`cat "$CONFIG_FILE" | jq .method | sed -e 's/^"//' -e 's/"$//'`
    if [ "$SS_MODE" == "server" ]; then
      if [ "$QR_SERVER_ADDR" == "" ]; then
        command -v "dig" >/dev/null 2>&1 || { echo >&2 "I require dig but it's not installed.  Aborting."; exit 1; }
        SS_SERVER_ADDR=`dig +short myip.opendns.com @resolver1.opendns.com`
      else
        SS_SERVER_ADDR="$QR_SERVER_ADDR"
      fi
    else
      SS_SERVER_ADDR=`cat "$CONFIG_FILE" | jq .server | sed -e 's/^"//' -e 's/"$//'`
    fi
    SS_SERVER_PORT=`cat "$CONFIG_FILE" | jq .server_port | sed -e 's/^"//' -e 's/"$//'`
    SS_PASSWORD=`cat "$CONFIG_FILE" | jq .password | sed -e 's/^"//' -e 's/"$//'`
    if [ "$SS_ENC_TYPE" != "" ] && [ "$SS_SERVER_ADDR" != "" ] && [ "$SS_SERVER_ADDR" != "0.0.0.0" ] && [ "$SS_SERVER_PORT" != "0" ] && [ "$SS_PASSWORD" != "" ]; then
      URI=$(echo -n "ss://"`echo -n ${SS_ENC_TYPE}:${SS_PASSWORD}@${SS_SERVER_ADDR}:${SS_SERVER_PORT} | base64`)
      qrencode -s $QR_MODULE_SIZE \
                    -l "$QR_ERROR_CORRECTION" \
                    -d $QR_PNG_DPI \
                    -m $QR_MARGIN_WIDTHS \
                    -t "$QR_IMG_FORMAT" \
                    -v "$QR_MINIMUM_VERSION" \
                    -o "$QRCODE_FILE" \
                    $QR_ADDITIONAL_OPTS \
                    "$URI"
    else
      echo "Invalid $CONFIG_FILE details! Skipping QRCode generation"
    fi
  else
    echo "Generating QRCodes are disabled, skipping."
  fi
fi

DNS_OPTS=""
if [ "$SS_MODE" == "local" ] && [ "$DNS_SERVER_ADDRS" != "" ]; then
   DNS_OPTS=`echo "-d $DNS_SERVER_ADDRS" | sed 's/,/ -d /g'`
fi

command -v "$SS_BIN" >/dev/null 2>&1 || { echo >&2 "I require $SS_BIN but it's not installed.  Aborting."; exit 1; }

SS_OBFS_OPTS=""
# Info here for obfs https://hub.docker.com/r/liaohuqiu/simple-obfs/
if [ "$ADD_OBFS_SUPPORT" == "yes" ] && [ "$ENABLE_OBFS" == "yes" ]; then
  command -v "obfs-$SS_MODE" >/dev/null 2>&1 || { echo >&2 "I require obfs-$SS_MODE but it's not installed.  Aborting."; exit 1; }
  SS_SERVER_PORT=`cat "$CONFIG_FILE" | jq .server_port | sed -e 's/^"//' -e 's/"$//'`
  if [ "$SS_MODE" == "server" ]; then
    exec "obfs-server" -p $OBFS_PORT --obfs "$OBFS_TYPE" -r "$SYSTEM_LOCALHOST:$SS_SERVER_PORT"
    SS_OBFS_OPTS="-s $SYSTEM_LOCALHOST"
  elif [ "$SS_MODE" == "local" ]; then
    SS_SERVER_ADDR=`cat "$CONFIG_FILE" | jq .server | sed -e 's/^"//' -e 's/"$//'`
    exec "obfs-local" -s "$SS_SERVER_ADDR" -p "$SS_SERVER_PORT" --obfs "$OBFS_TYPE" -l $OBFS_PORT --obfs-host "$OBFS_HOST"
    SS_OBFS_OPTS="-l $SYSTEM_LOCALHOST"
  else
    echo "We want obfs support but are running unknown mode $SS_MODE. Ignoring!"
  fi
fi

exec $SS_BIN -c "$CONFIG_FILE" $DNS_OPTS $SS_OBFS_OPTS "$VERBOSE" "$@"
