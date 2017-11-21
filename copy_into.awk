BEGIN {
  regex="[^/]+.tbl"
}
{
  if (match($2, regex)) {
    table=substr($2, RSTART, RLENGTH-4);
    print "COPY " $1 " RECORDS INTO " table " from '"$2"' USING DELIMITERS '|', '|\\n' LOCKED;"
  }
}
