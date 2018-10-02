#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

DB="${1:?Scale Factor not set}"
LOAD="load-$DB.pgsql"

run_file() { 
	psql \
		-P format=unaligned -P pager=off -v ON_ERROR_STOP=1 \
		-d "$DB" -f "$1"
}

set -x

cd "$(dirname "$0")"

if [ ! -e "$LOAD" ]; then
	wc -l $PWD/$1/data/* | grep -v total | sort -n | awk -f copy_from.awk > "$LOAD".tmp
	mv "$LOAD".tmp "$LOAD"
fi

dropdb "$DB" || true
createdb "$DB"

run_file tpch_schema.sql
run_file "$LOAD"
run_file tpch_alter.sql
run_file pg_idx.sql
