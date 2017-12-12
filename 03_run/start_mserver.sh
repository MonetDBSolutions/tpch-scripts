#!/usr/bin/env bash

usage () {
    echo "Usage: $0 --farm <path> --db <db> [--set arg=value] [--stethoscope] [--logdir <path>] [-dry] [--verbose] [--help]"
    echo "Start the mserver with specific argumnents. Mainly useful for scripting."
    echo ""
    echo "  -f, --farm <farm>                 The path to the db farm"
    echo "  -d, --db <db>                     The database"
    echo "  -e, --set <arg=value>             Start the mserver with the argument <arg>"
    echo "                                    having value <val>"
    echo "  -s, --stethoscope                 Save the stethoscope output"
    echo "  -l, --logdir <path>               The directory to save stethoscope logs"
    echo "  -y, --dry                         Don't start the server, just print the command"
    echo "  -v, --verbose                     More output"
    echo "  -h, --help                        This message"
}

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
            echo "$0: unknown option >$1<"
            usage
            exit 1
            ;;
    esac
done

if [ -z "$farm" -o -z "$db" ]; then
    usage
    exit 2
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
