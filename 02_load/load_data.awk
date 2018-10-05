
BEGIN {
  regex="[^/]+.tbl"
}
{
  if (match($1, regex)) {
    table=toupper(substr($1, RSTART, RLENGTH-4));
    print "SELECT 'loading " table "';"
    print "LOAD DATA INFILE '" $1 "' INTO TABLE " table " FIELDS TERMINATED BY '|';"
  }
}
