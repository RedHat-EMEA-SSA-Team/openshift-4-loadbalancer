#!/usr/bin/env bash

while true; do printf "\033c"; echo "show stat" | nc -U /var/lib/haproxy/stats | cut -d "," -f 1,2,18,57| column -s, -t; sleep 2; done
