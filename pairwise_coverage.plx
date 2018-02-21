#!/bin/env perl

use strict;
use warnings;

# TODO: Thinking about the above, there need be no consistency between
# the 'alignment' of x and y. All we need for support is that one base
# of x1 overlaps y1 and one base of x2 overlaps y2. A different
# approach would be to project x1 onto x2 using y1 -> y2, and looking
# to see if x1` overlaps x2. A projection isn't possible here because
# we only have block level alignment details, we need base level
# alignments to project accurately!

die "pass two, two part (query and target) range-files\n"
    unless @ARGV == 2;

open( my $RANGEPAIR_1, '<', $ARGV[0] )
    or die "Failed to open '$ARGV[0]': $!\n";

open( my $RANGEPAIR_2, '<', $ARGV[1] )
    or die "Failed to open '$ARGV[1]': $!\n";



my (%one, $one);

while(<$RANGEPAIR_1>){
    chomp;
    $one++;
    
    my ($id1, $st1, $en1, 
        $id2, $st2, $en2) = split "\t";
    
    push @{$one{"$id1:$id2"}},
       [$id1, $st1, $en1, 
        $id2, $st2, $en2];
}

warn "Range pairs in file one: $one\n";



my (%two, $two);

while(<$RANGEPAIR_2>){
    chomp;
    $two++;
    
    my ($id1, $st1, $en1, 
        $id2, $st2, $en2) = split "\t";
    
    push @{$two{"$id1:$id2"}},
       [$id1, $st1, $en1, 
        $id2, $st2, $en2];
}

warn "Range pairs in file two: $two\n";



# ## Sorting one and two... to no avail...
# for (keys %one){
#     @{$one{$_}} =
#         sort { $a->[1] <=> $b->[1] } @{$one{$_}};
# }

# for (keys %two){
#     @{$two{$_}} =
#         sort { $a->[1] <=> $b->[1] } @{$two{$_}};
# }





warn "Counting range pairs in file one 'supported' by those in file two\n";

my $support = 0;

for my $id_pair (keys %one){
    next unless exists $two{$id_pair};
    
    for my $one_aref (@{$one{$id_pair}}){
        
        my ($xid1, $xst1, $xen1, 
            $xid2, $xst2, $xen2) = @$one_aref;
    
    for my $two_aref (@{$two{$id_pair}}){
    
        my ($yid1, $yst1, $yen1, 
            $yid2, $yst2, $yen2) = @$two_aref;
        
        ## Does x range1 finish before y range1 starts?
        next if $xen1 < $yst1;
        
        ## Does x range1 start  after  y range1 ends  ?
        next if $xst1 > $yen1;
        
        ## So, x range1 and y range1 must intersect!
        
        ## Does x range2 finish before y range2 starts?
        next if $xen2 < $yst2;
        
        ## Does x range2 start  after  y range2 ends  ?
        next if $xst2 > $yen2;
        
        ## So, x range2 and y range2 must intersect!
        
        print
            join("\t", 
                 $xid1, $xst1, $xen1,
                 $xid2, $xst2, $xen2,
                 $yid1, $yst1, $yen1,
                 $yid2, $yst2, $yen2
            ), "\n";
        
        ## Calculating the intersection is a pain, so lets just forget
        ## that part ;-)        
        $support++;
        last;
    }}
}

warn $support, "\n";

warn
    sprintf("%6.2f%% range pairs in file one ".
            "'supported' by those in file two", $support/$one*100), "\n";
