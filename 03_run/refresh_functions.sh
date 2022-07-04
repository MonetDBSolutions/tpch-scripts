#!/bin/bash

if [ -z "$1" ]; then
  db="SF-10"
else
  db="$1"
fi

rf1(){  
  s=$(date +%s.%N)
  mclient -d "$db" -s "COPY INTO orders from '$PWD/orders.tbl.u1' USING DELIMITERS '|', '|\n';"
  mclient -d "$db" -s "COPY INTO lineitem from '$PWD/lineitem.tbl.u1' USING DELIMITERS '|', '|\n';"
  x=$(date +%s.%N)
  
  elapsed=$(echo "scale=4; $x - $s" | bc)
  echo "Refresh function 1 $db: $elapsed s "
}

rf2(){
  # The output from ./dbgen -v -U 1 -s 1000 generates a file delete.1 that does not match the ids from lineitem/order file 
  cat orders.tbl.u1 | cut -f 1 -d '|' > delete.1
  mclient -d "$db" -s "CREATE TABLE rfids(id INT); COPY INTO rfids from '$PWD/delete.1';"
  
  s=$(date +%s.%N)
  mclient -d "$db" -s "DELETE FROM lineitem WHERE lineitem.l_orderkey IN (SELECT id FROM rfids);"
  mclient -d "$db" -s "DELETE FROM orders WHERE orders.o_orderkey IN (SELECT id FROM rfids);"
  x=$(date +%s.%N)

  elapsed=$(echo "scale=4; $x - $s" | bc)
  echo "Refresh function 2 $db: $elapsed s "

  mclient -d "$db" -s "DROP TABLE rfids;"
}

generate_data(){
  # This will work if the database name is in the format SF-XXX
  SF=$(cut -d '-' -f 2 <<< "$db")
  pushd ../01_build/dbgen/
  ./dbgen -v -U 1 -s $SF
  popd
}



mclient -d "$db" -i tpch_writable.sql
#generate_data
pushd ../01_build/dbgen/
rf1
rf2
popd
