--  This Source Code Form is subject to the terms of the Mozilla Public
--  License, v. 2.0.  If a copy of the MPL was not distributed with this
--  file, You can obtain one at http://mozilla.org/MPL/2.0/.

--  Copyright 2017-2018 MonetDB Solutions B.V.

START TRANSACTION;
ALTER TABLE nation DROP CONSTRAINT nation_fk1;
ALTER TABLE supplier DROP CONSTRAINT supplier_fk1;
ALTER TABLE customer DROP CONSTRAINT customer_fk1;
ALTER TABLE partsupp DROP CONSTRAINT partsupp_fk1;
ALTER TABLE partsupp DROP CONSTRAINT partsupp_fk2;
ALTER TABLE orders DROP CONSTRAINT orders_fk1;
ALTER TABLE lineitem DROP CONSTRAINT lineitem_fk1;
ALTER TABLE lineitem DROP CONSTRAINT lineitem_fk2 ;
-- ALTER TABLE lineitem DROP CONSTRAINT lineitem_suppkey ;
-- ALTER TABLE lineitem DROP CONSTRAINT lineitem_partsuppkey ;

ALTER TABLE region DROP CONSTRAINT region_pk ;
ALTER TABLE nation DROP CONSTRAINT nation_pk ;
ALTER TABLE supplier DROP CONSTRAINT supplier_pk ;
ALTER TABLE customer DROP CONSTRAINT customer_pk ;
ALTER TABLE part DROP CONSTRAINT part_pk ;
ALTER TABLE partsupp DROP CONSTRAINT partsupp_pk ;

ALTER TABLE orders DROP CONSTRAINT orders_pk ;
ALTER TABLE lineitem DROP CONSTRAINT lineitem_pk ;

COMMIT;
