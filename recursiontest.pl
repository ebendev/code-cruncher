#!perl
use strict;

sub alphabase {
  use integer;
  my($num) = @_;
  if($num / 26) { return alphabase($num / 26) . alphabase($num % 26); }
  else { return chr(97 + $num % 26); }
}

print "$ARGV[0] = " . &alphabase($ARGV[0]) . "\n";

#my $temp;
#for(my $i = 0; $i <= $ARGV[0]; $i++) {
#  $temp = &abbrmaker($i);
#  print "$i = $temp\n";
#}