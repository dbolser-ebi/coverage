
-- Query to select all alignments between pairs of sequences in a
-- given WGA (using our 'MLSS_ID' to identify the WGA). In fact it's
-- safer to use two genome_db_ids, as this sets order of the results
-- (query vs. target)

-- For details of the schema, see:
-- http://www.ensembl.org/info/docs/api/compara/compara_schema.html



/* If needed...

OPTIMIZE TABLE dnafrag;
OPTIMIZE TABLE genomic_align;
OPTIMIZE TABLE genomic_align_block;

-- Order (and spelling!) is important!
SET @species1 = 'solanum_lycopersicum';
SET @species2 = 'solanum_tuberosum';

-- Use these explicitly in the query below (sorry)
SELECT @genome_db_id1 := genome_db_id FROM genome_db WHERE name = @species1;
SELECT @genome_db_id2 := genome_db_id FROM genome_db WHERE name = @species2;

*/

SELECT
  xx.name, MIN(x.dnafrag_start), MAX(x.dnafrag_end),
  yy.name, MIN(y.dnafrag_start), MAX(y.dnafrag_end)
FROM
  genomic_align_block b
--
INNER JOIN 
  genomic_align x
ON
  b.genomic_align_block_id =
  x.genomic_align_block_id
INNER JOIN
  dnafrag xx
ON
   x.dnafrag_id =
  xx.dnafrag_id
--
INNER JOIN 
  genomic_align y
ON
  b.genomic_align_block_id =
  y.genomic_align_block_id
INNER JOIN
  dnafrag yy
ON
   y.dnafrag_id =
  yy.dnafrag_id
--
WHERE
  --
  -- Limit to a specific WGA
  --
  b.method_link_species_set_id = 9453
  --
  -- OR
  --
  -- Limit to a specific pair of genome_db_ids
  --
  #xx.genome_db_id = @genome_db_id1 AND
  #yy.genome_db_id = @genome_db_id2
  --
AND
  x.genomic_align_id !=
  y.genomic_align_id
GROUP BY
  b.group_id,
  x.dnafrag_id,
  y.dnafrag_id
--
-- For debugging...
#LIMIT
#  03
;
