#!/bin/env perl

use strict;
use warnings;

## Easy manipulation of sets of integers (arbitrary intervals)
use Set::IntRange;

## Create two empty sets to play with
my $set_len = 1000000000;
my $set_a = Set::IntRange->new(1, $set_len);
my $set_b = Set::IntRange->new(1, $set_len);

## Fill a few thousand 'ranges' in both sets...
my $num_ranges = 5000;
my $range_len = 1000;

for (1..$num_ranges){
    my $ra = int(rand($set_len - $range_len));
    $set_a->Interval_Fill($ra, $ra + $range_len);
    
    my $rb = int(rand($set_len - $range_len));
    $set_b->Interval_Fill($rb, $rb + $range_len);
}

## Now find the size of the union between the two sets. This is what
## we call the 'coverage' of set_a on set_b.
my $set_u = Set::IntRange->new(1, $set_len);
$set_u->Union($set_a, $set_b);

# Number of bits set in the vector, AKA coverage.
print $set_u->Norm, "\n";
