#!perl -w
use strict;

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

my @dependency;
my $filestring = "";

print "===> CodeCruncher Copyright 2007 Eben Geer <===============================\n";

print "\n===> Original File - Start <===============================================\n";
while(<INPUT>) { $filestring .= $_; }
print $filestring;
print "\n===> Original File - End <=================================================\n";

print "\n===> Leading and trailing whitespace: Removing... <========================\n";
while(<INPUT>) {
  s/^\s+//;
  s/\s+$//;
  print $_;
}
print "\n===> Leading and trailing whitespace: Removed! <===========================\n";

print "\n===> Comments: Removing... <===============================================\n";
while(<INPUT>) {
  s/<!--.*//;
  s/.*-->//;
  print $_;
}
print "\n===> Comments: Removed! <==================================================\n";

print "\n===> Writing output file... <==============================================\n";
while(<INPUT>) {
  print OUTPUT $_;
}
print "\n===> Output file written! <================================================\n";

close INPUT;
close OUTPUT;
close LOG;