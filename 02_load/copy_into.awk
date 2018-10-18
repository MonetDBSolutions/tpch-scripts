# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0.  If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright 2017-2018 MonetDB Solutions B.V.

BEGIN {
  regex="[^/]+.tbl"
}
{
  if (match($2, regex)) {
    table=substr($2, RSTART, RLENGTH-4);
    print "COPY " $1 " RECORDS INTO " table " from '"$2"' USING DELIMITERS '|', '|\\n' LOCKED;"
  }
}
