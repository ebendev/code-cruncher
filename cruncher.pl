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

print "CodeCruncher v0\n";

while(<INPUT>) {
  s/^\s+//;
  s/\s+$//;
  print OUTPUT $_;
}

close INPUT;
close OUTPUT;
close LOG;