SQL= 01.sql 02.sql 03.sql 04.sql 05.sql 06.sql 07.sql 08.sql 09.sql 10.sql 11.sql 12.sql 13.sql 14.sql 15.sql 16.sql \
	18.sql 19.sql 21.sql 22.sql
	# 17.sql 20.sql \

TARGETS=$(SQL:.sql=.ok)

default: $(TARGETS)

%.ok: %.sql
	psql -P pager=off -v ON_ERROR_STOP=1 -d SF-1 -f $<
	touch $@

clean:
	rm -f *.ok
