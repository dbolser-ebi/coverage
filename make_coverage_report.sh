#!/bin/bash

file=$1
db_cmd=$2

file=${file:?plz pass an atac style file plz}
db_cmd=${db_cmd:-mysql-eg-mirror}

echo "ATAC FILE: '${file}'"
echo "USING '$db_cmd'" 



## Hopefully no more config below

pair=$(basename $file .atac.uids)
#echo "PAIR: '${pair}'"

## We grab db names from this filename
query_db=${pair%-TO-*}; query_db=${query_db%#*}
targe_db=${pair#*-TO-}; targe_db=${targe_db%#*}

## A bit cleaner...
pair=${query_db}-TO-${targe_db}

echo -e "\tDB1: '${query_db}'"
echo -e "\tDB2: '${targe_db}'"


echo
echo getting ranges

for db in $query_db $targe_db; do
    echo -e "\t$db"
    
    ## Total range
    if [ ! -s Ranges/${db}_total.ranges ];
    then
        echo -e "\t\tDumping total ranges for $db"
        $db_cmd $db -Ne '
          SELECT seq_region.name, 1, length FROM seq_region
          INNER JOIN seq_region_attrib USING (seq_region_id)
          INNER JOIN attrib_type USING (attrib_type_id)
          WHERE code = "toplevel"' \
            > Ranges/${db}_total.ranges
    else
        echo -e "\t\tusing existing total ranges for $db"
    fi
    
    ## Gene range
    if [ ! -s Ranges/${db}_gene.ranges ];
    then
        echo -e "\t\tDumping gene ranges for $db"
        $db_cmd $db -Ne '
          SELECT seq_region.name, seq_region_start, seq_region_end
          FROM gene INNER JOIN seq_region USING (seq_region_id)
          WHERE biotype = "protein_coding"' \
            > Ranges/${db}_gene.ranges
    else
        echo -e "\t\tUsing existing gene ranges for $db"
    fi
    
    ## Exon range
    if [ ! -s Ranges/${db}_exon.ranges ];
    then
        echo -e "\t\tDumping exon ranges for $db"
        $db_cmd $db -Ne '
          SELECT seq_region.name, exon.seq_region_start, exon.seq_region_end
          FROM exon INNER JOIN exon_transcript USING (exon_id)
          INNER JOIN transcript USING (transcript_id)
          INNER JOIN gene ON transcript_id = canonical_transcript_id
          INNER JOIN seq_region ON gene.seq_region_id = seq_region.seq_region_id
          WHERE gene.biotype = "protein_coding"' \
            > Ranges/${db}_exon.ranges
    else
        echo -e "\t\tUsing existing exon ranges for $db"
    fi
    
done
echo



echo
echo getting coverage stats

rm -f ${pair}.stats

for range in total gene exon; do
    echo -e "\t${range}"
    
    echo -ne "$range\tblock\tquery\t" >> ${pair}.stats
    perl ./simple_coverage_atac.plx \
        --atac-type u --side query \
        --range-file Ranges/${query_db}_${range}.ranges \
        --atac-file ${file} >> ${pair}.stats
    echo
    
    echo -ne "$range\tblock\ttarget\t" >> ${pair}.stats
    perl ./simple_coverage_atac.plx \
        --atac-type u --side target \
        --range-file Ranges/${targe_db}_${range}.ranges \
        --atac-file ${file} >> ${pair}.stats
    echo
    
    echo -ne "$range\trun\tquery\t" >> ${pair}.stats
    perl ./simple_coverage_atac.plx \
        --atac-type r --side query \
        --range-file Ranges/${query_db}_${range}.ranges \
        --atac-file ${file} >> ${pair}.stats
    echo

    echo -ne "$range\trun\ttarget\t" >> ${pair}.stats
    perl ./simple_coverage_atac.plx \
        --atac-type r --side target \
        --range-file Ranges/${targe_db}_${range}.ranges \
        --atac-file ${file} >> ${pair}.stats
    echo

done

exit





## Yuck...
## Yuck...
## Yuck...

dir=grabatac
for f in \
    arabidopsis_thaliana_core_6_59_9#TAIR9-TO-arabidopsis_thaliana_core_22_75_10#TAIR10.atac.uids \
    brachypodium_distachyon_core_4_56_10#Brachy1.0-TO-brachypodium_distachyon_core_22_75_12#v1.0.atac.uids \
    hordeum_vulgare_core_23_76_1#030312v2-TO-hordeum_vulgare_core_26_79_2#220312v1.atac.uids \
    medicago_truncatula_core_25_78_1#GCA_000219495.1-TO-medicago_truncatula_core_26_79_2#GCA_000219495.2.atac.uids \
    oryza_barthii_core_22_75_1#ABRL00000000-TO-oryza_barthii_core_26_79_3#ABRL00000000.atac.uids \
    oryza_glaberrima_core_10_63_51#1.0-TO-oryza_glaberrima_core_22_75_2#AGI1.1.atac.uids \
    oryza_indica_core_6_59_1#Jan_2005-TO-oryza_indica_core_22_75_2#ASM465v1.atac.uids \
    oryza_meridionalis_core_25_78_1#ALNW00000000-TO-oryza_meridionalis_core_26_79_13#Oryza_meridionalis_v1.3.atac.uids \
    oryza_sativa_core_19_72_6#MSU6-TO-oryza_sativa_core_20_73_7#IRGSP-1.0.atac.uids \
    populus_trichocarpa_core_4_56_11#jgi2004-TO-populus_trichocarpa_core_22_75_20#JGI2.0.atac.uids \
    triticum_aestivum_core_24_77_1#IWGSP1-TO-triticum_aestivum_core_26_79_2#IWGSC2.atac.uids \
    vitis_vinifera_core_10_63_2#IGGP_12x-TO-vitis_vinifera_core_26_79_3#IGGP_12x.atac.uids \
    vitis_vinifera_core_4_56_1#8X-TO-vitis_vinifera_core_22_75_3#IGGP_12x.atac.uids \
    zea_mays_core_17_70_5#AGPv2-TO-zea_mays_core_20_73_6#AGPv3.atac.uids
do
    ls $dir/$f
    ./make_coverage_report.sh $dir/$f
done



for f in *.stats; do  
    perl -ne '
push @x, [split("\t", $_)];
END{
  printf "%d\t%d\t%d\t%d\t".
    "%d\t%d\t%.4f%%\t%.4f%%\t%.4f%%\t%.4f%\t".
    "%d\t%d\t%.4f%%\t%.4f%%\t%.4f%%\t%.4f%\t".
    "%d\t%d\t%.4f%%\t%.4f%%\t%.4f%%\t%.4f%\n",
    $x[0][8], $x[2][8], $x[0][3], $x[1][3],
    $x[0][5]/1000000, $x[1][5]/1000000, $x[0][16], $x[1][16], $x[02][16], $x[03][16],
    $x[4][5]/1000000, $x[5][5]/1000000, $x[4][16], $x[5][16], $x[06][16], $x[07][16],
    $x[8][5]/1000000, $x[9][5]/1000000, $x[8][16], $x[9][16], $x[10][16], $x[11][16],
}' $f
done > \
    all_stats-preleff.tsv





## The following sub-set have leffy problems...

dir=/nfs/nobackup/ensemblgenomes/grabmuel/ensgen-sequences/atac_withLeaff
dir=CleanATAC/CleanNames
for f in \
    arabidopsis_thaliana_core_6_59_9#TAIR9-TO-arabidopsis_thaliana_core_22_75_10#TAIR10.atac.uids \
    brachypodium_distachyon_core_4_56_10#Brachy1.0-TO-brachypodium_distachyon_core_22_75_12#v1.0.atac.uids \
    oryza_glaberrima_core_10_63_51#1.0-TO-oryza_glaberrima_core_22_75_2#AGI1.1.atac.uids \
    oryza_indica_core_6_59_1#Jan_2005-TO-oryza_indica_core_22_75_2#ASM465v1.atac.uids \
    oryza_sativa_core_19_72_6#MSU6-TO-oryza_sativa_core_20_73_7#IRGSP-1.0.atac.uids \
    populus_trichocarpa_core_4_56_11#jgi2004-TO-populus_trichocarpa_core_22_75_20#JGI2.0.atac.uids \
    vitis_vinifera_core_4_56_1#8X-TO-vitis_vinifera_core_22_75_3#IGGP_12x.atac.uids \
    zea_mays_core_17_70_5#AGPv2-TO-zea_mays_core_20_73_6#AGPv3.atac.uids
do
    ./make_coverage_report.sh $dir/$f
done

## NB oryza_indica_ has a problem in its fasta file!


echo -ne "atac/blocks\tatac/runs\tquery/seq\ttarge/seq\t" # Preamble
echo -ne "query/mb\ttarge/mb\tquery/covb\ttarge/covb\tquery/covr\ttarge/covr\t" # Total
echo -ne "query/mb\ttarge/mb\tquery/covb\ttarge/covb\tquery/covr\ttarge/covr\t" # Genes
echo -ne "query/mb\ttarge/mb\tquery/covb\ttarge/covb\tquery/covr\ttarge/covr\n" # Exons
for f in *.stats; do  
    echo -ne "$f\t"
    perl -ne '
push @x, [split("\t", $_)];
END{
  printf "%d\t%d\t%d\t%d\t".
    "%d\t%d\t%.4f%%\t%.4f%%\t%.4f%%\t%.4f%\t".
    "%d\t%d\t%.4f%%\t%.4f%%\t%.4f%%\t%.4f%\t".
    "%d\t%d\t%.4f%%\t%.4f%%\t%.4f%%\t%.4f%\n",
    $x[0][8], $x[2][8], $x[0][3], $x[1][3],
    $x[0][5]/1000000, $x[1][5]/1000000, $x[0][16], $x[1][16], $x[02][16], $x[03][16],
    $x[4][5]/1000000, $x[5][5]/1000000, $x[4][16], $x[5][16], $x[06][16], $x[07][16],
    $x[8][5]/1000000, $x[9][5]/1000000, $x[8][16], $x[9][16], $x[10][16], $x[11][16],
}' $f
done > \
    all_stats-postleff.tsv






## Make a 'clean' set...

dir1=grabatac
dir2=/nfs/nobackup/ensemblgenomes/grabmuel/ensgen-sequences/atac_withLeaff

for f in \
    $dir2/arabidopsis_thaliana_core_6_59_9#TAIR9-TO-arabidopsis_thaliana_core_22_75_10#TAIR10.atac.uids \
    $dir2/brachypodium_distachyon_core_4_56_10#Brachy1.0-TO-brachypodium_distachyon_core_22_75_12#v1.0.atac.uids \
    $dir1/hordeum_vulgare_core_23_76_1#030312v2-TO-hordeum_vulgare_core_26_79_2#220312v1.atac.uids \
    $dir1/medicago_truncatula_core_25_78_1#GCA_000219495.1-TO-medicago_truncatula_core_26_79_2#GCA_000219495.2.atac.uids \
    $dir1/oryza_barthii_core_22_75_1#ABRL00000000-TO-oryza_barthii_core_26_79_3#ABRL00000000.atac.uids \
    $dir2/oryza_glaberrima_core_10_63_51#1.0-TO-oryza_glaberrima_core_22_75_2#AGI1.1.atac.uids \
    $dir2/oryza_indica_core_6_59_1#Jan_2005-TO-oryza_indica_core_22_75_2#ASM465v1.atac.uids \
    $dir1/oryza_meridionalis_core_25_78_1#ALNW00000000-TO-oryza_meridionalis_core_26_79_13#Oryza_meridionalis_v1.3.atac.uids \
    $dir2/oryza_sativa_core_19_72_6#MSU6-TO-oryza_sativa_core_20_73_7#IRGSP-1.0.atac.uids \
    $dir2/populus_trichocarpa_core_4_56_11#jgi2004-TO-populus_trichocarpa_core_22_75_20#JGI2.0.atac.uids \
    $dir1/triticum_aestivum_core_24_77_1#IWGSP1-TO-triticum_aestivum_core_26_79_2#IWGSC2.atac.uids \
    $dir1/vitis_vinifera_core_10_63_2#IGGP_12x-TO-vitis_vinifera_core_26_79_3#IGGP_12x.atac.uids \
    $dir2/vitis_vinifera_core_4_56_1#8X-TO-vitis_vinifera_core_22_75_3#IGGP_12x.atac.uids \
    $dir2/zea_mays_core_17_70_5#AGPv2-TO-zea_mays_core_20_73_6#AGPv3.atac.uids
do
    ls $f;
    cp $f CleanATAC
done



Query to tidy 

arabidopsis_thaliana_core_6_59_9#TAIR9-TO-arabidopsis_thaliana_core_22_75_10#TAIR10.atac.uids
brachypodium_distachyon_core_4_56_10#Brachy1.0-TO-brachypodium_distachyon_core_22_75_12#v1.0.atac.uids
hordeum_vulgare_core_23_76_1#030312v2-TO-hordeum_vulgare_core_26_79_2#220312v1.atac.uids
medicago_truncatula_core_25_78_1#GCA_000219495.1-TO-medicago_truncatula_core_26_79_2#GCA_000219495.2.atac.uids
oryza_barthii_core_22_75_1#ABRL00000000-TO-oryza_barthii_core_26_79_3#ABRL00000000.atac.uids
oryza_meridionalis_core_25_78_1#ALNW00000000-TO-oryza_meridionalis_core_26_79_13#Oryza_meridionalis_v1.3.atac.uids
oryza_sativa_core_19_72_6#MSU6-TO-oryza_sativa_core_20_73_7#IRGSP-1.0.atac.uids
populus_trichocarpa_core_4_56_11#jgi2004-TO-populus_trichocarpa_core_22_75_20#JGI2.0.atac.uids
vitis_vinifera_core_10_63_2#IGGP_12x-TO-vitis_vinifera_core_26_79_3#IGGP_12x.atac.uids
vitis_vinifera_core_4_56_1#8X-TO-vitis_vinifera_core_22_75_3#IGGP_12x.atac.uids
zea_mays_core_17_70_5#AGPv2-TO-zea_mays_core_20_73_6#AGPv3.atac.uids



oryza_indica_core_6_59_1#Jan_2005-TO-oryza_indica_core_22_75_2#ASM465v1.atac.uids
