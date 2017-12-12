#!/usr/bin/env bash

usage () {
    echo "Usage: $0 --farm <farm> --db <db> [--number <repeats>] [--arg <mserver arg> --range <min>:<max>[:<step>] --function <python 3 expression>] [--stethoscope] [--logdir <directory>] [--onlystart]"
    echo "Start mserver with different arguments and run TPC-H"
    echo ""
    echo "  -f, --farm <farm>                 The path to the db farm"
    echo "  -d, --db <db>                     The database"
    echo "  -n, --number <repeats>            How many times to run the queries. Default=5"
    echo "  -a, --arg <mserver arg>           The mserver argument"
    echo "  -r, --range <min>:<max>:[step]    The range of the values for 'arg'"
    echo "  -f, --funtion <exp>               A transformation for the current value."
    echo "                                    It must be a valid python 3 expression,"
    echo "                                    The text '\\\$r' will be subsituted for"
    echo "                                    the current value."
    echo "  -s, --stethoscope                 Save the stethoscope output"
    echo "  -l, --logdir <path>               The directory to save stethoscope logs"
    echo "  -o, --onlystart                   Only start the server, don't run TPC-H"
    echo "  -v, --verbose                     More output"
    echo "  -h, --help                        This message"
}

farm=
db=
onlystart=false
nruns=5
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
        -n|--number)
            nruns=$2
            shift
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
        -v|--verbose)
            set -x
            set -v
            shift
            ;;
        -o|--onlystart)
            onlystart=true
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

if [ -z "$farm" -o -z "$db" ]
then
    usage
    exit 1
fi

min=$(echo "$range" | awk -F: '{print $1}')
max=$(echo "$range" | awk -F: '{print $2}')
step=$(echo "$range" | awk -F: '{print $3}')

if [ -z "$min" -o -z "$max" ];
then
    echo "Range argument incorrect. Should be of the form <min>:<max>"
    usage
    exit 1
fi

for r in $(seq ${min} ${step} ${max})
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
    if ! $onlystart; then
        ./horizontal_run.sh -d "$db" -n "$nruns" -t "$argument"
    fi
    sleep 3
    kill $(cat /tmp/stethoscope.pid)
    kill $(cat /tmp/mserver.pid)
    while mclient -d "$db" -s 'select 1' >& /dev/null; do sleep 1; done
done
