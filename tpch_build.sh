#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0.  If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright 2017-2018 MonetDB Solutions B.V.

# The path to the database farm
farm_path=

# The TPC-H scale factor
sf=
scale_factor=

# The daemon port
port=50000

# Should we actually run?
dry_run=

# Should we load the data?
generate_only=

# show commands as they are executed
verbose=

usage() {
    echo "Usage: $0 --sf <scale factor> --farm <farm path> [--port <port>] [--dry-run] [--generate-only]"
    echo "Generate and load TPC-H data to MonetDB"
    echo ""
    echo "Options:"
    echo "  -s, --sf <scale factor>                The scale factor for TPC-H data."
    echo "                                         Scale factor 1 is 1GB of data."
    echo "                                         Scale factor 0.1 is 100MB of data."
    echo "  -f, --farm <farm path>                 The absolute path to the MonetDB"
    echo "                                         data farm."
    echo "  -p, --port <port>                      The MonetDB daemon listen port"
    echo "                                         (default 50000)."
    echo "  -d, --dry-run                          Do not generate or load data,"
    echo "                                         just print the start up command."
    echo "  -g, --generate-only                    Only generate the data."
    echo "                                         Don't load it."
}

server_startup_command() {
    echo "Use the command"
    echo ""
    echo "  mserver5 --dbpath=$farm_path/SF-$scale_factor --set monet_vault_key=$farm_path/SF-$scale_factor/.vaultkey"
    echo ""
    echo "to start the server."
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        -s|--sf)
            if [ "$2" != "${2//[,]/}" ]; then
                echo -e "ERROR: invalid scale factor \"$2\". Use '.' as decimal separator instead\n"
                usage
                exit 1
            fi
            # keep the orginal value
            sf=$2
            # For scale factor smaller than 1, replace the '.' with '_' for the dbname
            scale_factor=${2//[.]/_}
            shift
            shift
            ;;
        -f|--farm)
            farm_path=${2%/}
            shift
            shift
            ;;
        -p|--port)
            port=$2
            shift
            shift
            ;;
	-d|--dry-run)
	    dry_run="true"
	    shift
	    ;;
	-g|--generate-only)
	    generate_only="true"
	    shift
	    ;;
	-v|--verbose)
	    verbose="true"
	    shift
	    ;;
	-h|--help)
	    usage
	    exit 0
	    ;;
        *)
            echo "$0: Unknown parameter $1"
            usage
            exit 1
            ;;
    esac
done

if [ -z "$scale_factor" ]; then
    usage
    exit 1
elif [ -z "$generate_only" -a -z "$farm_path" ]; then
    usage
    exit 1
fi

# Make sure the farm path given is absolute
if [ -z "$generate_only" -a "$farm_path" = "${farm_path#/}" ]; then
    usage
    exit 1
fi

if [ ! -z "$dry_run" ]; then
    server_startup_command
    exit 0
fi

if [ ! -z "$verbose" ]; then
    set -x
fi

# Find the root directory of the TPC-H scripts
if [ `uname` == "Darwin" ]
then
	root_directory=`python3 -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' $0`
else
	root_directory=$(readlink -f $0)
fi
root_directory=${root_directory%/*}
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
    ./dbgen -vf -s "$sf"

    mkdir -p "$root_directory/02_load/SF-$scale_factor/data"
    mv *.tbl "$root_directory/02_load/SF-$scale_factor/data"
    popd
fi

pushd 02_load

# We can stop now if we only want to generate the data
if [ ! -z "$generate_only" ]; then
    echo "Data set generated in $root_directory/02_load/SF-$scale_factor/data"
    exit 0
fi

# Create the database farm
if [ ! -e "$farm_path" ]; then
    monetdbd create "$farm_path"
fi

# Start the daemon
monetdbd set port="$port" "$farm_path"
monetdbd start "$farm_path"
# Load the data
./sf_build.sh SF-"$scale_factor" "$port"
if [ $? != 0 ]; then
    echo "Data not loaded correctly"
    # Stop the daemon
    monetdbd stop "$farm_path"
    exit 1
fi
# Stop the daemon
monetdbd stop "$farm_path"

echo "SF-$scale_factor loaded."
server_startup_command

# Go back to the original directory
popd
