#!perl -w
use strict;

print "CodeCruncher v0\n\n";

open INPUT, "< $ARGV[0]";
open OUTPUT, "> $ARGV[1]";
open LOG, "> $ARGV[2]";




close INPUT;
close OUTPUT;
close LOG;