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
    echo "                                    run from others in the same results CSV. Default=timings"
    echo "  -m, --modifier <tag>              The SQL statement modifier {results,plan,trace,explain}"
    echo "  -p, --pipeline <pipeline>         The SQL query optimizer pipeline"
    echo "  -o, --output <directory>          The path to the output directory. Default=`pwd`/$modifier/$day_$dbname/timings.csv"
    echo "  -v, --verbose                     More output"
    echo "  -h, --help                        This message"
}

TIMEFORMAT="%R"
dbname=
nruns=1
tag="timings"
today=$(date +%Y-%m-%dT%H:%M:%S)
modifier=
pipeline=default_pipe
output=`pwd`


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
        -m|--modifier)
            modifier=$2
            shift
            shift
            ;;
        -p|--pipeline)
            pipeline=$2
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

if [ -z "${modifier}" ]; then
        bucket="results"
else
        bucket="${modifier}"
fi

optimizer="set optimizer='${pipeline}';"

dir=${bucket}/"${today}:${dbname}"
output="${output}/${bucket}/${today}:${dbname}/${tag}.csv"

mkdir -p "${dir}"

version=`mclient -d sf10 -version |grep version |sed -e "s/.*version//"`
echo "${version}" >>${dir}/version

echo "database,query,run,sqlparser,maloptimizer,run,clk" >${output}
for r in $(seq 1 $nruns)
do
    # iostat -t -m > /tmp/iostat
    ttl=0

    s=$(date +%s.%N)
    for q in $(ls ??.sql)
    do
        if [ $r == 1 ]; then
            echo "${optimizer} ${modifier}" > "/tmp/$q"
            cat "$q" >> "/tmp/$q"
        fi

        qn=`basename $q .sql`
        (mclient -d ${dbname} -f raw -w 120 -t performance  /tmp/$q) 2>${dir}/$qn.$r.time >${dir}/$qn.$r
        timer=`tail -2 ${dir}/$qn.$r.time| tr -d "\n" | sed -e "s/.*sql:/sql:/"| sed -e "s/sql://" -e "s/ opt:/,/" -e "s/ run:/,/" -e "s/clk:/,/" -e "s/ms//g" -e "s/ //g" `
        echo ${dbname}","${qn}","${r}","${timer}  | tee -a ${output}
    done
    x=$(date +%s.%N)
    sec=$(python -c "print($x - $s)")
    ttl1=$(python -c "print('%3.6f' % $sec)")
    echo "${dbname},all, $r, ${ttl1} seconds" | tee -a ${output}
done

# for trace experiments also collect the summary of spending time
if [ "$modifier" == "trace" ]
then
    echo "Prepare processing summary for all instructions"
    cd $dir
    x=`cat *.* | grep ' := ' | egrep -v ' := (user\.s[0-9]|language\.dataflow)' | awk 'BEGIN {s=0} {s+=$2} END {print s}'`
    for i in `cat * | grep ' := ' | egrep -v ' := (user\.s[0-9]|language\.dataflow)' | sed 's|^.* := \([^(]*\)(.*$|\1|' | sort -u`
    do
        c=`cat * | grep " := $i("|wc| sed -e "s/^ *//" -e "s/ .*//"`
        printf "%s   %8s calls %s\n" "`cat * | grep " := $i(" | awk 'BEGIN {s=0} {s+=$2} END {printf "%15d us   %9.6f %%\n",s,s/'"$x"'.0*100,$c}'`" $c,  $i ;
    done | sort -nr > summary
fi

# perform a comparison of the results with the previous one

prev=`ls -t ${bucket}/ | head -2 |tail -1`
last=`ls -t ${bucket}/ | head -1`
rm ${bucket}/last
ln -s ${last} ${bucket}/last

if [ "${bucket}" == "results" ]
then
    echo "Prepare a single comparison scan ${prev} and ${last}"
    for q in $(ls ??.sql)
    do
        qn=`basename $q .sql`
        if [  -e "results/${last}/${qn}.1"  -a -e "results/${prev}/${qn}.1" ]
        then
            diff results/${last}/${qn}.1 results/${prev}/${qn}.1 |tee results/last/diffs
        fi
    done
fi
