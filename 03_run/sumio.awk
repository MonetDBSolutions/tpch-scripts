/sda/	{ if ( cnt > 0) {totread= $5-totread; totwrite=$6 - totwrite; totreq= $2 -totreq;
		} else {
			totread= $5; totwrite=$6; totreq= $2;
		}
		cnt++;
		}
END	{ printf("%d,%d",totread,totwrite)}
