#!/bin/env perl
use 5.14.0;
use warnings;

## Easy manipulation of sets of integers (arbitrary intervals)
use Set::IntRange;

die "pass two range-files\n"
    unless @ARGV == 2;

my ($range_file_1,
    $range_file_2) = @ARGV;

## Parsing both files to get max range size (for efficiency)
warn "Parsing pass 1/2\n";

my %max_range_size =
    get_max_range_size($range_file_1, $range_file_2);



sub get_max_range_size{
    my ($range_file_1, $range_file_2) = @_;

    for my $range_file ($range_file_1, $range_file_2){
        warn "Parsing $range_file\n";

        open( my $RANGE, '<', $range_file )
            or die "Failed to open '$range_file': $!\n";

        while(<$RANGE>){
            chomp;

            my ($id, $range_start, $range_end) = split "\t";

            $length{$id} = $range_end
                if $range_end > ($length{$id} || 0)
            }

    warn scalar keys %max_range_size, "\n";
  }
}



warn "Parsing pass 2/2\n";

my %range_sets;
my %range_space;

for my $range_file ($range_file_1, $range_file_2){
    warn "$range\n";
    
    open( my $RANGE, '<', $range_file )
        or die "Failed to open '$range_file': $!\n";
    
    my $ranges = 0;
    my $range_space = 0;
    
    while(<$RANGE>){
        chomp;
        
        my ($id, $start, $end) = split "\t";
        
        $ranges++;
        $range_space += $end-$start+1;
    
        $range_sets{$range}{$id} = Set::IntRange->new(1, $max_range_size{$id})
            unless exists $range_sets{$range}{$id};
        $range_sets{$range}{$id}->Interval_Fill($start, $end);
    }
    
    warn "loaded $ranges ranges on ",
    scalar keys %{$range_sets{$range}}, " seq-regions\n";
    
    my $range_space_no_overlap;
    $range_space_no_overlap += $_->Norm
        for values %{$range_sets{$range}};
    
    warn "range space is $range_space total ".
        "($range_space_no_overlap no-overlap) bp\n";
    
    ## Hide this value away...
    $range_space{$range} = $range_space_no_overlap;
}



## What is the range-range coverage?

my $coverage_sr = 0;
my $coverage_bp = 0;

for my $id (keys %{$range_sets{$range_file_1}}){
    next unless exists $range_sets{$range_file_2}{$id};
    
    $coverage_sr++;
    
    my $intersection = Set::IntRange->new(1, $max_range_size{$id});
    
    $intersection->Intersection($range_sets{$range_file_1}{$id},
                                $range_sets{$range_file_2}{$id});
    
    $coverage_bp += $intersection->Norm;
}

warn "coverage of xxxxx ranges on $coverage_sr seq-regions\n";
warn "coverage (non-overlapping overlap) is ", $coverage_bp, " bp\n";

warn $coverage_bp / $range_space{$range_file_1} * 100,
    " of non-overlapping range space\n";
warn $coverage_bp / $range_space{$range_file_2} * 100,
    " of non-overlapping range space\n";

print
    join("\t",
         (scalar keys %{$range_sets{$range_file_1}}),
         $range_space{$range_file_1},
         
         (scalar keys %{$range_sets{$range_file_2}}),
         $range_space{$range_file_2},

         $coverage_sr,
         $coverage_bp,
         
         $coverage_bp / $range_space{$range_file_1} * 100,
         $coverage_bp / $range_space{$range_file_2} * 100,
         
         $range_file_1,
         $range_file_2,
    ), "\n";


## Subroutines
sub check_files{
    ...
}

__END__

##  Basically the
## 'set resize' operations are relatively costly, so by finding the
## maximum set size required per ID up front, we save a lot of work
## later...
