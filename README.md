# PowerDNS Docker Container for PostgreSQL

* Based on CentOS 7 
* Starts a slave pdns instance by default
* Looks for postgresql dbms at host linkedpg dbname=pdns
* Only if the pdns database is not found, it is created and populated

## Example use

    docker volume create --name pdns-postgres 
    docker run --name pdns-postgres -v pdns-postgres:/var/lib/postgresql/data -d postgres 
    docker run --name pdns --link pdns-postgres:linkedpg -d svinther/docker-powerdns-postgres

## Maintainer

* Steffen Vinther Sørensen <svinther@gmail.com>


