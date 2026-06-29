#!/usr/bin/env bash

# To be run in pg_container.... ./dockerbash
# try either.... depending on apline or deb image
echo "#### Ignore update errors, trying both apk and apt-get"
apk upgrade --no-cache
apt-get -yq update
apt-get -yq upgrade


DB_NAME="xnat"
TABLES_TO_SKIP="()" # do not skip any, as delete orphan rows - 'xdat_change_info', 'wrk_workflowdata_meta_data')"


# Query all tables, filter out the skipped ones, and run reindexdb for each
echo "Reindexing database..."
psql -U xnat -d "$DB_NAME" -Atc "SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename NOT IN $TABLES_TO_SKIP" | while read TABLE; do
  #
  reindexdb  -U xnat   --concurrently  -t "$TABLE" "$DB_NAME"
done

echo "Vacuuming database..."
psql -U xnat -d "$DB_NAME" -Atc "VACUUM analyze;"