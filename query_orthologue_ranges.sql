
-- Here we query the gene ranges for pairs of genes annotated with
-- the 'homoeolog_one2one' relationship (or whatever) by the compara
-- gene tree pipeline.

-- We do it in a couple of steps for efficiency (3 then 2 joins
-- instead of 6 joins in one (included for reference below)).

CREATE TEMPORARY TABLE temp_x1 (
  PRIMARY KEY (homology_id, gene_member_id)
) AS
SELECT
  homology_id,
  gene_member_id,
  name,
  dnafrag_start,
  dnafrag_end
FROM
  homology
INNER JOIN
  homology_member
USING
  (homology_id)
INNER JOIN
  gene_member
USING
  (gene_member_id)
INNER JOIN
  dnafrag USING (dnafrag_id)
WHERE
  homology.description = 'homoeolog_one2one'
AND
  dnafrag.genome_db_id = 2054
;

OPTIMIZE TABLE temp_x1;

CREATE TEMPORARY TABLE temp_x2 LIKE          temp_x1;
INSERT INTO            temp_x2 SELECT * FROM temp_x1;

OPTIMIZE TABLE temp_x2;

SELECT
  a.name,
  a.dnafrag_start,
  a.dnafrag_end,
  b.name AS bn,
  b.dnafrag_start as bs,
  b.dnafrag_end as be
FROM
  temp_y a INNER JOIN temp_y b
USING
  (homology_id)
WHERE
  a.gene_member_id !=
  b.gene_member_id
;





-- -- ter slur
-- SELECT
--   * 
-- FROM
--   homology h
-- INNER JOIN homology_member hm1 USING (homology_id)
-- INNER JOIN homology_member hm2 USING (homology_id)
-- INNER JOIN
--   gene_member gm1 ON gm1.gene_member_id = hm1.gene_member_id
-- INNER JOIN
--   gene_member gm2 ON gm2.gene_member_id = hm2.gene_member_id
-- INNER JOIN
--   dnafrag df1 ON df1.dnafrag_id = gm1.gene_member_id
-- INNER JOIN
--   dnafrag df2 ON df2.dnafrag_id = gm2.gene_member_id
-- WHERE
--   gm1.genome_db_id = 2054 AND
--   gm2.genome_db_id = 2054
-- AND
--   h.description = 'homoeolog_one2one'
-- AND
--   hm1.gene_member_id !=
--   hm2.gene_member_id
-- LIMIT
--   04
-- ;
