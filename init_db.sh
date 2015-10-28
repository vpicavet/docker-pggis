#!/bin/bash

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

# PostgreSQL user
#
# create postgresql user pggis

/sbin/setuser postgres /usr/bin/psql -c "CREATE USER pggis with SUPERUSER PASSWORD 'pggis';"

# == Auto restore dumps ==
#
# If we find some postgresql dumps in /data/restore, then we load it
# in new databases
shopt -s nullglob
for f in /data/restore/*.backup
do
	echo "Found database dump to restore : $f"
    DBNAME=$(basename -s ".backup" "$f")
    echo "Creating a new database $DBNAME.."
    /usr/bin/psql -U pggis -h localhost -c "CREATE DATABASE $DBNAME WITH OWNER = pggis     ENCODING = 'UTF8'     TEMPLATE = template0    CONNECTION LIMIT = -1;" postgres
    /usr/bin/psql -U pggis -h localhost -w -c "CREATE EXTENSION postgis; CREATE EXTENSION postgis_topology; CREATE EXTENSION pgrouting; CREATE EXTENSION pointcloud; CREATE EXTENSION pointcloud_postgis; CREATE EXTENSION postgis_sfcgal; drop type if exists texture; create type texture as (url text,uv float[][]);" $DBNAME
    echo "Restoring database $DBNAME.."
    /usr/bin/pg_restore -U pggis -h localhost -d $DBNAME -w "$f"
    echo "Restore done."
done

# == Auto restore SQL backups ==
#
# If we find some postgresql sql scripts /data/restore, then we load it
# in new databases
shopt -s nullglob
for f in /data/restore/*.sql
do
	echo "Found database SQL dump to restore : $f"
    DBNAME=$(basename -s ".sql" "$f")
    echo "Creating a new database $DBNAME.."
    /usr/bin/psql -U pggis -h localhost -c "CREATE DATABASE $DBNAME WITH OWNER = pggis     ENCODING = 'UTF8'     TEMPLATE = template0    CONNECTION LIMIT = -1;" postgres
    /usr/bin/psql -U pggis -h localhost -w -c "CREATE EXTENSION postgis; CREATE EXTENSION postgis_topology; CREATE EXTENSION pgrouting; CREATE EXTENSION pointcloud; CREATE EXTENSION pointcloud_postgis; CREATE EXTENSION postgis_sfcgal; drop type if exists texture; create type texture as (url text,uv float[][]);" $DBNAME
    echo "Restoring database $DBNAME.."
    /usr/bin/psql -U pggis -h localhost -d $DBNAME -w -f "$f"
    echo "Restore done."
done

# == create new database pggis ==
echo "Creating a new empty database..."
# create user and main database
/usr/bin/psql -U pggis -h localhost -c "CREATE DATABASE pggis WITH OWNER = pggis     ENCODING = 'UTF8'     TEMPLATE = template0    CONNECTION LIMIT = -1;" postgres

# activate all needed extension in pggis database
/usr/bin/psql -U pggis -h localhost -w -c "CREATE EXTENSION postgis; CREATE EXTENSION postgis_topology; CREATE EXTENSION postgis_sfcgal; CREATE EXTENSION pgrouting; CREATE EXTENSION pointcloud; CREATE EXTENSION pointcloud_postgis; drop type if exists texture;
create type texture as (url text,uv float[][]);" pggis

echo "Database initialized. Connect from host with :"
echo "psql -h localhost -p <PORT> -U pggis -W pggis"
echo "Get <PORT> value with 'docker ps'"
