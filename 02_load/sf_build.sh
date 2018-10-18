#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0.  If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright 2017-2018 MonetDB Solutions B.V.

TIMEFORMAT="%R"
if [ -z "$2" ]; then
  port=50000
else
  port="$2"
fi
monetdb -p "$port" stop "$1"
monetdb -p "$port" destroy "$1" -f
monetdb -p "$port" create "$1"
monetdb -p "$port" release "$1"
date
time mclient -d "$1" -ei tpch_schema.sql
date
if [ ! -e $1.load ]; then
  wc -l $PWD/$1/data/* | grep -v total | sort -n | awk -f copy_into.awk > $1.load
fi
time mclient -d "$1" -p "$port" -ei $1.load
date
time mclient -d "$1" -p "$port" -ei tpch_alter.sql
date
#cd;cd tpch; atlas $1
#cd;cd tpch; runqueries $1
