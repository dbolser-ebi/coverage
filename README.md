Scripts for looking at 'coverage' of various Whole Genome Alignment
methods across any given set of 'ranges' i.e. genes, exons,
orthologues, etc.

I'm using Set::IntRange to calculate coverage, so in fact, all scripts
here are quite generic, expecting a simple input format of:

    id1 start1 end1 id2 start2 end2
    id1 start1 end1 id2 start2 end2
    ...



1) Query alignment ranges (in the above format) from our Ensembl
   Compara database (using our internal MySQL shortcut command):

    time \
      mysql-eg-mirror ensembl_compara_plants_24_77 \
        < query_alignment_ranges.sql \
        > my_wga.range

See inside that SQL to configure which WGA is selected. Note that we
select 'bi-directional' data here, with every pair being represented
twice as "A -> B" and "B -> A".

Examples:

    ## Set MLSS = 9286
    mysql-eg-mirror ensembl_compara_plants_24_77 -N     \
      < query_alignment_ranges.sql     > wheat_lastz-24.range

    ## Set MLSS = 9358
    mysql-eg-mirror ensembl_compara_plants_25_78 -N     \
      < query_alignment_ranges.sql     > wheat_lastz-25.range

    ## Set MLSS = 9413
    mysql-eg-mirror ensembl_compara_plants_26_79 -N     \
      < query_alignment_ranges.sql     > wheat_atac-26.range



2) Query a range to compare to (in the above format) from our Ensembl
   Core database (using our internal MySQL shortcut command):

Examles:

    time \
      ./query_basic_ranges.sh triticum_aestivum_core_24_77_1 mysql-eg-mirror



3) Compare some ranges:

    time \
      ./simple_coverage.plx -s target \
        wheat_lastz-24.range \
        Ranges/triticum_aestivum_core_24_77_1_total.range 



4) Repeat...

   Query the 1 to 1 orthologues between wheat A, B, and D component
   genomes (see inside the script to set the homology type:

    time \
      mysql-staging-2-ensrw ensembl_compara_plants_26_79 \
        < query_orthologue_ranges.sql \
        > orthologue.ranges

   Compare some ranges:

    time \
      ./simple_coverage.plx \
        wheat_atac-26-3B_vs_3A.range \
        Ranges/orthologue.ranges.2

