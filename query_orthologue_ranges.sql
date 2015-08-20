
-- Here we query the gene ranges for pairs of genes annotated with the
-- 'homoeolog_one2one' relationship (or whatever) by the compara gene
-- tree pipeline.

-- We do it in a couple of steps for efficiency (3 then 2 joins
-- instead of 6 joins in one (included for reference below)).

-- Creates spurious output that needs to be removed from the result
OPTIMIZE TABLE homology;
OPTIMIZE TABLE homology_member;
OPTIMIZE TABLE gene_member;
OPTIMIZE TABLE dnafrag;

-- Since we have to trim cruft from the result of this query anyway,
-- lets be frivolous and use SQL variables...
#SET @homology_description = 'homoeolog_one2one';

SET @homology_description =  'ortholog_one2one';
#SET @homology_description =  'ortholog_one2many';
#SET @homology_description =  'ortholog_many2many';

-- Order (and spelling!) is important!
SET @species1 = 'solanum_lycopersicum';
SET @species2 = 'solanum_tuberosum';

#SET @species1 = 'arabidopsis_thaliana';
#SET @species2 = 'arabidopsis_lyrata';

#SET @species1 = 'arabidopsis_thaliana';
#SET @species2 = 'brassica_rapa';



-- NB: These may not be so easy to configure like this...
#  -- Bread wheat genome DBid (EG24)
#  dnafrag.genome_db_id BETWEEN 2001 AND 2003
#  -- Bread wheat genome DBid (EG25+)
#  dnafrag.genome_db_id = 2054



-- Nothing below should need configuring...

-- Get the genome_db_ids...
SELECT @genome_db_id1 := genome_db_id FROM genome_db WHERE name = @species1;
SELECT @genome_db_id2 := genome_db_id FROM genome_db WHERE name = @species2;

-- and MLSS for the above pair (I can't think of a better way...)
SELECT
  @mlss_id := method_link_species_set_id
FROM
  species_set
INNER JOIN
  method_link_species_set
USING
  (species_set_id)
WHERE
  method_link_id = 201 # orthologues
AND
  genome_db_id IN (@genome_db_id1, @genome_db_id2)
GROUP BY
  method_link_species_set_id
HAVING
  COUNT(*) = 2
;



-- This query can be slow! (The homology and homology member tables
-- are enormous.)

-- TODO: Why bother dumping the actuall sequence name? The id is just
-- as unique and consistent. This would save two extra joins.

DROP             TABLE IF EXISTS temp_x1;
CREATE TEMPORARY TABLE           temp_x1 (
  PRIMARY KEY (homology_id, genome_db_id)
) AS
SELECT
  homology_id,
  #method_link_species_set_id,
  #gene_member_id,
  #stable_id,
  genome_db_id,
  dnafrag.name,
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
  dnafrag
USING
  (dnafrag_id, genome_db_id)
WHERE
  homology.description = @homology_description
AND
   method_link_species_set_id = @mlss_id
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
#  a.genome_db_id  AS bbg,
  a.dnafrag_start AS aas,
  a.dnafrag_end   AS aae,
  --
  b.name          AS bbn,
#  b.stable_id     AS bbi,
#  b.genome_db_id  AS bbg,
  b.dnafrag_start AS bbs,
  b.dnafrag_end   AS bbe
FROM
  temp_x1 a
INNER JOIN
  temp_x2 b
USING
  (homology_id)
WHERE
  a.genome_db_id = @genome_db_id1
AND
  b.genome_db_id = @genome_db_id2
--
-- Debugging
#LIMIT
#  03
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
