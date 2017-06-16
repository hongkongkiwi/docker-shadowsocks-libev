# hongkongkiwi/docker-shadowsocks
![](https://images.microbadger.com/badges/version/hongkongkiwi/shadowsocks-libev.svg)
![](https://images.microbadger.com/badges/image/hongkongkiwi/shadowsocks-libev.svg)
![Docker Pulls](https://img.shields.io/docker/pulls/hongkongkiwi/shadowsocks-libev.svg)
![Docker Stars](https://img.shields.io/docker/stars/hongkongkiwi/shadowsocks-libev.svg)

Shadowsocks-libev is a lightweight secured SOCKS5 proxy for embedded devices and low-end boxes.

It is a port of Shadowsocks created by @clowwindy, and maintained by @madeye and @linusyang.

Shadowsocks-libev is written in pure C and depends on libev. It's designed to be a lightweight implementation of shadowsocks protocol, in order to keep the resource usage as low as possible.

For a full list of feature comparison between different versions of shadowsocks, refer to the Wiki page.

[![shadowsocks-libev logo](https://gaukas.wang/wp-content/uploads/2015/11/Shadowsocks.png)](https://github.com/shadowsocks/shadowsocks-libev)

## Usage

### Creating a Server
```
docker create \
--name="shadowsocks-libev-server" \
-v <path to server config file>:/config/ss_config.json \
-e SS_MODE="server" \
-p 8080:8080 \
hongkongkiwi/shadowsocks-libev
```

### Creating a Client
```
docker create \
--name="shadowsocks-libev-client" \
-v <path to client config file>:/config/ss_config.json \
-e SS_MODE="client" \
-p 1080:1080 \
hongkongkiwi/shadowsocks-libev
```

### Testing the client
```
curl --socks5-hostname 127.0.0.1:1080 "http://www.google.com"
```

## Parameters

`The parameters are split into two halves, separated by a colon, the left hand side representing the host and the right the container side.
For example with a port -p external:internal - what this shows is the port mapping from internal to external of the container.
So -p 1080:1090 would expose port 1080 from inside the container to be accessible from the host's IP on port 1090
http://192.168.x.x:1090 would show you what's running INSIDE the container on port 1080.`


* `-p 1080:1080` or `-p 8080:8080` - the port(s)
* `-v /config/ss_config.json` - location of configuration file
* `-e SS_MODE` for setting whether we are running as a server or client. Set to either "server" or "client"
* `-e PGID` for GroupID - see below for explanation
* `-e PUID` for UserID - see below for explanation
* `-e TZ` for setting timezone information, eg Europe/London

It is based on a minimal alpine linux build, for shell access whilst the container is running do `docker exec -it "shadowsocks-libev-client" /bin/bash` or `docker exec -it "shadowsocks-libev-server" /bin/bash`.

### User / Group Identifiers

Sometimes when using data volumes (`-v` flags) permissions issues can arise between the host OS and the container. We avoid this issue by allowing you to specify the user `PUID` and group `PGID`. Ensure the data volume directory on the host is owned by the same user you specify and it will "just work" ™.

In this instance `PUID=1001` and `PGID=1001`. To find yours use `id user` as below:

```
  $ id <dockeruser>
    uid=1001(dockeruser) gid=1001(dockergroup) groups=1001(dockergroup)
```

## Setting up the application

You will need to setup a config file to use for each kind of server. You can use some default settings as below:


### Server
```
{
    "server": "0.0.0.0",
    "server_port": 8080,
    "local_address": "0.0.0.0",
    "local_port":1080,
    "password": "YOUR_PASSWORD",
    "timeout": 300,
    "method": "rc4-md5",
    "fast_open": false
}
```
Note: Change YOUR_PASSWORD to whatever you want

### Client
```
{
    "server": "YOUR_LOCAL_IP",
    "server_port": 8080,
    "local_address": "0.0.0.0",
    "local_port":1080,
    "password": "YOUR_PASSWORD",
    "timeout": 300,
    "method": "rc4-md5",
    "fast_open": false
}
```
Note: Change YOUR_LOCAL_IP and YOUR_PASSWORD to whatever you want

## Info

* To monitor the logs of the container in realtime `docker logs -f "shadowsocks-libev-client"` or `docker logs -f "shadowsocks-libev-server"`.

## Versions

+ **16.06.17:** Initial Release
