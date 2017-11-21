#!/usr/bin/env bash

usage() {
    echo "usage: $0 database repeats [version] [output]"
    exit 1
}

if [ "x$1" == "x" ]
then
    usage
fi

if [ "x$2" == "x" ]
then
    usage
fi

if [ -z "$3" ]
then
    version="default"
else
    version="$3"
fi

dbname=$1
nruns=$2
optimizer="set optimizer='default_pipe';"
TIMEFORMAT="%R"

today=$(date +%Y-%m-%d)
dir=results/"$today_$dbname_$version"
mkdir -p "$dir"

if [ -z "$4" ]
then
    output=0
else
    output=1
fi

set +x

for i in $(ls ??.sql)
do
    echo "$optimizer" > "/tmp/$i"
    cat "$i" >> "/tmp/$i"
    # for j in $(seq 1 3)
    # do
        # mclient -d "$dbname" -f raw -w 80 -i < "/tmp/$i" 2>&1 >/dev/null
    # done
    # echo "# Warmup done"

    iostat -t -m > /tmp/iostat
    total=0

    for j in $(seq 1 $nruns)
    do
        s=$(date +%s.%N)
        mclient -d "$dbname" -f raw -w 80 -i < "/tmp/$i" 2>&1 >/dev/null
        x=$(date +%s.%N)
        sec=$(python -c "print($x - $s)")
        total=$(python -c "print($total + $sec)")
        if [ $j == 1 ]; then
            mn=$sec
            mx=$sec
        else
            mn=$(python -c "print(min($mn, $sec))")
            mx=$(python -c "print(max($mn, $sec))")
        fi
    done
    total=$(python -c "print($total/$nruns)")
    iostat -t -m >> /tmp/iostat
    io=$(awk -f sumio.awk /tmp/iostat)

    echo "$dbname,$version,"$(basename $i .sql)",$mn,$io" | tee -a results/result.csv
done
