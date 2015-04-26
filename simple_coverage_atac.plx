#!perl

use strict;
use warnings;

## Easy manipulation of sets of integers (arbitrary intervals)
use Set::IntRange;

## Command line...
use Getopt::Long;

## Files and options
my $range_file;
my $atac_file;
my $atac_type  = 'u'; # Ungapped blocks
my $side       = 'query';

## Get commad line options
GetOptions( 
    ## Note, these can be genes, exons, or any other range
    'range-file=s'      => \$range_file,

    ## Standard ATAC format expected
    'atac-file|file=s'  => \$atac_file,

    ## Either b (blocks), r (runs), or c (clumps)
    'atac-type|type=s'  => \$atac_type,
    
    ## Either query or target
    'side=s'            => \$side,
)
    or die "failure to communicate\n";

die "pass a range-file\n" unless defined $range_file;
die "pass an atac-file\n" unless defined $atac_file;

open( my $RANGE, '<', $range_file )
    or die "Failed to open range file '$range_file': $!\n";

open( my $ATAC, '<', $atac_file )
    or die "Failed to open atac file '$atac_file': $!\n";

warn "using $range_file\n";
warn "using $atac_file\n";

die "atac-type must be either b (block), r (run) or c (clump)\n"
    unless
        $atac_type eq 'u' || # Ungapped blocks
        $atac_type eq 'r' || # Runs
        $atac_type eq 'c';   # Clumps

warn "using $atac_type\n";

my $atac_type_pattern = qr(^M $atac_type);

die "side must be either query or target\n"
    unless
        $side eq 'query'  ||
        $side eq 'target';

warn "using $side\n";





## This is needed for efficieny below... Although, after debugging, it
## may not be needed! Certainly if we keep it, the code below can be
## cleaned up.
my %length;

warn "Parsing the range file pass 1/2\n";

while(<$RANGE>){
    chomp;
    my ($id, $st, $en) = split "\t";
    if($en > ($length{$id} || 0)){
        $length{$id} = $en;
    }
}
## Rewind
seek $RANGE, 0, 0;
warn scalar keys %length, "\n";


warn "Parsing the atac file pass 1/2\n";

while(<$ATAC>){
    ## Only want to look at match lines of this type
    next unless /$atac_type_pattern/;
    
    chomp;
    my @row = split ' ';
    
    my $id1 = $row[4];
    my $st1 = $row[5]+1;
    my $en1 = $row[5]+$row[6];
    
    my $id2 = $row[8];
    my $st2 = $row[9]+1;
    my $en2 = $row[9]+$row[10];
    
    if ($side eq 'query'){
        if($en1 > ($length{$id1} || 0)){
            $length{$id1} = $en1;
        }
    }
    if ($side eq 'target'){
        if($en2 > ($length{$id2} || 0)){
            $length{$id2} = $en2;
        }
    }
}
## Rewind
seek $ATAC, 0, 0;
warn scalar keys %length, "\n";





warn "Parsing the range file pass 2/2\n";

my %range_sets;
my $ranges = 0;
my $range_space = 0;

while(<$RANGE>){
    chomp;
    my ($id, $st, $en) = split "\t";
    
    $ranges++;
    
    if(!exists $range_sets{$id}){
        $range_sets{$id} = Set::IntRange->new(1, $length{$id});
    }
    else{
        if($en > $range_sets{$id}->Size){
            die "$id\tfuck off!\n";
            $range_sets{$id}->Resize(1, $en);
        }
    }
    $range_sets{$id}->Interval_Fill($st, $en);
    $range_space += $en-$st+1;
}
warn "loaded $ranges ranges on ", scalar keys %range_sets, " seq-regions\n";

my $range_space_no_overlap;
$range_space_no_overlap += $_->Norm
    for values %range_sets;

warn "range space is $range_space total ($range_space_no_overlap no-overlap) bp\n";





warn "Parsing the atac file pass 2/2\n";

my %atac_sets;
my $atacs = 0;
my $atac_space = 0;

while(<$ATAC>){
    ## Only want to look at match lines of this type
    next unless /$atac_type_pattern/;
    
    chomp;
    my @row = split ' ';
    
    my $id1 = $row[4];
    my $st1 = $row[5]+1;
    my $en1 = $row[5]+$row[6];
    
    my $id2 = $row[8];
    my $st2 = $row[9]+1;
    my $en2 = $row[9]+$row[10];
    
    $atacs++;
    
    if ($side eq 'query'){
        next unless exists $range_sets{$id1};
        if(!exists $atac_sets{$id1}){
            $atac_sets{$id1} = Set::IntRange->new(1, $length{$id1});
        }
        else{
            if($en1 > $atac_sets{$id1}->Size){
                die "FUCK OFF!\n";
                $atac_sets{$id1}->Resize(1, $en1);
            }
        }
        $atac_sets{$id1}->Interval_Fill($st1, $en1);
        $atac_space += $en1-$st1+1;
    }
    
    if ($side eq 'target'){
        next unless exists $range_sets{$id2};
        if(!exists $atac_sets{$id2}){
            $atac_sets{$id2} = Set::IntRange->new(1, $length{$id2});
        }
        else{
            if($en2 > $atac_sets{$id2}->Size){
                die "FUCK FUCK FUCK FUCK OFFF!\n";
                $atac_sets{$id2}->Resize(1, $en2);
            }
        }
        $atac_sets{$id2}->Interval_Fill($st2, $en2);    
        $atac_space += $en2-$st2+1;
    }
    #warn time, ": Done $atacs\n" unless $atacs % 1000;
    #last if $atacs > 200000;
}
warn "loaded $atacs atacs on ", scalar keys %atac_sets, " seq-regions\n";

my $atac_space_no_overlap;
$atac_space_no_overlap += $_->Norm
    for values %atac_sets;

warn "atac space is $atac_space total ($atac_space_no_overlap no-overlap) bp\n";





## What is the range coverage?

my $coverage_sr = 0;
my $coverage_bp = 0;

for my $id (keys %range_sets){
    next unless exists $atac_sets{$id};
    
    $coverage_sr++;
    
    # my ($smallest, $biggest) = sort {$a<=>$b}
    # ($range_sets{$id}->Max, $atac_sets{$id}->Max);
    
    # $range_sets{$id}->Resize(1, $biggest);
    # $atac_sets{$id}->Resize(1, $biggest);
    
    my $intersection = Set::IntRange->new(1, $length{$id});
    
    $intersection->Intersection($range_sets{$id}, $atac_sets{$id});
    
    $coverage_bp += $intersection->Norm;
}

warn "coverage of xxxxx atacs on $coverage_sr seq-regions\n";
warn "coverage (non-overlapping overlap) is ", $coverage_bp, " bp\n";
warn $coverage_bp / $range_space_no_overlap * 100, " of non-overlapping range space\n";


# print
#     join("\t",
#          'range_count',
#          'range_count_seq_region',
#          'range_bp_total',
#          'range_bp_no_overlap',
#          'range_bp_overlap',
         
#          'atac_count',
#          'atac_count_seq_region',
#          'atac_bp_total',
#          'atac_bp_no_overlap',
#          'atac_bp_overlap',
         
#          'coverage_count_seq_region',
#          'coverage_count_seq_region_outside_range',
#          'coverage_count_bp',
#          'perc',
#     ), "\n";
         
print
    join("\t",
         $ranges,
         (scalar keys %range_sets),
         $range_space,
         $range_space_no_overlap,
         $range_space -
         $range_space_no_overlap,

         $atacs,
         (scalar keys %atac_sets),
         $atac_space,
         $atac_space_no_overlap,
         $atac_space -
         $atac_space_no_overlap,
         
         $coverage_sr,
         (scalar keys %atac_sets) - $coverage_sr,
         $coverage_bp,
         
         $coverage_bp / $range_space_no_overlap * 100,
    ), "\n";
