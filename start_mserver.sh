#!/usr/bin/env bash

threads=
mmap_threshold=
farm=
db=
kill_previous=false

while [ "$#" -gt 0 ]; do
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
        nthreads|-nthreads|--nthreads)
            threads="--set gdk_nr_threads=$2"
            shift
            shift
            ;;
        mmap_threshold|-mmap_threshold|--mmap_threshold)
            mmap_threshold="--set gdk_mmap_minsize_transient=$(echo $2 | bc)"
            shift
            shift
            ;;
        kill|-kill|--kill)
            kill_previous=true
            shift
            ;;
        *)
            echo "$0: unknown option $1"
            exit 1
            ;;
    esac
done

if [ "$kill_previous" == "true" ]; then
    echo "killing mserver"
    kill $(cat /tmp/mserver5.pid)
    exit 0
fi

if [ -z "$farm" -o -z "$db" ]; then
    echo "$0: -farm <dbfarm_path> -db <db_name> [-nthreads <number of threads> -mmap_threshold <size in bytes>]"
    exit 1
fi


cmdstr="mserver5 --dbpath=$farm/$db --set monet_vault_key=$farm/$db/.vaultkey --set max_clients=64 --set sql_optimizer=default_pipe --daemon=yes $threads $mmap_threshold"
($cmdstr& echo $! > /tmp/mserver.pid)
until mclient -d "$db" -s 'select 1' >& /dev/null; do sleep 1; done
