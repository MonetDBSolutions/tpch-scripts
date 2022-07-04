#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0.  If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright 2017-2018 MonetDB Solutions B.V.

usage() {
    echo "Usage: $0 --db <db> --plan <query-order> [--tag <tag>] "
    echo "Run the TPC-H queries a number of times and report timings."
    echo ""
    echo "Options:"
    echo "  -d, --db <db>                     The database"
    echo "  -t, --tag <tag>                   An arbitrary string to distinguish this"
    echo "                                    run from others in the same results CSV."
    echo "  -o, --order <plan>                 Execution order of queries"
    echo "  -p, --port <port>                 Port number where the server is listening"
    echo "  -v, --verbose                     More output"
    echo "  -h, --help                        This message"
}

dbname=
tag="default"

while [ "$#" -gt 0 ]
do  
    case "$1" in
        -d|--db)
            dbname=$2
            shift
            shift
            ;;
        -t|--tag)
            tag=$2
            shift
            shift
            ;;
        -p|--port)
            port=$2
            shift
            shift
            ;;
        -o|--order)
            plan=$2
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


output="$tag.$dbname.timings.csv"

echo "# Database,Query,Min,Max,Average" | tee -a "$output"

for q in $plan
do  

    s=$(date +%s.%N)
    mclient -d "$dbname" -f raw -p "$port" -w 80 -i < "/tmp/$q" 2>&1 >/dev/null
    x=$(date +%s.%N)
    elapsed=$(echo "scale=4; $x - $s" | bc)
    echo "$dbname,$tag,"$(basename $q .sql)",$elapsed" | tee -a "$output"

done

