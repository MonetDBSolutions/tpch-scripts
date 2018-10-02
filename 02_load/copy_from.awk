BEGIN {
  regex="[^/]+.tbl"
}
{
  if (match($2, regex)) {
    table=substr($2, RSTART, RLENGTH-4);
    print "COPY " table " FROM PROGRAM 'sed -e s/\|$// "$2"' WITH DELIMITER '|';"
  }
}
