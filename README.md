A PG GIS setup for Docker
=========================

Presentation
------------

This Docker image is a container with all latest PostgreSQL extensions needed to do serious GIS work.
It is based on Ubuntu 14.04 and features :

* PostgreSQL 9.4 (from PGDG packages)
* PostGIS 2.1.5 (compiled from release sources) with SFCGAL support (git master)
* PgRouting (git master)
* PostgreSQL PointCloud extension (git master)
* PDAL (git master)

It creates a pggis database with a pggis superuser (password pggis), with postgis, pgrouting and pointcloud extensions activated. It is therefore ready to eat data, and you can enjoy 2D vector and raster features, 3D support and functions, large point data volumes and analysis, topology support and all PostgreSQL native features.

Just get me started !
---------------------

Make sure you have docker installed. On Ubuntu 14.04, Docker is named *docker.io*, replace the name by *docker* if you use another release.

If you just want to run a container with this image, you do not need this repository as the image is available on docker.io as a Trusted Build.
Just run the container and it will download the image if you do not already have it locally :

```sh
sudo docker.io run --rm -P --name pggis_test oslandia/pggis /sbin/my_init
```

Connect to the database
-----------------------

When you run the image to create a new container, a database is automatically created on startup, with all extensions activated. the database is named *pggis* and belongs to the *pggis* user, with *pggis* as a password.

Assuming you have the postgresql-client installed, you can use the host-mapped port to test as well. You need to use docker ps to find out what local host port the container is mapped to first:

```sh
$ sudo docker.io ps
CONTAINER ID        IMAGE                   COMMAND                CREATED             STATUS              PORTS                     NAMES
75fec271dc5e        oslandia/pggis:latest   /usr/lib/postgresql/   51 seconds ago      Up 50 seconds       0.0.0.0:49154->5432/tcp   pggis_test          
$ psql -h localhost -p 49154 -d pggis -U pggis --password
```

Automatically restore data
--------------------------

When the container runs, it first check its */data/restore* path for *sql* files and *backup* files.

If there is any backup file present, it will create a new database (named as the file basename), activate all extensions, and restore the backup database.

If there is any SQL file present, it will similarly create a new database, activate extensions, and load the SQL file into the created database.

To enable this, you have to map the exposed */data* volume to a host directory when running the image. You can do so using the *-v* option of *docker run*. This host directory should then have a *restore* subdirectory with the backups you want to restore.

Example follows, restoring two backups, one in custom format, another in SQL.

```sh
$ find /home/user/mydata/
/home/user/mydata/
/home/user/mydata/restore
/home/user/mydata/restore/restore_test.backup
/home/user/mydata/restore/restore_test2.sql
/home/user/mydata/otherstuff
...

$ docker run --rm -P --name pggis_test -v /home/user/mydata:/data oslandia/pggis /sbin/my_init

```

Now if you want to use this repository to build or modify the image, continue reading.

Build and/or run the container
------------------------------

Git clone this repository to get the Dockerfile, and cd to it.

You can build the image with :

```sh
sudo docker.io build -t oslandia/pggis .
```

Run the container with :

```sh
sudo docker.io run --rm -P --name pggis_test oslandia/pggis /sbin/my_init
```

Support
=======

Do not hesitate to fork, send pull requests or fill issues on GitHub to enhance this image.

Contact Oslandia at infos+pggis@oslandia.com for any question or support.


References
==========

More complete documentation on Oslandia's blog post : 
http://www.oslandia.com/full-spatial-database-power-in-2-lines-en.html

Dockerfile reference :
http://docs.docker.io/reference/builder/

PostgreSQL service example :
http://docs.docker.io/examples/postgresql_service/

