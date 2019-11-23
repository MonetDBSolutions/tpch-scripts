# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0.  If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright 2017-2018 MonetDB Solutions B.V.

/sda/	{ if ( cnt > 0) {totread= $5-totread; totwrite=$6 - totwrite; totreq= $2 -totreq;
		} else {
			totread= $5; totwrite=$6; totreq= $2;
		}
		cnt++;
		}
END	{ printf("%d,%d",totread,totwrite)}
