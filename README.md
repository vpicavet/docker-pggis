A PG GIS setup for Docker
=========================

Presentation
------------

This Docker image is a container with all latest PostgreSQL extensions needed to do serious GIS work.
It is based on Ubuntu 14.04 and features :

* PostgreSQL 9.3 (from package)
* PDAL (git master)
* PostgreSQL PointCloud extension (git master)
* PostGIS 2.1.2 (compiled from release sources) with SFCGAL support (git master)

It creates a pggis database with a pggis superuser, with postgis and pointcloud extensions activated. It is therefore ready to eat data, and you can enjoy 2D vector and raster features, 3D support and functions, large point data volumes and analysis, topology support and all PostgreSQL native features.

Build and/or run the container
------------------------------

Git clone this repository to get the Dockerfile, and cd to it.

You can build the image with :

```sh
sudo docker.io build -t oslandia/pggis .
```

Run the container with :

```sh
sudo docker.io run --rm -P --name pggis_test oslandia/pggis
```

Connect to the database
-----------------------

Assuming you have the postgresql-client installed, you can use the host-mapped port to test as well. You need to use docker ps to find out what local host port the container is mapped to first:

```sh
$ docker.io ps
CONTAINER ID        IMAGE                   COMMAND                CREATED             STATUS              PORTS                     NAMES
75fec271dc5e        oslandia/pggis:latest   /usr/lib/postgresql/   51 seconds ago      Up 50 seconds       0.0.0.0:49154->5432/tcp   pggis_test          
$ psql -h localhost -p 49154 -d pggis -U pggis --password
```

References
==========

Dockerfile reference :
http://docs.docker.io/reference/builder/

PostgreSQL service example :
http://docs.docker.io/examples/postgresql_service/

