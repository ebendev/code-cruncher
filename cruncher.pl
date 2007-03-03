#!perl -w

### Pragmas ######################
use strict;
#use FileHandle;


### Globals ######################
 # Path strings
#my $inputAbsPath;
#my $outputAbsPath;
#my $indexRelPath;
#my $testRelPath;
#
#my @names; # all identifiers in the general namespace: functions, variables, ids
##my @avoid = qw(rows HistoryDiv); # list of strings not to crunch
#my @avoid = qw(); # list of strings not to crunch
#
# # Source files
#my @filenames;
#my @filestrings;
#
# # Test module
#my $teststring;


### Subroutines ######################

##a b c d e f g h i j  k  l  m  n  o  p  q  r  s  t  u  v  w  x  y  z
##0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
#sub alphabase {
#  use integer;
#  my($num) = @_;
#  if($num / 26) { return alphabase($num / 26) . alphabase($num % 26); }
#  else { return chr(97 + $num % 26); }
#}
#
#sub isKeyword {
#  my ($str) = @_;
#
#  return 1 if isCollision($str);
#
#  if($str eq "do") { return 1; }
#  elsif($str eq "if") { return 1; }
#  elsif($str eq "for") { return 1; }
#  else { return 0; }
#}
#
#sub isCollision {
#  my ($str) = @_;
#
#  foreach my $el (@names) {
#    return 1 if $str eq $el;
#  }
#}
#
#sub isAvoid {
#  my ($str) = @_;
#
#  foreach my $el (@avoid) {
#    return 1 if $str eq $el;
#  }
#}

# Command line variables
my $crunchNames = 1; # default On
my $crunchWS = 0; # default Off
my $warningsOn = 1; # default On

my $rootPath;
my @updatePaths;
my $logPath;
my $profilePath;

### -> Script Execution Entry Point <- #################################################################################
### Process command line options #################################################################################################
## -ws            crunch whitespace
## --ws-only      crunch only whitespace
## --no-warnings  crunch without asking for user approval
## -root:path     specify path to index.html or equivalent starting point (only one root may be given)
## -update:path   specify path to any unconnected, but dependent modules, like tests, that need to have the updated names
## -log:path      specify the path to the log file (default is log.html in current working directory)
## -profile:path  specify the path to a config file which holds the command line options desired (any given command line options
##                  will override those found in the profile
##################################################################################################################################

# Load profile, if present

print "\n";
#print @ARGV;
#print "\n\n";

foreach my $el (@ARGV) {
  if($el =~ /-ws(?!.)/) { $crunchWS = 1; }
  elsif($el =~ /--ws-only/) { $crunchWS = 1; $crunchNames = 0; }
  elsif($el =~ /--no-warnings/) { $warningsOn = 0; }
  elsif($el =~ /-root:(.+)/) {
    if(defined($rootPath)) { print "$el ignored. You may only specify one root.\n"; }
    else { $rootPath = $1; }
  }
  elsif($el =~ /-update:(.+)/) { $updatePaths[@updatePaths] = $1; }
  elsif($el =~ /-log:(.+)/) {
    if(defined($logPath)) { print "$el ignored. You may only specify one log file.\n"; }
    else { $logPath = $1; }
  }
  elsif($el =~ /-profile:(.+)/) {
    if(defined($profilePath)) { print "$el ignored. You may only specify one profile.\n"; }
    else { $profilePath = $1; }
  }
  else { print "'$el' ignored. Unrecognized option.\n"; }
}
print "\n";
if(!defined($logPath)) { $logPath = "log.html"; }

if(@ARGV < 1 or !defined($rootPath)) {
  print "\nRoot page not specified.  Correct form is:\n\$ cruncher.pl -root:path/to/index.html/or/equivalent\n";
  exit 1;
}

print "crunchNames = $crunchNames\n";
print "crunchWS = $crunchWS\n";
print "warningsOn = $warningsOn\n";
if(defined($rootPath)) { print "rootPath = $rootPath\n"; }
if(@updatePaths > 0) {
  print "updatePaths = ";
  print @updatePaths;
  print "\n";
}
if(defined($logPath)) { print "logPath = $logPath\n"; }
if(defined($profilePath)) { print "profilePath = $profilePath\n"; }

print "\n";

### Load Config #################
#{
#  die "Config file not specified.  Correct form is:\n\$ cruncher.pl [config_file] [optional_log_file]\n" if @ARGV < 1;
#  open CONFIG, "< $ARGV[0]" or die "$ARGV[0] - $!\n";
#
#  my $configstring;
#  while(<CONFIG>) { $configstring .= $_; }
#
#  ($inputAbsPath)  = ($configstring =~ m/abs_path = "(.+)";/);
#  ($outputAbsPath) = ($configstring =~ m/abs_out_path = "(.+)";/);
#  ($indexRelPath)  = ($configstring =~ m/index = "(.+)";/);
#  ($testRelPath)  = ($configstring =~ m/test = "(.+)";/);
#
#  close CONFIG;
#}
#
#### Open files: INPUT, LOG ###########
#open INPUT, "< $inputAbsPath$indexRelPath" or die "$inputAbsPath$indexRelPath - $!\n";
#if($ARGV[1]) {
#  open LOG, "> $ARGV[1]";
#  select LOG;
#}
#
#
##{
##  my $errstr = "file not specified.  Correct form is:\n\$ cruncher.pl [input] [output] [optional_logfile] [optional_test_module]\n";
##  die "Input $errstr" if @ARGV < 1;
##  die "Output $errstr" if @ARGV < 2;
##}
#
##open INPUT, "< $ARGV[0]"
##     or die "$ARGV[0] - $!\n";
##open OUTPUT, "> $ARGV[1]"
##     or die "$ARGV[1] - $!\n";
##if($ARGV[2]) {
##  open LOG, "> $ARGV[2]";
##  select LOG;
##}
##if($ARGV[3]) {
##  open TESTS, "< $ARGV[3]";
##}
#
##my @filenames;
##my @filestrings;
#
##my $teststring;
##my $testfile;
#
## do i need additional logic if ..\ prepends the individual file names?
#
##while($ARGV[0] =~ m"((.*\\)+)"g) {
##  $inputpath = $1;
##}
#
##while($ARGV[1] =~ m"((.*\\)+)"g) {
##  $outputpath = $1;
##}
##if(defined($ARGV[3])) {
##  if(index($inputpath, $ARGV[3]) == 0) {
##    $testspath = substr($ARGV[3], length($inputpath));
##    print index($inputpath, $ARGV[3]);
##  }
#
#  #$ARGV[3] =~ s/($inputpath)//;
#  #$testspath = $ARGV[3];
##}
#
#unless(defined($inputAbsPath)) { $inputAbsPath = ""; }
#unless(defined($outputAbsPath)) { $outputAbsPath = ""; }
#unless(defined($testRelPath)) { $testRelPath = ""; }
#
##while($ARGV[1] =~ m"(.*\\)*(.+)"g) {
##  $filenames[0] = $2;
##}
#
#print "===> CodeCruncher Copyright 2007 Eben Geer <===============================\n";
#print "===> Input path: '$inputAbsPath' <===\n";
#print "===> Output path: '$outputAbsPath' <===\n";
##if(defined($ARGV[3])) {
##  print "===> Test module path: '$testRelPath' <===\n";
##}
#
#$filenames[0] = $indexRelPath;
#print "\n===> Original File: $inputAbsPath$filenames[0] - Start <===\n";
#while(<INPUT>) { $filestrings[0] .= $_; }
#print $filestrings[0];
#print "\n===> Original File: $inputAbsPath$filenames[0] - End <===\n";
#
## search for external files only goes one level deep
#
#print "\n===> External source files (.js): Identifying... <=========================\n";
#while($filestrings[0] =~ m/src="(.*\.js)"/g) {
#  $filenames[@filenames] = $1;
#  print "$inputAbsPath$filenames[@filenames - 1]\n";
#}
#print "\n===> External source files (.js): Identified! <============================\n";
#print "\n===> External source files (.css): Identifying... <========================\n";
#while($filestrings[0] =~ m/url\((.*\.css)\)/g) {
#  $filenames[@filenames] = $1;
#  print "$inputAbsPath$filenames[@filenames - 1]\n";
#}
#print "\n===> External source files (.css): Identified! <===========================\n";
#print "\n===> External source files: Opening... <===================================\n";
#for(my $i = 1; $i < @filenames; $i++) {
#  my $fh = new FileHandle("< $inputAbsPath$filenames[$i]");
#  $filestrings[$i] = "";
#  while(<$fh>) { $filestrings[$i] .= $_; }
#  print "$inputAbsPath$filenames[$i]\n";
#}
#print "\n===> (" . scalar @filestrings - 1 . ") External source files: Opened! <==================================\n";
#
#for(my $i = 1; $i < @filenames; $i++) {
#  print "\n===> External Source File: $inputAbsPath$filenames[$i] - Start <===\n";
#  print $filestrings[$i];
#  print "\n===> External Source File: $inputAbsPath$filenames[$i] - End <===\n";
#}
#
#print "\n===> Comments: Extracting... <=============================================\n";
#for(my $i = 0; $i < @filestrings; $i++) {
#  print "[$filenames[$i]]\n";
#
#  # HTML-style comments <!-- -->
#  while($filestrings[$i] =~ s/(<!--(?!.{1,10}import).*?-->)//s) { print "$1\n"; }
#
#  # C-style block comments /* */
#  while($filestrings[$i] =~ s"(/\*.*?\*/)""s) { print "$1\n"; }
#
#  # C++ style single-line comments // - and then ;//
#  while($filestrings[$i] =~ s"(^//.*)"") { print "$1\n"; }
#  while($filestrings[$i] =~ s"(\s//.*)"") { print "$1\n"; }
#  while($filestrings[$i] =~ s";(//.*)";") { print "$1\n"; }
#}
#print "\n===> Comments: Extracted! <================================================\n";
#print "\n===> Functions, Variables, and ID's: Identifying... <======================\n";
#for(my $i = 0; $i < @filestrings; $i++) {
#  print "[$filenames[$i]]\n";
#  while($filestrings[$i] =~ m/var\s+(\w+)/g) {
#    #if($1 ne "rows") { $names[@names] = $1; }
#    #$names[@names] = $1;
#    $names[@names] = $1 unless(isAvoid($1));
#    print "Identified Variable: '$names[@names - 1]'\n";
#  }
#}
#for(my $i = 0; $i < @filestrings; $i++) {
#  print "[$filenames[$i]]\n";
#  while($filestrings[$i] =~ m/function\s+(\w+)\s*\(/g) {
#    $names[@names] = $1 unless(isAvoid($1));
#    print "Identified Function: '$names[@names - 1]'\n";
#  }
#}
#for(my $i = 0; $i < @filestrings; $i++) {
#  print "[$filenames[$i]]\n";
#  while($filestrings[$i] =~ m/id="(\w+)"/g) {
#    $names[@names] = $1 unless(isAvoid($1));
#    print "Identified ID: '$names[@names - 1]'\n";
#  }
#}
#for(my $i = 0; $i < @filestrings; $i++) {
#  print "[$filenames[$i]]\n";
#  while($filestrings[$i] =~ m/(?<!meta )name="(\w+)"/g) {
#    $names[@names] = $1 unless(isAvoid($1));
#    print "Identified ID: '$names[@names - 1]'\n";
#  }
#}
#print "\n===> Functions, Variables, and ID's: Identified! <=========================\n";
#print "\n===> Functions, Variables, and ID's: Renaming... <=========================\n";
#my @abbr;
#my $n = @names;
#my $offset = 0;
#for(my $k = 0; $k < $n; $k++) {
#  while(isKeyword($abbr[$k] = alphabase($k + $offset))) {
#    $offset++;
#  }
#}
#for(my $j = 0; $j < @names; $j++) {
#  for(my $i = 0; $i < @filestrings; $i++) {
#    #$filestrings[$i] =~ s/(?<![^\s\-\+\*\/=])($names[$j])(?![^\s\-\+\*\/=])/$abbr[$j]/g;
#    #$filestrings[$i] =~ s/(?<=[\s\-\+\*\/\=\;\(\[\.\,])($names[$j])(?=[\s\-\+\*\/\=\;\(\)\]\.\,])/$abbr[$j]/g;
#    #$filestrings[$i] =~ s/(?<![\w<\.])($names[$j])(?![\w>])/$abbr[$j]/g;
#    #$filestrings[$i] =~ s/(?<![\w<\.])($names[$j])(?! ?[\w])/$abbr[$j]/g;
#    #$filestrings[$i] =~ s/(?<![\w<\.])($names[$j])(?! ?[\w])(?![>])/$abbr[$j]/g;
#    #$filestrings[$i] =~ s/(?<![\w'<])($names[$j])(?! ?[\w'])(?![>])/$abbr[$j]/g;
#    $filestrings[$i] =~ s/(?<![\w<])(?<!== ')($names[$j])(?! ?[\w])(?![>])/$abbr[$j]/g;
#  }
#  print "'$abbr[$j]' substituted for '$names[$j]'\n";
#}
#print "\n===> Functions, Variables, and ID's: Renamed! <============================\n";
#
#for(my $i = 0; $i < @filenames; $i++) {
#  print "\n===> Source File Before Whitespace Removal: $inputAbsPath$filenames[$i] - Start <===\n";
#  print $filestrings[$i];
#  print "\n===> Source File Before Whitespace Removal: $inputAbsPath$filenames[$i] - End <===\n";
#}
#
#if(0) {
#print "\n===> Whitespace: Extracting... <===========================================\n";
#for(my $i = 0; $i < @filestrings; $i++) {
#  # = + -
#  $filestrings[$i] =~ s/(?<!')\s*=\s*(?!')/=/g;
#  $filestrings[$i] =~ s/(?<!')\s*\+\s*(?!')/\+/g;
#  $filestrings[$i] =~ s/(?<!')\s*-\s*(?!')/-/g;
#
#  # < > || &&
#  $filestrings[$i] =~ s/\s*<\s*/</g;
#  $filestrings[$i] =~ s/\s*>\s*/>/g;
#  $filestrings[$i] =~ s/\s*\|\|\s*/\|\|/g;
#  $filestrings[$i] =~ s/\s*\&\&\s*/\&\&/g;
#
#  # ( ) { }
#  $filestrings[$i] =~ s/\s*\(\s*/\(/g;
#  $filestrings[$i] =~ s/\s*\)\s*/\)/g;
#  $filestrings[$i] =~ s/\s*\{\s*/\{/g;
#  $filestrings[$i] =~ s/\s*\}\s*/\}/g;
#
#  # leading and trailing whitespace
#  $filestrings[$i] =~ s/;\s+/;/g;
#  $filestrings[$i] =~ s/\n\s*//g;
#
#  print "[$filenames[$i]]\n";
#  print "$filestrings[$i]\n";
#}
#}
#print "\n===> Whitespace: Extracted! <==============================================\n";
#print "\n===> Output files: Writing... <============================================\n";
#for(my $i = 0; $i < @filenames; $i++) {
#  print "$outputAbsPath$filenames[$i]\n";
#  open EXTERNAL, "> $outputAbsPath$filenames[$i]" or die "$outputAbsPath$filenames[$i] - $!\n";
#  print EXTERNAL $filestrings[$i];
#  close EXTERNAL;
#}
#print "\n===> Output files: Written! <==============================================\n";
#
##if(defined($ARGV[3])) {
#  print "\n===> Test Module: Updating... <============================================\n";
#  open TESTIN, "< $inputAbsPath$testRelPath" or die "$inputAbsPath$testRelPath - $!\n";
#  while(<TESTIN>) { $teststring .= $_; }
#  close TESTIN;
#  for(my $j = 0; $j < @names; $j++) {
#    $teststring =~ s/(?<![\w"<])($names[$j])(?! ?[\w"])(?![>])/$abbr[$j]/g;
#    print "'$abbr[$j]' substituted for '$names[$j]'\n";
#  }
#  open TESTOUT, "> $outputAbsPath$testRelPath" or die "$outputAbsPath$testRelPath - $!\n";
#  print TESTOUT $teststring;
#  close TESTOUT;
#  print "\n===> Test Module: Updated! <===============================================\n";
##}
#
#print "\n===> CodeCruncher Finished! <==============================================\n";
#
#close INPUT;
##close OUTPUT;
#close LOG;
#
#
#
