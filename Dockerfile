FROM centos:7

MAINTAINER Robert Bohne <robert.bohne@redhat.com>

RUN yum install -y haproxy gettext && \
    yum update -y && \
    yum clean all

EXPOSE 6443
EXPOSE 80
EXPOSE 443
EXPOSE 22623

ENV  API="bootstrap=192.168.222.30:6443,master-0=192.168.222.31:6443,master-1=192.168.222.32:6443,master-3=192.168.222.33:6443"
ENV  INGRESS_HTTP="master-0=192.168.222.31:80,master-1=192.168.222.32:80,master-3=192.168.222.33:80,worker-0=192.168.222.34:80,worker-1=192.168.222.35:80,worker-3=192.168.222.36:80"
ENV  INGRESS_HTTPS="master-0=192.168.222.31:443,master-1=192.168.222.32:443,master-3=192.168.222.33:443,worker-0=192.168.222.34:443,worker-1=192.168.222.35:443,worker-3=192.168.222.36:443"
ENV  MACHEIN_CONFIG_SERVER="bootstrap=192.168.222.30:22623,master-0=192.168.222.31:22623,master-1=192.168.222.32:22623,master-3=192.168.222.33:22623"

# https://www.haproxy.org/download/1.8/doc/management.txt
# "4. Stopping and restarting HAProxy"
# "when the SIGTERM signal is sent to the haproxy process, it immediately quits and all established connections are closed"
# "graceful stop is triggered when the SIGUSR1 signal is sent to the haproxy process"
STOPSIGNAL SIGUSR1


COPY entrypoint.sh /
COPY haproxy-template.cfg /
ENTRYPOINT ["/entrypoint.sh"]
CMD ["haproxy", "-f", "/haproxy.cfg"]

