# OpenShift 4 load balancer container image
OpenShift 4 load balancer for PoC's or developemt/testing purpose - NOT for production purpose

**If you push changes to master, we'll immediately launch an image build on
[quay.io](https://quay.io/repository/redhat-emea-ssa-team/openshift-4-loadbalancer?tab=info)!**

![build status](https://quay.io/repository/redhat-emea-ssa-team/openshift-4-loadbalancer/status)

If you like to play with it and look around: 
```
podman run -ti quay.io/redhat-emea-ssa-team/openshift-4-loadbalancer bash
$ haproxy -f /haproxy.cfg
```


## Environment variables
| Variable  | Description | Example |
|----|----|----|
|API|API Member |`bootstrap=192.168.222.30:6443,master-0=192.168.222.31:6443`
|API_LISTEN|API listener |`127.0.0.1:6443,192.168.222.1:6443`
|INGRESS_HTTP|Ingress http member|`worker-0=192.168.222.34:443`
|INGRESS_HTTP_LISTEN|Ingress http listener|`127.0.0.1:80,192.168.222.1:80`
|INGRESS_HTTPS|Ingress http listener|`worker-0=192.168.222.34:443`
|INGRESS_HTTPS_LISTEN|Ingress https listener|`127.0.0.1:443,192.168.222.1:443`
|MACHINE_CONFIG_SERVER|Machine config server member|`bootstrap=192.168.222.30:22623,master-0=192.168.222.31:22623`
|MACHINE_CONFIG_SERVER_LISTEN|Machine config server listener|`127.0.0.1:22623,192.168.222.1:22623`
|STATS_LISTEN|Stats listen if empty stats on TCP socket is disabled|`127.0.0.1:1984`
|STATS_ADMIN_PASSWORD|Stats admin passwort if empty stats on TCP socket is disabled|`aengeo4oodoidaiP`

### HA Proxy conf based on examples above
```
global
    log         127.0.0.1 local2

    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats



listen stats 127.0.0.1:1984
  mode            http
  log             global

  maxconn 10
  timeout client 100s
  timeout server 100s
  timeout connect 100s
  timeout queue   100s

  stats enable
  stats hide-version
  stats refresh 30s
  stats show-node
  stats auth admin:aengeo4oodoidaiP
  stats uri /


#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------

defaults
    mode                    http
    log                     global
    #option                  httplog
    option                  dontlognull
    #option http-server-close
    #option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000

listen ingress-http
    bind 127.0.0.1:80
    bind 192.168.222.1:80
    mode tcp
    server worker-0 192.168.222.34:80 check

listen ingress-https
    bind 127.0.0.1:443
    bind 192.168.222.1:443
    mode tcp
    server worker-0 192.168.222.34:443 check

listen api
    bind 127.0.0.1:6443
    bind 192.168.222.1:6443
    mode tcp
    server bootstrap 192.168.222.30:6443 check
    server master-0 192.168.222.31:6443 check

listen machine-config-server
    bind 127.0.0.1:22623
    bind 192.168.222.1:22623
    mode tcp
    server bootstrap 192.168.222.30:22623 check
    server master-0 192.168.222.31:22623 check
```

## Show stats via unix socket

```
podman exec -ti openshift-4-loadbalancer /watch-stats.sh
```
## Deployment 

### Systemd service example

`/etc/systemd/system/openshift-4-loadbalancer.service`:

```
[Unit]
Description=OpenShift 4 LoadBalancer CLUSTER
After=network.target

[Service]
Type=simple
TimeoutStartSec=5m

ExecStartPre=-/usr/bin/podman rm "openshift-4-loadbalancer"
ExecStartPre=/usr/bin/podman pull quay.io/redhat-emea-ssa-team/openshift-4-loadbalancer
ExecStart=/usr/bin/podman run --name openshift-4-loadbalancer --net host \
  -e API=bootstrap=192.168.222.30:6443,master-0=192.168.222.31:6443,master-1=192.168.222.32:6443,master-3=192.168.222.33:6443 \
  -e API_LISTEN=127.0.0.1:6443,192.168.222.1:6443 \
  -e INGRESS_HTTP=master-0=192.168.222.31:80,master-1=192.168.222.32:80,master-3=192.168.222.33:80,worker-0=192.168.222.34:80,worker-1=192.168.222.35:80,worker-3=192.168.222.36:80 \
  -e INGRESS_HTTP_LISTEN=127.0.0.1:80,192.168.222.1:80 \
  -e INGRESS_HTTPS=master-0=192.168.222.31:443,master-1=192.168.222.32:443,master-3=192.168.222.33:443,worker-0=192.168.222.34:443,worker-1=192.168.222.35:443,worker-3=192.168.222.36:443 \
  -e INGRESS_HTTPS_LISTEN=127.0.0.1:443,192.168.222.1:443 \
  -e MACHINE_CONFIG_SERVER=bootstrap=192.168.222.30:22623,master-0=192.168.222.31:22623,master-1=192.168.222.32:22623,master-3=192.168.222.33:22623 \
  -e MACHINE_CONFIG_SERVER_LISTEN=127.0.0.1:22623,192.168.222.1:22623 \
  -e STATS_LISTEN=127.0.0.1:1984 \
  -e STATS_ADMIN_PASSWORD=aengeo4oodoidaiP \
  quay.io/redhat-emea-ssa-team/openshift-4-loadbalancer

ExecReload=-/usr/bin/podman stop "openshift-4-loadbalancer"
ExecReload=-/usr/bin/podman rm "openshift-4-loadbalancer"
ExecStop=-/usr/bin/podman stop "openshift-4-loadbalancer"
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
```
