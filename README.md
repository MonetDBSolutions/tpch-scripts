# TPC-H scripts for MonetDB

This is a set of programs that can be used to generate TPC-H test data
and load it to MonetDB.

A copy of `dbgen`, the TPC's data generation utility for TPC-H is
included in this repository as allowed for in clause 9 of its
[End-User License Agreement
(EULA)](http://www.tpc.org/tpc_documents_current_versions/source/tpc_eula.txt). It
also available without charge from the TPC,
[here](http://www.tpc.org/TPC_Documents_Current_Versions/download_programs/tools-download-request.asp?bm_type=TPC-H&bm_vers=2.17.1&mode=CURRENT-ONLY)

## Working with MonetDB and TPC-H

### Downloading and installing MonetDB

Having the source code (either from the [mercurial
repository](https://dev.monetdb.org/hg/MonetDB), the [gihtub
mirror](https://github.com/MonetDB/MonetDB) or from an [uncompressed
tarball](https://www.monetdb.org/downloads/sources/Latest)), the way
to compile is pretty standard for a UNIX package:

    $ cd /path/to/source
    $ ./bootstrap
    $ mkdir build
    $ cd build
    $ ../configure [options]
    $ make -j
    $ make install

Some important options for the configure script are:

* `--prefix=/path/to/install/directory`
* `--enable-optimize --disable-debug`

  Use the optimization flags while
  compiling the source. Also omit debug symbols. These two are need to
  be specified together

* `--disable-rintegration --disable-py2integration --disable-py3integration`

  Disable a number of optional features, that are not relevant to
  TPC-H performance testing. These are not essential, but help reduce
  the compilation time.


### Preparing the database(s)

We have prepared a set of scripts that automate the process of
preparing databases loaded with TPC-H and running various kinds of
performance measurements. The scripts can be found on
[github](https://github.com/MonetDBSolutions/tpch-scripts). The tree
structure of this repository is shown below:

    ├── 01_build
    │   ├── dbgen
    │   │   ├── answers
    │   │   ├── check_answers
    │   │   ├── queries
    │   │   ├── reference
    │   │   ├── tests
    │   │   └── variants
    │   ├── dev-tools
    │   └── ref_data
    │       ├── 1
    │       ├── 100
    │       ├── 1000
    │       ├── 10000
    │       ├── 100000
    │       ├── 300
    │       ├── 3000
    │       └── 30000
    ├── 02_load
    └── 03_run

Directory `01_build` contains the data generator that TPC provides for
this benchmark, directory `02_load` contains scripts that automate the
creation and loading of the data in MonetDB, and directory `03_run`
contains scripts for running the queries, and capturing the results.

In the root directory of this repository you will find a script named
`tpch_build.sh`, that automates, creating and loading data in
MonetDB. The only arguments are the scale factor for the generated
data and the absolute path for the MonetDB farm. Optionally you can
specify a port number for the MonetDB daemon. The default value for
this setting is 50000.

For example the command:

    $ ./tpch_build.sh -s 100 -f /path/to/farm

will do the following:

1. generate the data for scale factor 100 (i.e. 100 GB of data)
1. create a MonetDB database farm at the specified directory
1. create a MonetDB database named `SF-100` (NB for scale factors smaller than 1, the decimal separator '.' is replaced by '_' so as to produce a dbname accepted by MonetDB)
1. load the data in the database
1. print the command you need to run in order to start the MonetDB server

### Running TPC-H

After the database has been created you can use the scripts inside the
`03_run` directory in order to measure the performance under various
conditions. This directory contains the TPC-H queries and three
scripts that help with performing measurements.

#### The `horizontal_run.sh` script

The simplest measurement is done using the script
`horizontal_run.sh` (or the script `vertical_run.sh`, see below).
It runs every TPC-H benchmark query repeatedly for N times (hence the name
 `horizontal_run`).
You need to specify the following arguments:

* database that contains the data (`--db`)
* number of repeats (`--number`)

  Each query should be run multiple times in order to correctly take
  into account the effects of data caching, and other factors that
  might incidentally affect the running times. The more times you run
  the queries, the more robust the measurements will be, but also the
  more time consuming the experiment will be. 3, 4 and 5 seem to be
  reasonable values for this parameter

* tag (`--tag`)

  An arbitrary string that helps distinguish between different
  experiments.

* output file (`--output`)

  The file name for the output csv file.

The file contains the following columns:

1. database
1. tag
1. query number
1. minimum time
1. maximum time
1. average time

The correct metric to use is minimum time (the best time that the
database achieved for this query), but maximum and average times are
reported as well.

In this case the MonetDB server needs to be running before executing
the script. The simplest way to start it is by using the command the
`tpch_build.sh` reports when it finishes.

#### The `vertical_run.sh` script

The script `vertical_run.sh` is another way to do experiments.
It repeatedly runs the whole set of TPC-H benchmark queries for N times (hence
 the name `vertial_run`).

This script supports exactly the same command line options as the script
 `horizontal_run.sh` does.
However, it outputs different information about query executions, which
 contains the following columns:

1. database
1. tag
1. run number
1. total exec. time of this query set

#### The `param_experiment.sh` script

In order to measure the effect that different *arithmetic* values for
MonetDB server parameters have on the query execution times we can use
the script `param_experiment.sh`. Example parameters of this kind are
`gdk_nr_threads` which restricts the number of threads MonetDB is
allowed to use, and `gdk_mmap_minsize_transient` which defines a
threshold in bytes after which memory map will be used for
intermediate results.

The important arguments for this script are:

* farm (`--farm`)

  The directory where the database farm resides. This argument is
  needed in this case because the script starts and stops the server
  itself, and therefore needs to know exactly where the data is

* database (`--db`)

  The database where the data resides. Note: it is important to
  understand that farm and database are different concepts, much like
  database cluster and database are different concepts in PostgreSQL
  (see for instance
  [this](https://www.postgresql.org/docs/11/creating-cluster.html)).

* number of repeats (`--number`)

  How many times to repeat each query. The same semantics as the same
  parameter in `horizontal_run.sh`.

* server argument (`--arg`)

  The name of the server argument.

* value range (`--range`)

  The range of values to consider for the parameter in the form
  `min:max[:step]`.

* a transformation function for the values (`--function`)

  In some cases it is convenient to specify a simple function that
  transforms the range of values specified with the previous
  parameter. For instance values for `gdk_mmap_minsize_transient` are
  measured in bytes but are meaningful in the range of Gigabytes. We
  can use the `--function` option in order to apply the expontenation
  operation to the range. The value of this option should be a valid
  Python 3 expression. The string `$r` is substituted for the current
  parameter value.

Some examples might help to clarify the use of this script:

    $ ./param_experiment.sh -f /tmp/example_farm -d SF-100 -n 5 -a gdk_nr_threads -r 1:20

The above invocation will do the following:

1. start a new MonetDB server with the argument `--set gdk_nr_threads=1`
1. use the script `horizontal_run.sh` to run the TPC-H benchmark for
this setting
1. stop the server
1. start a new MonetDB server with the argument `--set
gdk_nr_threads=2`

A more complicated example:

    $ ./param_experiment.sh -f /tmp/example_farm -d SF-100 -n 5 -a gdk_mmap_minsize_transient -r 20:40:2 -u ‘2**$r’

This will start a MonetDB server with the argument

    --set gdk_mmap_minsize_transient=1048576

(1048576 = 2^20) and run the TPC-H benchmark on it. Then it will kill
this server and start a new one with the argument

    --set gdk_mmap_minsize_transient=4194304

(4194304 = 2^22) and run the TPC-H benchmark on this server, etc.

#### The `start_mserver.sh` script

The script `start_mserver.sh` is used internally by the script
`param_experiment.sh` and should not need to be called directly.

#### The `perf_monitor.py` script

The script `perf_monitor.py` can be used to monitor the query performance over
 a relatively long running period.
First, it executes each query in the benchmark `N` times and compute the
 average time of `N-1` fastest executions.
This average is regarded as the baseline performance of this query.
Then, the script repeatedly execute the whole benchmark query set for the time
 period as given by the option `--duration`.
During each iteration, the queries are first randomly reordered for their
 executions.

After each query execution, the script compares this execution time against the
 baseline performance of this query to see if its performance has degradated.
The performance deviation percentage is computed as:

    devpercnt = (current_exec_time - baseline_exec_time) / baseline_exec_time.

If `devpercnt` is larger than the threshold given by the option
 `--degradation_threshold`, then we have detected a _performance degradation_.
Otherwise, we have a _performance normality_.

If the performance status is `normality`, which is also the initial status, and
 the number of performance degradations has reached the number given by the
 option `--patience` (i.e. the patience level), then the performance status
 will be changed into `degradation`.
If the performance status is `degradation` and the number of performance
 normalities has reached the patience level, then the performance status will
 be changed into `normality`.

This script outputs the following information about the query executions:

1. db name
1. run number
1. query number
1. exec. time of this query
1. deviation of this exec. time from its base exec. time
1. percentage of the deviation of compared to its base exec. time
1. performance status: 0 - normality, 1 - degradation

Example usage:

To use this script, one basically need to conduct the following three steps.

First, use the `tpch_build.sh` script (in the root directory of this
 repository) to generate a TPC-H dataset and load it into a MonetDB database:

    ./tpch_build.sh -s 1 -f /<path>/<to>/tpch

Second, start the just created database (this command can be copy-pasted from
 the final output of the `tpch_build.sh` script, or acquired later from this
 script using it `-d` option):

    mserver5 --dbpath=/<path>/<to>/tpch/SF-1 --set monet_vault_key=/<path>/<to>/tpch/SF-1/.vaultkey

Finally, start the performance monitoring:

    ./perf_monitor.py -i 10 -p 5 -d 30 -t 0.5 SF-1

where the options mean:
* `-i 10`: execute the queries 10 times to obtain the baseline performance
*  `-p 5`: collect 5 performance degradations before printing a warning
* `-d 30`: run the performance monitoring for 30 seconds (excl. the initiation time)
* `-t 0.5`: regard execution time increases of larger than 50% as performance degradations

For more information about the options, see `./perf_monitor.py -h`.

