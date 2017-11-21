#!/usr/bin/env bash

usage () {
    echo "usage: -farm <farm> -db <db>"
}

farm=
db=
while [ "$#" -gt 0 ]
do
    case "$1" in 
        farm|-farm|--farm)
            farm="$2"
            shift
            shift
            ;;
        db|-db|--db)
            db="$2"
            shift
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
    ./start_mserver.sh -farm "$farm" -db "$db" -nthreads "$threads"
    ./horizontal_run.sh "$db" 5 "$threads" # | tee -a results/result.csv
    kill -9 $(cat /tmp/mserver.pid)
    while mclient -d "$db" -s 'select 1' >& /dev/null; do sleep 1; done
done
