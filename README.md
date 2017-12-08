# TPC-H scripts for MonetDB

This is a set of programs that can be used to generate TPC-H test data and load it to MonetDB.

A copy of `dbgen`, the TPC's data generation utility for TPC-H is included in this repository as allowed for in clause 9 of its [End-User License Agreement (EULA)](http://www.tpc.org/tpc_documents_current_versions/source/tpc_eula.txt). It also available without charge from the TPC, [here](http://www.tpc.org/TPC_Documents_Current_Versions/download_programs/tools-download-request.asp?bm_type=TPC-H&bm_vers=2.17.1&mode=CURRENT-ONLY)

Use the script `./tpch_build.sh` to create a new MonetDB database with TPC-H data and then look at the `03_run` directory and specifically at the `03_run/horizontal_run.sh` script for ideas on running experiments.
