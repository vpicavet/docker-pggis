# PostgreSQL GIS stack
#
# This image includes the following tools
# - PostgreSQL 11
# - PostGIS 2.5.2 with raster, topology and sfcgal support
# - OGR Foreign Data Wrapper
# - PgRouting
# - PDAL 1.9.1
# - PostgreSQL PointCloud version master
#
# Version 1.8

FROM phusion/baseimage:0.11
MAINTAINER Vincent Picavet, vincent.picavet@oslandia.com

# Set correct environment variables.
ENV HOME /root

# Regenerate SSH host keys. baseimage-docker does not contain any, so you
# have to do that yourself. You may also comment out this instruction; the
# init system will auto-generate one during boot.
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]


RUN apt-get update && apt-get install -y wget ca-certificates sudo

# Use APT postgresql repositories for 11 version
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" > /etc/apt/sources.list.d/pgdg.list && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# packages needed for compilation
RUN apt-get update

RUN apt-get install -y autoconf build-essential cmake docbook-mathml docbook-xsl libboost-dev libboost-thread-dev libboost-filesystem-dev libboost-system-dev libboost-iostreams-dev libboost-program-options-dev libboost-timer-dev libcunit1-dev libgdal-dev libgeos++-dev libgeotiff-dev libgmp-dev libjson-c-dev liblas-dev libmpfr-dev libopenscenegraph-dev libpq-dev libproj-dev libxml2-dev postgresql-server-dev-11 xsltproc git build-essential wget libzstd-dev

# application packages
RUN apt-get install -y postgresql-11

# Download and compile CGAL
RUN wget https://github.com/CGAL/cgal/releases/download/releases%2FCGAL-4.13.1/CGAL-4.13.1.tar.xz &&\
    tar -xf CGAL-4.13.1.tar.xz &&\
    cd CGAL-4.13.1 &&\
    mkdir build && cd build &&\
    cmake .. &&\
    make -j3 && make install
# cleanup
RUN rm -Rf CGAL-4.13.1.tar.xz CGAL-4.13.1

# download and compile SFCGAL
RUN git clone https://github.com/Oslandia/SFCGAL.git
RUN cd SFCGAL && cmake . && make -j3 && make install
# cleanup
RUN rm -Rf SFCGAL

# Download and compile PostGIS
RUN wget http://download.osgeo.org/postgis/source/postgis-2.5.2.tar.gz
RUN tar -xzf postgis-2.5.2.tar.gz
RUN cd postgis-2.5.2 && ./configure --with-sfcgal=/usr/local/bin/sfcgal-config
RUN cd postgis-2.5.2 && make && make install
# cleanup
RUN rm -Rf postgis-2.5.2.tar.gz postgis-2.5.2

# Download and compile pgrouting
RUN git clone https://github.com/pgRouting/pgrouting.git &&\
    cd pgrouting &&\
    mkdir build && cd build &&\
    cmake -DWITH_DOC=OFF -DWITH_DD=ON .. &&\
    make -j3 && make install
# cleanup
RUN rm -Rf pgrouting

# Download and compile ogr_fdw
RUN git clone https://github.com/pramsey/pgsql-ogr-fdw.git &&\
    cd pgsql-ogr-fdw &&\
    make && make install &&\
    cd .. && rm -Rf pgsql-ogr-fdw

# Compile PDAL
RUN git clone https://github.com/PDAL/PDAL.git pdal && \
    cd pdal && \
    git checkout 1.9.1
RUN mkdir PDAL-build && \
    cd PDAL-build && \
    cmake ../pdal && \
    make -j3 && \
    make install
# cleanup
RUN rm -Rf pdal && rm -Rf PDAL-build

# Compile PointCloud
RUN git clone https://github.com/pramsey/pointcloud.git
RUN cd pointcloud && ./autogen.sh && ./configure && make -j3 && make install
# cleanup
RUN rm -Rf pointcloud

# get compiled libraries recognized
RUN ldconfig

# clean packages

# all -dev packages
RUN apt-get remove -y --purge autotools-dev libgeos-dev libgif-dev libgl1-mesa-dev libglu1-mesa-dev libgnutls-dev libgpg-error-dev libhdf4-alt-dev libhdf5-dev libicu-dev libidn11-dev libjbig-dev libjpeg8-dev libjpeg-dev libjpeg-turbo8-dev libkrb5-dev libldap2-dev libltdl-dev liblzma-dev libmysqlclient-dev libnetcdf-dev libopenthreads-dev libp11-kit-dev libpng12-dev libpthread-stubs0-dev librtmp-dev libspatialite-dev libsqlite3-dev libssl-dev libstdc++-4.8-dev libtasn1-6-dev libtiff5-dev libwebp-dev libx11-dev libx11-xcb-dev libxau-dev libxcb1-dev libxcb-dri2-0-dev libxcb-dri3-dev libxcb-glx0-dev libxcb-present-dev libxcb-randr0-dev libxcb-render0-dev libxcb-shape0-dev libxcb-sync-dev libxcb-xfixes0-dev libxdamage-dev libxdmcp-dev libxerces-c-dev libxext-dev libxfixes-dev libxshmfence-dev libxxf86vm-dev linux-libc-dev manpages-dev mesa-common-dev libgcrypt11-dev unixodbc-dev uuid-dev x11proto-core-dev x11proto-damage-dev x11proto-dri2-dev x11proto-fixes-dev x11proto-gl-dev x11proto-input-dev x11proto-kb-dev x11proto-xext-dev x11proto-xf86vidmode-dev xtrans-dev zlib1g-dev libzstd-dev

# installed packages
RUN apt-get remove -y --purge autoconf build-essential cmake docbook-mathml docbook-xsl libboost-dev libboost-filesystem-dev libboost-timer-dev libcgal-dev libcunit1-dev libgdal-dev libgeos++-dev libgeotiff-dev libgmp-dev libjson-c-dev liblas-dev libmpfr-dev libopenscenegraph-dev libpq-dev libproj-dev libxml2-dev postgresql-server-dev-9.5 xsltproc git build-essential wget 

# additional compilation packages
RUN apt-get remove -y --purge automake m4 make

# ---------- SETUP --------------

# add a baseimage PostgreSQL init script
RUN mkdir /etc/service/postgresql
ADD postgresql.sh /etc/service/postgresql/run

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible. 
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/11/main/pg_hba.conf

# And add ``listen_addresses`` to ``/etc/postgresql/9.5/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/11/main/postgresql.conf

# Expose PostgreSQL
EXPOSE 5432

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/data", "/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

# add database setup upon image start
ADD pgpass /root/.pgpass
RUN chmod 700 /root/.pgpass
RUN mkdir -p /etc/my_init.d
ADD init_db_script.sh /etc/my_init.d/init_db_script.sh
ADD init_db.sh /root/init_db.sh

# ---------- Final cleanup --------------
#
# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

