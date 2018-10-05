#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

DB="${1:?Database name not set}"
DIR="${2:?Directory not set}"
LOAD="load-$DB.mysql"

run_file() { 
	mysql "$DB" < "$1"
}

set -x

cd "$(dirname "$0")"

if [ ! -e "$LOAD" ]; then
	ls -rS $PWD/$DIR/data/*.tbl | awk -f load_data.awk > "$LOAD".tmp
	mv "$LOAD".tmp "$LOAD"
fi

mysql -e "drop database if exists $DB"
mysql -e "create database $DB"
# 
run_file tpch_schema.sql
run_file q15_view.sql
run_file "$LOAD"
run_file mysql_alter.sql
run_file pg_idx.sql
