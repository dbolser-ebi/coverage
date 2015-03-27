#!/bin/bash

## Database to get ranges from
core_db=${1:?pass a database}

## On which server?
core_db_cmd=${2:-mysql-eg-mirror}

echo $core_db
echo $core_db_cmd

#exit;

## Where to write results
outdir=Ranges



## OK..

## Total range
$core_db_cmd $core_db -Ne '
  SELECT s.name, 1, length FROM seq_region s
  INNER JOIN seq_region_attrib USING (seq_region_id)
  INNER JOIN attrib_type USING (attrib_type_id)
  WHERE code = "toplevel"' \
      > ${outdir}/${core_db}_total.range
wc -l   ${outdir}/${core_db}_total.range

## Gene range
$core_db_cmd $core_db -Ne '
  SELECT name, seq_region_start, seq_region_end
  FROM gene INNER JOIN seq_region USING (seq_region_id)
  WHERE biotype = "protein_coding"' \
      > ${outdir}/${core_db}_gene.range
wc -l   ${outdir}/${core_db}_gene.range

## Exon range
$core_db_cmd $core_db -Ne '
  SELECT name, exon.seq_region_start, exon.seq_region_end
  FROM exon INNER JOIN exon_transcript USING (exon_id)
  INNER JOIN transcript USING (transcript_id)
  INNER JOIN gene ON transcript_id = canonical_transcript_id
  INNER JOIN seq_region ON gene.seq_region_id = seq_region.seq_region_id
  WHERE gene.biotype = "protein_coding"' \
      > ${outdir}/${core_db}_exon.range
wc -l   ${outdir}/${core_db}_exon.range
