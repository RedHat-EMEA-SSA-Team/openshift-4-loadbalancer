#!/usr/bin/env bash

function build_conf {
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

# Examples:
#   export API="bootstrap=192.168.222.30:6443,master-0=192.168.222.31:6443,master-1=192.168.222.32:6443,master-3=192.168.222.33:6443"
#   export INGRESS_HTTP="master-0=192.168.222.31:80,master-1=192.168.222.32:80,master-3=192.168.222.33:80,worker-0=192.168.222.34:80,worker-1=192.168.222.35:80,worker-3=192.168.222.36:80"
#   export INGRESS_HTTPS="master-0=192.168.222.31:443,master-1=192.168.222.32:443,master-3=192.168.222.33:443,worker-0=192.168.222.34:443,worker-1=192.168.222.35:443,worker-3=192.168.222.36:443"
#   export MACHEIN_CONFIG_SERVER="bootstrap=192.168.222.30:22623,master-0=192.168.222.31:22623,master-1=192.168.222.32:22623,master-3=192.168.222.33:22623"
# 
export INGRESS_HTTP_CFG=$(build_conf $INGRESS_HTTP)
export INGRESS_HTTPS_CFG=$(build_conf $INGRESS_HTTPS)
export API_CFG=$(build_conf $API)
export MACHEIN_CONFIG_SERVER_CFG=$(build_conf $MACHEIN_CONFIG_SERVER)

envsubst < haproxy-template.cfg > /haproxy.cfg

exec "$@"