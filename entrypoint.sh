#!/usr/bin/env bash

# Examples:
#   export HAPROXY_CLIENT_TIMEOUT=30s
#   export HAPROXY_SERVER_TIMEOUT=30s
#   export API="bootstrap=192.168.222.30:6443,master-0=192.168.222.31:6443,master-1=192.168.222.32:6443,master-3=192.168.222.33:6443"
#   export API_LISTEN="127.0.0.1:6443,192.168.222.1:6443"
#   export INGRESS_HTTP="master-0=192.168.222.31:80,master-1=192.168.222.32:80,master-3=192.168.222.33:80,worker-0=192.168.222.34:80,worker-1=192.168.222.35:80,worker-3=192.168.222.36:80"
#   export INGRESS_HTTP_LISTEN="127.0.0.1:80,192.168.222.1:80"
#   export INGRESS_HTTPS="master-0=192.168.222.31:443,master-1=192.168.222.32:443,master-3=192.168.222.33:443,worker-0=192.168.222.34:443,worker-1=192.168.222.35:443,worker-3=192.168.222.36:443"
#   export INGRESS_HTTPS_LISTEN="127.0.0.1:443,192.168.222.1:443"
#   export MACHINE_CONFIG_SERVER="bootstrap=192.168.222.30:22623,master-0=192.168.222.31:22623,master-1=192.168.222.32:22623,master-3=192.168.222.33:22623"
#   export MACHINE_CONFIG_SERVER_LISTEN="127.0.0.1:22623,192.168.222.1:22623"
#   export STATS_LISTEN="127.0.0.1:1984"
#   export STATS_ADMIN_PASSWORD="aengeo4oodoidaiP"



function build_member_conf {
    DATA=$1
    IFS=,
    CONFIG=""
    for i in $DATA ; do
        # i contains 'name=ip:port'
        #       ${i%:=} => name
        #       ${i#*=} => ip:port
        CONFIG+="    server ${i%=*} ${i#*=} check\n"
    done
    echo -e $CONFIG;
}

function build_listen_conf {
    DATA=$1
    IFS=,
    CONFIG=""
    for i in $DATA ; do
        # i contains 'ip:port'
        CONFIG+="    bind ${i}\n"
    done
    echo -e $CONFIG;
}

if [ ! -z "${STATS_LISTEN}" ] && [ ! -z "${STATS_ADMIN_PASSWORD}" ] ; then
    echo "Stats enabled;"
    export STATS_CFG="
frontend stats
  bind $STATS_LISTEN
  mode http
  log             global

  maxconn 10
  timeout client 100s

  stats enable
  stats hide-version
  stats refresh 30s
  stats show-node
  stats auth admin:$STATS_ADMIN_PASSWORD
  stats uri /
"
else
    export STATS_CFG=""
fi

# If timeout valies are not set keep default to 1minute to maintain upward compatibility
export HAPROXY_CLIENT_TIMEOUT_CFG=${HAPROXY_CLIENT_TIMEOUT:-1m}
export HAPROXY_SERVER_TIMEOUT_CFG=${HAPROXY_SERVER_TIMEOUT:-1m}

export INGRESS_HTTP_CFG=$(build_member_conf $INGRESS_HTTP)
export INGRESS_HTTP_LISTEN_CFG=$(build_listen_conf ${INGRESS_HTTP_LISTEN:-*:80})

export INGRESS_HTTPS_CFG=$(build_member_conf $INGRESS_HTTPS)
export INGRESS_HTTPS_LISTEN_CFG=$(build_listen_conf ${INGRESS_HTTPS_LISTEN:-*:443})

export API_CFG=$(build_member_conf $API)
export API_LISTEN_CFG=$(build_listen_conf ${API_LISTEN:-*:6443})

export MACHINE_CONFIG_SERVER_CFG=$(build_member_conf $MACHINE_CONFIG_SERVER)
export MACHINE_CONFIG_SERVER_LISTEN_CFG=$(build_listen_conf ${MACHINE_CONFIG_SERVER_LISTEN:-*:22623})

envsubst < haproxy-template.cfg > /haproxy.cfg

exec "$@"
