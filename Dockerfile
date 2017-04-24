FROM centos:7
MAINTAINER Steffen Vinther Sørensen <svinther@gmail.com>

ENV PGUSER=postgres \
    PGHOST=linkedpg \
    PGDATABASE=pdns

RUN yum -y install epel-release && \
    yum -y install pdns-backend-postgresql postgresql && \
    yum clean all

ADD docker-entrypoint.sh /
ADD pgsql-schema.sql /etc/pdns
ADD pdns.conf /etc/pdns/

EXPOSE 53/tcp 53/udp

ENTRYPOINT ["/docker-entrypoint.sh"]

