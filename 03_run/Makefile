SQL= 01.sql 02.sql 03.sql 04.sql 05.sql 06.sql 07.sql 08.sql 09.sql 10.sql 11.sql 12.sql 13.sql 14.sql 15.sql 16.sql \
	18.sql 19.sql 21.sql 22.sql
	# 17.sql 20.sql \

PG_TARGETS=$(SQL:.sql=.pg_ok)
MYSQL_TARGETS=$(SQL:.sql=.my_ok)

default:
	@echo "Run 'make postgres' or 'make mysql'"
	@false

postgres: $(PG_TARGETS)

mysql: $(MYSQL_TARGETS)

%.pg_ok: %.sql
	mysql SF1 <$<
	touch $@

%.my_ok: %.mysql
	mysql SF1 <$<
	touch $@

#%.mysql: %.sql
#	tr a-z A-Z <$< >$@.tmp
#	mv $@.tmp $@

clean:
	rm -f *.pg_ok *.my_ok


#-       psql -P pager=off -v ON_ERROR_STOP=1 -d SF-1 -f $<
#+       mysql SF1 <$<
