#!/bin/bash

set -e

PSQL="psql -h linkedpg"

# wait for postgres to start
pgready () {
  echo "SELECT 1" | $PSQL postgres 1> /dev/null
  echo $?
}

RETRY=10
until [ $(pgready) -eq 0 ] || [ $RETRY -le 0 ] ; do
  echo "Waiting for postgres"
  sleep 2
  RETRY=$(expr $RETRY - 1)
done
if [ $RETRY -le 0 ]; then
  >&2 echo Error: Could not connect to postgres
  exit 1
fi

DBEXISTS=$(echo "SELECT 'true' FROM pg_database WHERE datname = '$PGDATABASE'" | $PSQL -qAt postgres)
if [ ! "$DBEXISTS" ]; then
 echo "CREATE DATABASE \"$PGDATABASE\"" | $PSQL postgres
 $PSQL < /etc/pdns/pgsql-schema.sql
fi


trap "/usr/bin/pdns_control quit" SIGHUP SIGINT SIGTERM

exec /usr/sbin/pdns_server "$@"


