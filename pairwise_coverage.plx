#!/bin/env perl

use strict;
use warnings;

die "pass two, two part (query and target) range-files\n"
    unless @ARGV == 2;

open( my $RANGEPAIR_1, '<', $ARGV[0] )
    or die "Failed to open '$ARGV[0]': $!\n";

open( my $RANGEPAIR_2, '<', $ARGV[1] )
    or die "Failed to open '$ARGV[1]': $!\n";



my @y;

while(<$RANGEPAIR_1>){
    chomp;
    
    my ($id1, $st1, $en1, 
        $id2, $st2, $en2) = split "\t";
    
    push @y, [$id1, $st1, $en1, 
              $id2, $st2, $en2];
}

warn scalar @y, "\n";



my $support;

while(<$RANGEPAIR_2>){
    chomp;
    
    my ($id1, $st1, $en1, 
        $id2, $st2, $en2) = split "\t";
    
    $support++ if
        _has_support($id1, $st1, $en1, $id2, $st2, $en2);
}

warn $support, "\n";



sub _has_support {
    my $xid1 = shift;
    my $xst1 = shift;
    my $xen1 = shift;
    my $xid2 = shift;
    my $xst2 = shift;
    my $xen2 = shift;
    
    ## TODO: This loop can be optimized by sorting @x and quitting
    ## appropriately.
    for(@y){
        my ($yid1, $yst1, $yen1, 
            $yid2, $yst2, $yen2) = @$_;
        
        ## Is x range1 on the same id1 as y range1
        next if $xid1 ne $yid1;
        next if $xid2 ne $yid2;
        
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
        return 1;
    }
    
    ## No intersection today
    return 0;
}
