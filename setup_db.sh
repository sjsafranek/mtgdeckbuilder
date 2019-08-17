#!/bin/bash

sudo -u postgres psql -c "DROP DATABASE mtgdb;"

sudo -u postgres psql -c "CREATE USER mtguser WITH PASSWORD 'dev';"
sudo -u postgres psql -c "CREATE DATABASE mtgdb;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE mtgdb to mtguser;"
sudo -u postgres psql -c "ALTER USER mtguser WITH SUPERUSER;"

PGPASSWORD=dev psql -d mtgdb -U mtguser -f database.sql
