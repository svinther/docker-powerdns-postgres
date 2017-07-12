# PowerDNS Docker Container for PostgreSQL/SQLite

* Based on CentOS 7 
* Starts either a master with postgres backend, or a sqlite slave instance

In case of running in master mode, a postgres backend container must be available
* postgres backend container must be linked as 'linkedpg'
* Only if the 'pdns' database is not found, it is created and populated with table defs etc.

## Example use

### Run a master dns with persistent volume

    docker volume create --name pdns-postgres 
    docker run --name pdns-postgres -v pdns-postgres:/var/lib/postgresql/data -d postgres 
    docker run --name pdns --link pdns-postgres:linkedpg -d svinther/docker-powerdns-postgres

### Run a superslave with persistent volume

    #Specify host:ip of the supermaster in env variable
    docker volume create --name pdns-sqlite
    docker run --name pdns -e SUPERMASTER="host:ip" -v pdns-sqlite:/var/lib/sqlite -d svinther/docker-powerdns-postgres

### Run with overrides

All settings can be overrided at the 'docker run' phase, for a list of available overrides:

    docker exec -ti <container> pdns_server --help

## Show running config

    docker exec -ti <container> pdns_control current-config


## Maintainer

* Steffen Vinther Sørensen <svinther@gmail.com>


