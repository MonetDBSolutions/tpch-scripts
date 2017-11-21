#!/usr/bin/env bash

TIMEFORMAT="%R"
monetdb stop $1
monetdb destroy $1 -f
monetdb create $1
monetdb release $1
date
time mclient -d $1 -ei tpch_schema.sql
date
if [ ! -e $1.load ]; then
  wc -l $PWD/$1/data/* | grep -v total | sort -n | awk -f copy_into.awk > $1.load
fi
time mclient -d $1 -ei $1.load
date
time mclient -d $1 -ei tpch_alter.sql
date
#cd;cd tpch; atlas $1
#cd;cd tpch; runqueries $1
