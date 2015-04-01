
-- Here we query the gene ranges for pairs of genes annotated with
-- the 'homoeolog_one2one' relationship (or whatever) by the compara
-- gene tree pipeline.

-- We do it in a couple of steps for efficiency (3 then 2 joins
-- instead of 6 joins in one (included for reference below)).

/*
-- Creates spurious output that needs to be removed from the result
OPTIMIZE TABLE homology;
OPTIMIZE TABLE homology_member;
OPTIMIZE TABLE gene_member;
OPTIMIZE TABLE dnafrag;
*/

CREATE TEMPORARY TABLE temp_x1 (
  PRIMARY KEY (homology_id, gene_member_id)
) AS
SELECT
  homology_id,
  gene_member_id,
  name,
  stable_id,
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
  -- Paralogues between component genomes
  homology.description = 'homoeolog_one2one'
AND
  -- Bread wheat genome DBid (EG24)
  dnafrag.genome_db_id BETWEEN 2001 AND 2003
#  -- Bread wheat genome DBid (EG25+)
#  dnafrag.genome_db_id = 2054
;

-- Creates spurious output that needs to be removed from the result
OPTIMIZE TABLE temp_x1;

CREATE TEMPORARY TABLE temp_x2 LIKE          temp_x1;
INSERT INTO            temp_x2 SELECT * FROM temp_x1;

-- Creates spurious output that needs to be removed from the result
OPTIMIZE TABLE temp_x2;

SELECT
  a.name          AS aan,
#  a.stable_id     AS aai,
  a.dnafrag_start AS aas,
  a.dnafrag_end   AS aae,
  --
  b.name          AS bbn,
#  a.stable_id     AS bbi,
  b.dnafrag_start AS bbs,
  b.dnafrag_end   AS bbe
FROM
  temp_x1 a
INNER JOIN
  temp_x2 b
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
