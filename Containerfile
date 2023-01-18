FROM registry.access.redhat.com/ubi9/ubi-minimal

MAINTAINER Robert Bohne <robert.bohne@redhat.com>

RUN microdnf update -y && rm -rf /var/cache/yum
RUN microdnf install haproxy gettext nmap-ncat -y \
    && microdnf clean all

EXPOSE 6443
EXPOSE 80
EXPOSE 443
EXPOSE 22623

# https://www.haproxy.org/download/1.8/doc/management.txt
# "4. Stopping and restarting HAProxy"
# "when the SIGTERM signal is sent to the haproxy process, it immediately quits and all established connections are closed"
# "graceful stop is triggered when the SIGUSR1 signal is sent to the haproxy process"
STOPSIGNAL SIGUSR1


COPY entrypoint.sh /
COPY watch-stats.sh /
COPY haproxy-template.cfg /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["haproxy", "-f", "/haproxy.cfg"]

