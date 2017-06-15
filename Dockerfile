#
# Dockerfile for shadowsocks-libev
#
FROM gliderlabs/alpine:3.4
MAINTAINER Andy Savage <andy@savage.hk>

# Change versions here
ENV SS_VER "latest"

# Repo Info
ENV SS_REPO "shadowsocks/shadowsocks-libev"
ENV SS_IPSET_REPO "shadowsocks/ipset"
ENV SS_LIBCORK_REPO "shadowsocks/libcork"
ENV SS_LIBBLOOM_REPO "shadowsocks/libbloom"

EXPOSE 1080/tcp
EXPOSE 1080/udp

# Location of config file - Keep to default unless you need to change
ENV CONFIG_FILE "/config/config.json"
ENV VERBOSE_LOGGING "yes"

# Default config location on the container
ENV DEFAULT_CONFIG "/usr/local/default_ss_config.json"

VOLUME ["/config"]

RUN set -ex \
    && apk add --no-cache bash \
                      libcrypto1.0 \
                      libev \
                      libsodium \
                      mbedtls \
                      pcre \
                      udns \
    && apk add --no-cache \
        --virtual TMP autoconf \
                     automake \
                     build-base \
                     curl \
                     gettext-dev \
                     libev-dev \
                     libsodium-dev \
                     libtool \
                     linux-headers \
                     mbedtls-dev \
                     openssl-dev \
                     pcre-dev \
                     tar \
                     udns-dev

# Populate SS_VER with latest version
RUN SS_VER=`echo "$SS_VER" | tr -d "v"`; if [ "$SS_VER" == "" -o "$SS_VER" == "latest" ]; then export SS_VER=`curl -s "https://api.github.com/repos/$SS_REPO/releases" | grep "tag_name" | head -n 1 | tr -d '"",v' | cut -f2 -d ":"` | tr -d " "; fi
# Set the variables based on version
ENV SS_DIR "/tmp/shadowsocks-libev-$SS_VER"

RUN mkdir -p "/tmp" && cd "/tmp" \
    && curl -sSL https://github.com/$SS_REPO/archive/v$SS_VER.tar.gz | tar xz \
    && cd $SS_DIR
RUN curl -sSL https://github.com/$SS_IPSET_REPO/archive/shadowsocks.tar.gz | tar xz --strip 1 -C libipset
RUN curl -sSL https://github.com/$SS_LIBCORK_REPO/archive/shadowsocks.tar.gz | tar xz --strip 1 -C libcork
RUN curl -sSL https://github.com/$SS_LIBBLOOM_REPO/archive/master.tar.gz | tar xz --strip 1 -C libbloom \
        && ./autogen.sh \
        && ./configure --disable-documentation \
        && make install

# Cleanup files
RUN apk del TMP \
    && rm -rfv /tmp/*

# Copy files to container
COPY ./default_config.json "$DEFAULT_CONFIG"
COPY ./run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/bin/bash","/run.sh"]
