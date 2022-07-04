#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0.  If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright 2017-2018 MonetDB Solutions B.V.

usage() {
    echo "Usage: $0 --db <db> [--number <repeats>] "
    echo "Run the TPC-H queries in parallel with n clients and report timings."
    echo ""
    echo "Options:"
    echo "  -d, --db <db>                     The database"
    echo "  -v, --verbose                     More output"
    echo "  -p, --port <port>                 Port number where the server is listening"
    echo "  -n, --number <repeats>            How many streams (mclients) in paralellel run the queries. Default=1"
    echo "  -h, --help                        This message"
}

dbname=
nruns=1
port=50000
tag="default"
output="timings.csv"
pipeline="default_pipe"

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
        -p|--port)
            port=$2
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

optimizer="set optimizer='$pipeline';"
TIMEFORMAT="%R"

for i in $(ls ??.sql)
do
    echo "$optimizer" > "/tmp/$i"
    cat "$i" >> "/tmp/$i"
done

# Order for the first 7 tpch streams (SF1000 must have 7 streams)
declare -a order=("21.sql 03.sql 18.sql 05.sql 11.sql 07.sql 06.sql 20.sql 17.sql 12.sql 16.sql 15.sql 13.sql 10.sql 02.sql 08.sql 14.sql 19.sql 09.sql 22.sql 01.sql 04.sql" "06.sql 17.sql 14.sql 16.sql 19.sql 10.sql 09.sql 02.sql 15.sql 08.sql 05.sql 22.sql 12.sql 07.sql 13.sql 18.sql 01.sql 04.sql 20.sql 03.sql 11.sql 21.sql" "08.sql 05.sql 04.sql 06.sql 17.sql 07.sql 01.sql 18.sql 22.sql 14.sql 09.sql 10.sql 15.sql 11.sql 20.sql 02.sql 21.sql 19.sql 13.sql 16.sql 12.sql 03.sql" "05.sql 21.sql 14.sql 19.sql 15.sql 17.sql 12.sql 06.sql 04.sql 09.sql 08.sql 16.sql 11.sql 02.sql 10.sql 18.sql 01.sql 13.sql 07.sql 22.sql 03.sql 20.sql" "21.sql 15.sql 04.sql 06.sql 07.sql 16.sql 19.sql 18.sql 14.sql 22.sql 11.sql 13.sql 03.sql 01.sql 02.sql 05.sql 08.sql 20.sql 12.sql 17.sql 10.sql 09.sql" "10.sql 03.sql 15.sql 13.sql 06.sql 08.sql 09.sql 07.sql 04.sql 11.sql 22.sql 18.sql 12.sql 01.sql 05.sql 16.sql 02.sql 14.sql 19.sql 20.sql 17.sql 21.sql" "18.sql 08.sql 20.sql 21.sql 02.sql 04.sql 22.sql 17.sql 01.sql 11.sql 09.sql 19.sql 03.sql 13.sql 05.sql 07.sql 10.sql 16.sql 06.sql 14.sql 15.sql 12.sql")

echo "Starting TPCH throughput execution of $nruns streams"
xs=$(date +%s.%N)

for (( i=0; i<nruns; ++i)); do
    echo $i
    ./tpch_ordered_run.sh -d $dbname -t S$i -p $port -o "${order[$i]}" &
    #pids[${i}]=$!
done

FAIL=0

for job in `jobs -p`
do
echo $job
    wait $job || let "FAIL+=1"
done

echo $FAIL

if [ "$FAIL" == "0" ];
then
    xx=$(date +%s.%)
    elapsed=$(echo "scale=4; $xx - $xs" | bc)
    echo "All streams finished successfully! Ts=$elapsed"
else
    echo "There were issues in the experiments ($FAIL clients)"
fi
