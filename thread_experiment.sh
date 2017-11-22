#!/usr/bin/env bash

usage () {
    echo "usage: -farm <farm> -db <db>"
}

farm=
db=
while [ "$#" -gt 0 ]
do
    case "$1" in
        -f|--farm)
            farm="$2"
            shift
            shift
            ;;
        -d|--db)
            db="$2"
            shift
            shift
            ;;
        -s|--stethoscope)
            stethoscope="-s"
            shift
            ;;
        *)
            echo "$0: unknown argument $1"
            exit 1
            ;;
    esac
done

for threads in $(seq 1 96)
do
    ./start_mserver.sh -f "$farm" -d "$db" -n "$threads" "$stethoscope"
    ./horizontal_run.sh "$db" 5 "$threads" # | tee -a results/result.csv
    kill $(cat /tmp/stethoscope.pid)
    kill $(cat /tmp/mserver.pid)
    while mclient -d "$db" -s 'select 1' >& /dev/null; do sleep 1; done
done
