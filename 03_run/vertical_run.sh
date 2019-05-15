#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0.  If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright 2017-2018 MonetDB Solutions B.V.

usage() {
    echo "Usage: $0 --db <db> [--number <repeats>] [--tag <tag>] [--output <file>]"
    echo "Run the TPC-H queries a number of times and report timings."
    echo ""
    echo "Options:"
    echo "  -d, --db <db>                     The database"
    echo "  -n, --number <repeats>            How many times to run the queries. Default=1"
    echo "  -t, --tag <tag>                   An arbitrary string to distinguish this"
    echo "                                    run from others in the same results CSV."
    echo "  -o, --output <file>               Where to append the output. Default=timings.csv"
    echo "  -v, --verbose                     More output"
    echo "  -h, --help                        This message"
}

dbname=
nruns=1
tag="default"
output="timings.csv"

while [ "$#" -gt 0 ]
do
    case "$1" in
        -d|--db)
            dbname=$2
            shift
            shift
            ;;
        -n|--number)
            nruns=$2
            shift
            shift
            ;;
        -t|--tag)
            tag=$2
            shift
            shift
            ;;
        -o|--output)
            output=$2
            shift
            shift
            ;;
        -v|--verbose)
            set -x
            set -v
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "$0: unknown argument $1"
            usage
            exit 1
            ;;
    esac
done

if [ -z "$dbname" ]; then
    usage
    exit 1
fi

optimizer="set optimizer='default_pipe';"
TIMEFORMAT="%R"

today=$(date +%Y-%m-%d)
dir=results/"$today_$dbname_$tag"
mkdir -p "$dir"

# echo "# Database,Tag,Run#,Total" >> "$output"
for r in $(seq 1 $nruns)
do
    # iostat -t -m > /tmp/iostat
    ttl=0

    for q in $(ls ??.sql)
    do
	if [ $r == 1 ]; then
            echo "$optimizer" > "/tmp/$q"
            cat "$q" >> "/tmp/$q"
        fi

        s=$(date +%s.%N)
        mclient -d "$dbname" -f raw -w 80 -i < "/tmp/$q" 2>&1 >/dev/null
        x=$(date +%s.%N)
        sec=$(python -c "print($x - $s)")
        ttl=$(python -c "print($ttl + $sec)")
    done
    echo "Stats per run:"
    echo "$dbname,$tag, run #$r,$ttl" | tee -a "$output"
done


