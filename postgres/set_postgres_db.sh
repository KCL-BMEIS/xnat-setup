#!/usr/bin/env bash

linux_dir=$(dirname "$0")
cd $linux_dir
cd ..
install_dir=$(pwd)
if [ ! -f "$install_dir/xnat.cfg" ]
then
        echo "Error: Cannot find xnat.cfg file"
        exit 1
fi
sed -i "s/ //g"  $install_dir/xnat.cfg
dos2unix $install_dir/xnat.cfg
source $install_dir/xnat.cfg

PG=$(docker ps | egrep xnat-db | cut -c1-12)


sudo docker exec -it "$PG" psql -U xnat -c  "ALTER SYSTEM SET listen_addresses='*';"
# redundent - standard conforming strings no longer used.
# sudo docker exec -it "$PG" psql -U xnat -c  "ALTER SYSTEM SET standard_conforming_strings = 'off';"


sudo docker exec -it "$PG" psql -U xnat -c  "ALTER SYSTEM SET max_connections = $max_connections"
sudo docker exec -it "$PG" psql -U xnat -c  "ALTER SYSTEM SET shared_buffers = '$shared_buffers'"
sudo docker exec -it "$PG" psql -U xnat -c  "ALTER SYSTEM SET effective_cache_size = '$effective_cache_size'"
sudo docker exec -it "$PG" psql -U xnat -c  "ALTER SYSTEM SET maintenance_work_mem ='$maintenance_work_mem'"
sudo docker exec -it "$PG" psql -U xnat -c  "ALTER SYSTEM SET checkpoint_completion_target = $checkpoint_completion_target"
sudo docker exec -it "$PG" psql -U xnat -c  "ALTER SYSTEM SET wal_buffers = '$wal_buffers'"
sudo docker exec -it "$PG" psql -U xnat -c  "ALTER SYSTEM SET default_statistics_target = $default_statistics_target"
sudo docker exec -it "$PG" psql -U xnat -c  "ALTER SYSTEM SET random_page_cost = $random_page_cost"
sudo docker exec -it "$PG" psql -U xnat -c  "ALTER SYSTEM SET effective_io_concurrency = $effective_io_concurrency"
sudo docker exec -it "$PG" psql -U xnat -c  "ALTER SYSTEM SET work_mem = '$work_mem'"
sudo docker exec -it "$PG" psql -U xnat -c  "ALTER SYSTEM SET min_wal_size = '$min_wal_size'"
sudo docker exec -it "$PG" psql -U xnat -c  "ALTER SYSTEM SET max_wal_size = '$max_wal_size'"
sudo docker exec -it "$PG" psql -U xnat -c  "ALTER SYSTEM SET max_worker_processes = $max_worker_processes"
sudo docker exec -it "$PG" psql -U xnat -c  "ALTER SYSTEM SET max_parallel_workers_per_gather = $max_parallel_workers_per_gather"
sudo docker exec -it "$PG" psql -U xnat -c  "ALTER SYSTEM SET max_parallel_workers = $max_parallel_workers"
sudo docker exec -it "$PG" psql -U xnat -c  "ALTER SYSTEM SET max_parallel_maintenance_workers = $max_parallel_maintenance_workers"
# Do NOT set huge pages on on Linux systems
sudo docker exec -it "$PG" psql -U xnat -c  "ALTER SYSTEM SET huge_pages = $huge_pages"


docker commit "$PG"  postgres-xnat