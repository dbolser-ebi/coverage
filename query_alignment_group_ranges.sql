
-- Query to select all alignments between pairs of sequences in a
-- given WGA (using our 'MLSS_ID' to identify the WGA).

-- For details of the schema, see:
-- http://www.ensembl.org/info/docs/api/compara/compara_schema.html



/* If needed...

OPTIMIZE TABLE dnafrag;
OPTIMIZE TABLE genomic_align;
OPTIMIZE TABLE genomic_align_block;

*/



#EXPLAIN -- Useful for debugging
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
  -- Limit to a specific WGA (pick one!)
  --
  -- Wheat inter-component alignments using LASTZ (EG24 and below)
  b.method_link_species_set_id = 9286
  --
  -- Wheat inter-component alignments using LASTZ (EG25 and above)
  #b.method_link_species_set_id = 9358
  --
  -- Wheat inter-component alignments using ATAC (EG26 and above)
  #b.method_link_species_set_id = 9413
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
