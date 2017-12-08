#!/usr/bin/env bash

usage () {
    echo "usage: $0 --farm <farm> --db <db> [--arg <mserver arg> --range <min>:<max> --function <python 3 expression>] [--stethoscope] [--logdir <directory>]"
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
        -r|--range)
            range="$2"
            shift
            shift
            ;;
        -f|--function)
            fn="$2"
            shift
            shift
            ;;
        -a|--arg)
            ar="$2"
            shift
            shift
            ;;
        -l|--logdir)
            logdir="-l $2"
            shift
            shift
            ;;
        *)
            echo "$0: unknown argument $1"
            exit 1
            ;;
    esac
done

if [ -z "$farm" -o -z "$db" ]
then
    usage
    exit 1
fi

min=$(echo "$range" | awk -F: '{print $1}')
max=$(echo "$range" | awk -F: '{print $2}')

if [ -z "$min" -o -z "$max" ];
then
    echo "Range argument incorrect. Should be of the form <min>:<max>"
    usage
    exit 1
fi

rng="seq ${min} ${max}"

for r in $($rng);
do
    eval "ff=${fn}"
    arg_val=$(python3 -c "print('{}'.format($ff))")
    if [ -z "$arg_val" ];
    then
        argument=
    else
        argument="$ar=$arg_val"
    fi
    ./start_mserver.sh "-f" "$farm" "-d" "$db" "--set" "$argument" $stethoscope $logdir
    ./horizontal_run.sh "$db" 5 "$argument"
    sleep 3
    kill $(cat /tmp/stethoscope.pid)
    kill $(cat /tmp/mserver.pid)
    while mclient -d "$db" -s 'select 1' >& /dev/null; do sleep 1; done
done
