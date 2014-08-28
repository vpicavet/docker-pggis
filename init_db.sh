#!/bin/sh

# wait for pg server to be ready
echo "Waiting for PostgreSQL to run..."
sleep 1
while ! /usr/bin/pg_isready -q
do
    sleep 1
    echo -n "."
done

# PostgreSQL running
echo "PostgreSQL running, initializing database."

# create postgresql user pggis
# create user and main database

/sbin/setuser postgres /usr/bin/psql -c "CREATE USER pggis with SUPERUSER PASSWORD 'pggis';"

/usr/bin/psql -U pggis -h localhost -c "CREATE DATABASE pggis WITH OWNER = pggis     ENCODING = 'UTF8'     TEMPLATE = template0    CONNECTION LIMIT = -1;" postgres

# activate all needed extension in pggis database
/usr/bin/psql -U pggis -h localhost -w -c "CREATE EXTENSION postgis; CREATE EXTENSION postgis_topology; CREATE EXTENSION pgrouting; CREATE EXTENSION pointcloud; CREATE EXTENSION pointcloud_postgis;" pggis

echo "Database initialized. Connect from host with :"
echo "psql -h localhost -p <PORT> -U pggis -W pggis"
echo "Get <PORT> value with 'docker ps'"
