#!/usr/bin/env bash

threads=
mmap_threshold=
farm=
db=
start_stethoscope=false
dry_run=

while [ "$#" -gt 0 ]; do
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
        -n|--nthreads)
            threads="--set gdk_nr_threads=$2"
            shift
            shift
            ;;
        -m|--mmap_threshold)
            mmap_threshold="--set gdk_mmap_minsize_transient=$(echo $2 | bc)"
            shift
            shift
            ;;
        -s|--stethoscope)
            start_stethoscope=true
            shift
            ;;
        -e|--set)
            arg="--set $2"
            shift
            shift
            ;;
        -l|--logdir)
            logdir="$2"
            shift
            shift
            ;;
        -y|--dry)
            dry_run=echo
            shift
            ;;
        *)
            echo "$0: unknown option >$1<"
            exit 1
            ;;
    esac
done

if [ -z "$farm" -o -z "$db" ]; then
    echo "$0: --farm <dbfarm_path> --db <db_name> [--nthreads <number of threads>] [--mmap_threshold <size in bytes>] [--stethoscope]"
    exit 1
fi

vault_arg=
if [ -e "$farm/$db/.vaultkey" ]; then
    vault_arg="--set monet_vault_key=$farm/$db/.vaultkey"
fi

cmdstr="mserver5 --dbpath=$farm/$db $vault_arg --daemon=yes $arg"
if [ -z "$dry_run" ]; then
    ($cmdstr& echo $! > /tmp/mserver.pid)
    until mclient -d "$db" -s 'select 1' >& /dev/null; do sleep 1; done
else
    echo "$cmdstr"
fi
if [ -z "$logdir" ]; then
    logdir=/tmp
    if [ ! -d "$logdir" ]; then
        mkdir "$logdir"
    fi
fi
log_fn=$(echo "$cmdstr" | tr -s ' ' '_' | tr '/' '_')
log_fn="$log_fn"_$(date +%s)
cmdstr="stethoscope -d $db -j -o $logdir/$log_fn"
if [ -z "$dry_run" ]; then
    touch "$logdir/$log_fn"
    ($cmdstr& echo $! > /tmp/stethoscope.pid)
else
    echo "$cmdstr"
fi
