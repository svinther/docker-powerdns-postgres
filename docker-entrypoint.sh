#!/bin/bash

set -e
PSQL="psql -h linkedpg"
SQLITE="sqlite3 /var/lib/sqlite/sqlite.db"

setpdnsconf_sqlite() {
cat << EOF > /etc/pdns/pdns.conf
setuid=pdns
setgid=pdns
launch=gsqlite3
gsqlite3-database=/var/lib/sqlite/sqlite.db
gsqlite3-pragma-synchronous=0
slave=yes
EOF

cat << 'EOF' > /usr/local/bin/addslave
#!/bin/bash

set -e

domain=$1
masterip=$2
: ${domain:?"ARGS:=<domainname> <masterip>"}
: ${masterip:?"ARGS:=<domainname> <masterip>"}

$SQLITE <<< "INSERT INTO domains (name, master, type) VALUES ('$domain', '$masterip', 'SLAVE');" 
EOF
chmod +x /usr/local/bin/addslave
}

setpdnsconf_postgres() {
cat << EOF > /etc/pdns/pdns.conf
setuid=pdns
setgid=pdns
launch=gpgsql
gpgsql-user=postgres
gpgsql-dbname=pdns
master=yes
EOF

cat << 'EOF' > /usr/local/bin/addslave
#!/bin/bash

set -e

domain=$1
masterip=$2
: ${domain:?"ARGS:=<domainname> <masterip>"}
: ${masterip:?"ARGS:=<domainname> <masterip>"}

$PSQL <<< "INSERT INTO domains (name, master, type) VALUES ('$domain', '$masterip', 'SLAVE');" 
EOF
chmod +x /usr/local/bin/addslave
}
#check if we got a postgres database
ping -c1 -W1 linkedpg &> /dev/null || nopg=$?
if [[ -z $nopg ]]; then
 echo "Trying postgres setup"

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

 setpdnsconf_postgres
else

 echo "Trying sqlite setup"
 if [[ ! -d /var/lib/sqlite ]]; then
  mkdir /var/lib/sqlite
 fi

 if [[ ! -f /var/lib//sqlite/sqlite.db ]]; then
  $SQLITE < /etc/pdns/sqlite-schema.sql

  if [[ -n "$SUPERMASTER" ]]; then
   #if SUPERMASTER is set, then we go superslave with sqlite3 backend

   SUPER_HOSTNAME=$(cut -d':' -f1 <<< $SUPERMASTER)
   SUPER_IP=$(cut -d':' -f2 <<< $SUPERMASTER)

   : ${SUPER_HOSTNAME:?"SUPERMASTER env must be formatted as <hostname>;<ip>"}
   : ${SUPER_IP:?"SUPERMASTER env must be formatted as <hostname>;<ip>"}

   $SQLITE <<< "INSERT INTO supermasters VALUES ('$SUPER_IP', '$SUPER_HOSTNAME', '');"
  fi
 fi
 chown -R pdns.pdns /var/lib/sqlite

 setpdnsconf_sqlite
fi



trap "/usr/bin/pdns_control quit" SIGHUP SIGINT SIGTERM

exec /usr/sbin/pdns_server "$@"


