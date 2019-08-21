#!/usr/bin/env bash

function build_conf {
    DATA=$1
    PORT=$2
    IFS=,
    CONFIG=""
    for i in $DATA ; do 
        # i containes 'NAME:IP'
        #       ${i%:*} => NAME
        #       ${i#*:} => IP
        
        CONFIG+="    server ${i%:*} ${i#*:}:$PORT check\n"

    done
    echo -e $CONFIG;
}

# Examples:
#   API="bootstrap:192.168.222.30,master-0:192.168.222.31,master-1:192.168.222.32,master-3:192.168.222.33"
#   INGRESS_HTTP="master-0:192.168.222.31,master-1:192.168.222.32,master-3:192.168.222.33,worker-0:192.168.222.34,worker-1:192.168.222.35,worker-3:192.168.222.36"
#   INGRESS_HTTPS="master-0:192.168.222.31,master-1:192.168.222.32,master-3:192.168.222.33,worker-0:192.168.222.34,worker-1:192.168.222.35,worker-3:192.168.222.36"
#   MACHEIN_CONFIG_SERVER="bootstrap:192.168.222.30,master-0:192.168.222.31,master-1:192.168.222.32,master-3:192.168.222.33"
# 
export INGRESS_HTTP_CFG=$(build_conf $INGRESS_HTTP 80)
export INGRESS_HTTPS_CFG=$(build_conf $INGRESS_HTTPS 443)
export API_CFG=$(build_conf $API 6443)
export MACHEIN_CONFIG_SERVER_CFG=$(build_conf $MACHEIN_CONFIG_SERVER 22623 )

envsubst < haproxy-template.cfg > /haproxy.cfg

exec "$@"