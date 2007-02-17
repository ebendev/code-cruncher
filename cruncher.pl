#!perl -w
use strict;
use FileHandle;

{
  my $errstr = "file not specified.  Correct form is:\n\$ cruncher.pl [input] [output] [optional_logfile]\n";
  die "Input $errstr" if @ARGV < 1;
  die "Output $errstr" if @ARGV < 2;
}

open INPUT, "< $ARGV[0]"
     or die "$ARGV[0] - $!\n";
open OUTPUT, "> $ARGV[1]"
     or die "$ARGV[1] - $!\n";
if($ARGV[2]) {
  open LOG, "> $ARGV[2]";
  select LOG;
}

my @filenames;
my @filestrings;

my $inputpath;
my $outputpath;

# do i need additional logic if ..\ prepends the individual file names?

while($ARGV[0] =~ m"((.*\\)+)"g) {
  $inputpath = $1;
}

while($ARGV[1] =~ m"((.*\\)+)"g) {
  $outputpath = $1;
}

unless(defined($inputpath)) { $inputpath = ""; }
unless(defined($outputpath)) { $outputpath = ""; }

while($ARGV[1] =~ m"(.*\\)*(.+)"g) {
  $filenames[0] = $2;
}

print "===> CodeCruncher Copyright 2007 Eben Geer <===============================\n";
print "===> Input path: '$inputpath' <===\n";
print "===> Output path: '$outputpath' <===\n";

print "\n===> Original File: $inputpath$filenames[0] - Start <===\n";
while(<INPUT>) { $filestrings[0] .= $_; }
print $filestrings[0];
print "\n===> Original File: $inputpath$filenames[0] - End <===\n";

# search for external files only goes one level deep

print "\n===> External source files (.js): Identifying... <=========================\n";
while($filestrings[0] =~ m/src="(.*\.js)"/sg) {
  $filenames[@filenames] = $1;
  print "$inputpath$filenames[@filenames - 1]\n";
}
print "\n===> External source files (.js): Identified! <============================\n";

print "\n===> External source files (.css): Identifying... <========================\n";
while($filestrings[0] =~ m/url\((.*\.css)\)/sg) {
  $filenames[@filenames] = $1;
  print "$inputpath$filenames[@filenames - 1]\n";
}
print "\n===> External source files (.css): Identified! <===========================\n";

print "\n===> External source files: Opening... <===================================\n";
for(my $i = 1; $i < @filenames; $i++) {
  my $fh = new FileHandle("< $inputpath$filenames[$i]");
  $filestrings[$i] = "";
  while(<$fh>) { $filestrings[$i] .= $_; }
  print "$inputpath$filenames[$i]\n";
}
print "\n===> (" . scalar @filestrings - 1 . ") External source files: Opened! <==================================\n";

for(my $i = 1; $i < @filenames; $i++) {
  print "\n===> External Source File: $inputpath$filenames[$i] - Start <===\n";
  print $filestrings[$i];
  print "\n===> External Source File: $inputpath$filenames[$i] - End <===\n";
}

#my $test = "silly people do silly things if in silly moods";
#if($test =~ m/(silly(.*?)moods)/) { print "$1\n"; }

print "\n===> Comments: Extracting... <=============================================\n";
for(my $i = 0; $i < @filestrings; $i++) {
  print "[$filenames[$i]]\n";
  while($filestrings[$i] =~ s/(<!--.*?-->)//s) {
    print "$1\n";
  }
}
print "\n===> Comments: Extracted! <================================================\n";

print "\n===> Output files: Writing... <============================================\n";
for(my $i = 0; $i < @filenames; $i++) {
  print "$outputpath$filenames[$i]\n";
  open EXTERNAL, "> $outputpath$filenames[$i]" or die "$outputpath$filenames[$i] - $!\n";
  print EXTERNAL $filestrings[$i];
  close EXTERNAL;
}
print "\n===> Output files: Written! <==============================================\n";

close INPUT;
close OUTPUT;
close LOG;