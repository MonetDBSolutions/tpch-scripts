#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0.  If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright 2017-2018 MonetDB Solutions B.V.

# The path to the database farm
farm_path=

# The TPC-H scale factor
scale_factor=

usage() {
    echo "Usage: $0 --sf <scale factor> --farm <farm path> [--port <port>]"
    echo "scale factor 1 is 1GB database"
    echo "farm path should be an absolute path"
}

port=50000
while [ "$#" -gt 0 ]; do
    case "$1" in
        -s|--sf)
            scale_factor=$2
            shift
            shift
            ;;
        -f|--farm)
            farm_path=$2
            shift
            shift
            ;;
        -p|--port)
            port=$2
            shift
            shift
            ;;
        *)
            echo "$0: Unknown parameter $1"
            usage
            exit 1
            ;;
    esac
done

if [ -z "$scale_factor" -o -z "$farm_path" ]; then
    usage
    exit 1
fi

# Make sure the farm path given is absolute
if [ "$farm_path" = "${farm_path#/}" ]; then
    usage
    exit 1
fi

# Find the root directory of the TPC-H scripts
root_directory=$(readlink -f $0)
root_directory=${root_directory%${0:1}}
echo "Root directory = $root_directory"

# Go to the scripts root directory
pushd $root_directory

# Add dot monetdb file for permissions
test -f $HOME/.monetdb || cat << EOF > $HOME/.monetdb
user=monetdb
password=monetdb
save_history=true
EOF

# Generate the data if the following directory does not exist.
# TODO: Add a condition about the actual files we need.
if [ ! -e "$root_directory/02_load/SF-$scale_factor/data" ]; then
    pushd 01_build/dbgen
    make
    # Create the data for the scale factor
    ./dbgen -vf -s "$scale_factor"

    mkdir -p "$root_directory/02_load/SF-$scale_factor/data"
    mv *.tbl "$root_directory/02_load/SF-$scale_factor/data"
    popd
fi

pushd 02_load

# Create the database farm
if [ ! -e "$farm_path" ]; then
    monetdbd create "$farm_path"
fi

# Start the daemon
monetdb set port="$port" "$farm_path"
monetdbd start "$farm_path"
# Load the data
./sf_build.sh SF-"$scale_factor" "$port"
# Stop the daemon
monetdbd stop "$farm_path"

echo "SF-$scale_factor loaded. Use"
echo "mserver5 --dbpath=$farm_path/SF-$scale_factor --set monet_vault_key=$farm_path/SF-$scale_factor/.vaultkey"
echo "to start the server."

# Go back to the original directory
popd
