#!perl -w

### Pragmas ######################
use strict;
use FileHandle;
use Cwd;


### Globals ######################
 # Path strings
my $inputPath;
my $outputPath;

my @names; # all identifiers in the general namespace: functions, variables, ids
#my @avoid = qw(rows HistoryDiv); # list of strings not to crunch
my @avoid = qw(); # list of strings not to crunch

 # Source files
my @filenames;
my @filestrings;

 # Test module
my $teststring;

# Command line variables
my $crunchNames = 1; # default ON
my $crunchWS = 0; # default off
my $warningsOn = 1; # default ON
my $verbose = 0; # default off
my $append = 0; # default off

my $rootPath;
#my $outputPath;
my @updatePaths;
my $logPath;
my $profilePath;
my $log;


### Subroutines ######################
sub printBreak {
  my ($str) = @_;
  my $i = 0;
  if($verbose) {
    print "===> $str <===";
    print "=" while($i++ < 69 - length $str);
    print "\n";
  }
#  $i = 0;
#  if(defined $log) {
#    print $log "===> $str <===";
#    print $log "=" while($i++ < 69 - length $str);
#    print $log "\n";
#  }
  if(defined $log) {
    print $log "</table>\n<table>\n";
    print $log "<caption>$str</caption>\n";
  }
}
sub printOut {
  my ($str) = @_;
  if($verbose) { print $str; }
  if(defined $log) {
    $str =~ s/</&lt;/g;
    $str =~ s/>/&gt;/g;
    #$str =~ s/\n//g;

    print $log "<tr><td><pre>$str</pre></td></tr>\n";
  }
}

#a b c d e f g h i j  k  l  m  n  o  p  q  r  s  t  u  v  w  x  y  z
#0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
sub alphabase {
  use integer;
  my($num) = @_;
  if($num / 26) { return alphabase($num / 26) . alphabase($num % 26); }
  else { return chr(97 + $num % 26); }
}

sub isKeyword {
  my ($str) = @_;

  return 1 if isCollision($str);

  if($str eq "do") { return 1; }
  elsif($str eq "if") { return 1; }
  elsif($str eq "for") { return 1; }
  else { return 0; }
}

sub isCollision {
  my ($str) = @_;

  foreach my $el (@names) {
    return 1 if $str eq $el;
  }
}

sub isAvoid {
  my ($str) = @_;

  foreach my $el (@avoid) {
    return 1 if $str eq $el;
  }
}


### -> Script Execution Entry Point <- #################################################################################
### Process command line options #################################################################################################
## -ws            crunch whitespace
## --ws-only      crunch only whitespace
## --no-warnings  crunch without asking for user approval
## -verbose       (deprecated) output log info to screen
## --append-log   append to the log file, instead of replacing it
## -root:path     specify path to index.html or equivalent starting point (only one root may be given)
## -output:path   specify path to the output root (only one output root may be given)
## -update:path   specify path (relative to root) to any unconnected, but dependent modules, like tests, that need to have the updated names
## -log:path      specify the path to the log file (default is log.html in current working directory)
## -profile:path  specify the path to a config file which holds the command line options desired (any given command line options
##                  will override those found in the profile
##################################################################################################################################

# Load profile, if present
#load into @argv


my $dir = getcwd;
#print $dir;
print "\n";

foreach my $el (@ARGV) {
  if($el =~ /-ws(?!.)/) { $crunchWS = 1; }
  elsif($el =~ /--ws-only/) { $crunchWS = 1; $crunchNames = 0; }
  elsif($el =~ /--no-warnings/) { $warningsOn = 0; }
  #elsif($el =~ /-verbose/) { $verbose = 1; }
  elsif($el =~ /--append-log/) { $append = 1; }
  elsif($el =~ /-root:(.+)/) {
    if(defined($rootPath)) { print "$el ignored. You may only specify one root.\n"; }
    else { $rootPath = $1; }
  }
  elsif($el =~ /-output:(.+)/) {
    if(defined($outputPath)) { print "$el ignored. You may only specify one output root.\n"; }
    else { $outputPath = $1; }
  }
  elsif($el =~ /-update:(.+)/) { $updatePaths[@updatePaths] = $1; }
  elsif($el =~ /-log:(.+)/) {
    if(defined($logPath)) { print "$el ignored. You may only specify one log file.\n"; }
    else { $logPath = $1; }
  }
  elsif($el =~ /-profile:(.+)/) {
    if(defined($profilePath)) { print "$el ignored. You may only specify one profile.\n"; }
    else {
      print "Profile option not yet supported.\n";
      #$profilePath = $1;
    }
  }
  else { print "'$el' ignored. Unrecognized option.\n"; }
}
print "\n";

#my $fh;
#
#if(defined($profilePath)) {
#  $fh = new FileHandle("< $profilePath");
#  if(!defined($fh)) { print "Could not open specified profile: $profilePath. Ignoring...\n"; }
#  else { print "Opened profile: $profilePath\n"; }
#}
#
#if(defined($fh)) {
#  print "Additional command line options: \n";
#
#  my $profileStr = "";
#  while(<$fh>) { $profileStr .= $_; }
#
#
#  print $profileStr;
#  print "\n\n";
#  undef $fh; # automatically closes the file
#}

$rootPath =~ s/\\/\//g;
if(!defined($logPath)) { $logPath = "log.html"; }

if(@ARGV < 1 or !defined($rootPath)) {
  print "\nRoot page not specified.  Correct form must include:\n\$ cruncher.pl -root:path/to/index.html/or/equivalent\n";
  exit 1;
}

#print "crunchNames = $crunchNames\n";
#print "crunchWS = $crunchWS\n";
#print "warningsOn = $warningsOn\n";
#print "verbose = $verbose\n";
#if(defined($rootPath)) { print "rootPath = $rootPath\n"; }
#if(defined($outputPath)) { print "outputPath = $outputPath\n"; }
#if(@updatePaths > 0) {
#  print "updatePaths = ";
#  print @updatePaths;
#  print "\n";
#}
#if(defined($logPath)) { print "logPath = $logPath\n"; }
#if(defined($profilePath)) { print "profilePath = $profilePath\n"; }

print "\n";


# Open root
#my $rootStr;
{
  $rootPath =~ s/\\/\//g;
  my $fh = new FileHandle "< $rootPath";
  if(!defined($fh)) {
    print "Could not open root page: '$rootPath'\n\nExiting...\n\n";
    exit 1;
  }
  #while(<$fh>) { $rootStr .= $_; }
  while(<$fh>) { $filestrings[0] .= $_; }
}

# Open Log
{
  if($append) { $log = new FileHandle ">>$logPath"; }
  else { $log = new FileHandle "> $logPath"; }
  if(!defined($log)) {
#    print "Could not open log file for writing.\nSwitching to verbose mode.\n\n";
#    $verbose = 1;
    print "Could not open log file for writing.\nExiting...\n\n";
    exit 1;
  }
  else { select $log; }
}

# Isolate relative input path, filename
if($rootPath =~ /([^\/]+)$/) {
  $filenames[0] = $1;
  if($rootPath =~ /(.*\/?)$filenames[0]/) {
    $inputPath = $1;
  }
}
if(!defined($outputPath)) { $outputPath = $inputPath; }


print STDOUT "Please wait while code is crunched.\n\n" if $crunchNames;
print STDOUT "Please wait while whitespace is crunched.\n\n" if($crunchWS && !$crunchNames);

#####################################
## Start Meaningful HTML Logging
#####################################
print '<?xml version="1.0" encoding="UTF-8"?>', "\n";
print '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN""http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">', "\n";
print '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">', "\n";
print "<head>\n<title>Cruncher Log</title>\n";

print "<style>\n";
print 'body { font: 75%/1.6 "Myriad Pro", Frutiger, "Lucida Grande", "Lucida Sans", "Lucida Sans Unicode", Verdana, sans-serif; }';
#print 'body { font: 10pt "Courier New", monospace; }';
print 'table { border-collapse: collapse; width: 85em; border: 1px solid #666; }';
print 'caption { font-size: 1.2em; font-weight: bold; margin: 1em 0; }';
print 'col { border-right: 1px solid #ccc; }';
#print 'thead { background: #ccc url(images/bar.gif) repeat-x left center; border-top: 1px solid #a5a5a5; border-bottom: 1px solid #a5a5a5; }';
print 'th { background: #bbb; font-weight: normal; text-align: left; }';
print 'th, td { padding: 0.1em 1em; }';
print 'td { font: 10pt "Courier New", monospace; }';
print 'tr:hover { background-color: #3d80df; color: #fff; }';
print 'thead tr:hover { background-color: transparent; color: inherit; }';
#  print $log '.even {
#  background-color: #edf5ff;
#}
#
#.odd {
#  background-color: inherit;
#}
#
#.pass {
#  border: none;
#  font-weight: bold;
#  color: green;
#}
#
#.pass:hover {
#  color: white;
#}
#
#.fail {
#  border: none;
#  font-weight: bold;
#  color: red;
#}
#
#.fail:hover {
#  color: white;
#}
#
#.inputcell {
#  font-weight: bold;
#  border-bottom: solid black 1px;
#  border-top: solid black 1px;
#  border-right: solid black 1px;
#  border-left: solid black 1px;
#}';
#
print "\n</style>\n<script>\n";
print '';

print "\n</script>\n</head>\n<body>\n";

#sub printHeading {
#  my ($str, $type) = @_;
#  print "
#}

#printHeading("CodeCruncher Copyright 2007 Eben Geer", 1);
#printHeading("Input Path: $inputPath", 2);

#printBreak("CodeCruncher Copyright 2007 Eben Geer");
#printBreak("Input Path: $inputPath");

print "<h1>CodeCruncher &copy; 2007 Eben Geer</h1>\n";
print "<h2>Input Path: $inputPath</h2>\n";



# search for external files only goes one level deep

sub cleanHTML {
  (my $str) = @_;
  $str =~ s/</&lt;/g;
  $str =~ s/>/&gt;/g;
  $str =~ s/\n//g;
  $str;
}

### Identify JavaScript source files ###
print "<table>\n";
print "<caption>External source files (.js)</caption>\n";
print "<tr><th>File</th><th>From Source Line</th></tr>\n";

while($filestrings[0] =~ m/\n?(.*src="(.*\.js).*)/g) {
  my $line = cleanHTML($1);
  my $fname = $2;
  $filenames[@filenames] = $fname;

  $line =~ s/$fname/<strong>$fname<\/strong>/g;
  print "<tr><td>$fname</td><td>$line</td></tr>\n";
  print STDOUT ".";
}
print "</table>\n\n";

sub printTableHead {
  my ($caption) = shift @_;
  print "<table>\n";
  print "<caption>$caption</caption>\n";
  print '<tr>';
  print "<th>$_</th>" for @_;
  print "</tr>\n";
}

sub printTableRow {
  print '<tr>';
  print "<td>$_</td>" for @_;
  print "</tr>\n";
}

sub printTableFoot {
  print "</table>\n\n";
}

### Identify CSS source files ###
printTableHead("External source files (.css)", "File", "From Source Line");
while($filestrings[0] =~ m/\n?(.*url\((.*\.css)\).*)/g) {
  my $line = cleanHTML($1);
  my $fname = $2;
  $filenames[@filenames] = $fname;

  $line =~ s/$fname/<strong>$fname<\/strong>/g;
  printTableRow($fname, $line);
  print STDOUT ".";
}
printTableFoot;

#printBreak("External source files: Opening...");
#for(my $i = 1; $i < @filenames; $i++) {
#  my $fh = new FileHandle("< $inputPath$filenames[$i]");
#  while(<$fh>) { $filestrings[$i] .= $_; }
#  printOut("$filenames[$i]\n");
#  if(!$verbose) { print "."; }
#}
#printBreak("(" . scalar @filestrings - 1 . ") External source files: Opened!");
#
#### Crunch Names #########################################################################
#if($crunchNames) {
#
#for(my $i = 0; $i < @filenames; $i++) {
#  printBreak("External Source File: $filenames[$i] - Start");
#  printOut($filestrings[$i]);
#  printBreak("External Source File: $filenames[$i] - End");
#  if(!$verbose) { print "."; }
#}
#
#printBreak("Comments: Extracting...");
#for(my $i = 0; $i < @filestrings; $i++) {
#  printOut("[$filenames[$i]]\n");
#
#  # HTML-style comments <!-- -->
#  while($filestrings[$i] =~ s/(<!--(?!.{1,10}import).*?-->)//s) { printOut("$1\n"); }
#
#  # C-style block comments /* */
#  while($filestrings[$i] =~ s"(/\*.*?\*/)""s) { printOut("$1\n"); }
#
#  # C++ style single-line comments // - and then ;//
#  while($filestrings[$i] =~ s"(^//.*)"") { printOut("$1\n"); }
#  while($filestrings[$i] =~ s"(\s//.*)"") { printOut("$1\n"); }
#  while($filestrings[$i] =~ s";(//.*)";") { printOut("$1\n"); }
#  
#  if(!$verbose) { print "."; }
#}
#printBreak("Comments: Extracted!");
#
#printBreak("Functions, Variables, and ID's: Identifying...");
#
#sub identifyNames {
#  my ($type, $re) = @_;
#  for(my $i = 0; $i < @filestrings; $i++) {
#    printOut("[$filenames[$i]]\n");
#    while($filestrings[$i] =~ m/$re/g) {
#      if(isAvoid($2)) { printOut("Avoided: '$2' [FROM LINE ->] $1\n"); }
#      elsif(isCollision($2)) { printOut("Ignored Repeat: '$2' [FROM LINE ->] $1\n"); }
#      else {
#        $names[@names] = $2;
#        printOut("Identified $type: '$2' [FROM LINE ->] $1\n");
#      }
#      if(!$verbose) { print "."; }
#    }
#  }
#}
#
#identifyNames("Variable", '\n?(.*var\s+(\w+).*)');
#identifyNames("Function", '\n?(.*function\s+(\w+)\s*\(.*)');
#identifyNames("ID", '\n?(.*id="(\w+)".*)');
#identifyNames("Name", '\n?(.*(?<!meta )name="(\w+)".*)');
#
#printBreak("Functions, Variables, and ID's: Identified!");
#
#printBreak("Functions, Variables, and ID's: Renaming...");
#my @abbr;
#my $n = @names;
#my $offset = 0;
#for(my $k = 0; $k < $n; $k++) {
#  while(isKeyword($abbr[$k] = alphabase($k + $offset))) {
#    $offset++;
#  }
#  if(!$verbose) { print "."; }
#}
#
#### Substitute crunched names ###
#for(my $j = 0; $j < @names; $j++) {
#  printOut("['$abbr[$j]' substituted for '$names[$j]' in the following lines:]\n");
#  for(my $i = 0; $i < @filestrings; $i++) {
#    while($filestrings[$i] =~ s/(\n?)(.*)(?<![\w<])(?<!== ')($names[$j])(?! ?[\w])(?![>])(.*)/$1$2$abbr[$j]$4/) {
#      printOut("$2$abbr[$j]$4 [SUBSTITUTED FOR ->] $2$3$4\n");
#      if(!$verbose) { print "."; }
#    }
#  }
#}
#printBreak("Functions, Variables, and ID's: Renamed!");
#
##if(@updatePaths > 0) {
#for my $el (@updatePaths) {
#  printBreak("Updating dependent module: $el");
#  open MODULEIN, "< $inputPath$el" or die "$inputPath$el  could not be opened for input. - $!\n";
#  my $fstr;
#  while(<MODULEIN>) { $fstr .= $_; }
#  close MODULEIN;
#
#  for(my $j = 0; $j < @names; $j++) {
#    printOut("[Substituting '$abbr[$j]' for '$names[$j]']\n");
#    while($fstr =~ s/(\n?)(.*)(?<![\w<"])(?<!== ')($names[$j])(?! ?[\w])(?![">])(.*)/$1$2$abbr[$j]$4/) {   # only difference is " & "
#      printOut("$2$abbr[$j]$4 [SUBSTITUTED FOR ->] $2$3$4\n");
#      if(!$verbose) { print "."; }
#    }
#  }
#  open MODULEOUT, "> $outputPath$el" or die "$outputPath$el could not be opened for output. - $!\n";
#  print MODULEOUT $fstr;
#  close MODULEOUT;
#  printBreak("Updated dependent module: $el");
#}
#
#}
#### Done crunching names ############################################################################
#
#
#### Crunch whitespace ###############################################################################
#if($crunchWS) {
#
#for(my $i = 0; $i < @filenames; $i++) {
#  printBreak("Source File Before Whitespace Removal: $filenames[$i] - Start");
#  printOut($filestrings[$i]);
#  printBreak("Source File Before Whitespace Removal: $filenames[$i] - End");
#}
#
#sub removeWS {
#  # 0 - item, 1 - filestring, 2 - regular expression
#  printOut("[Substituting '$_[0]' for ' $_[0] ']\n");
#  while($_[1] =~ s/(\n?)(.*)(?<!')($_[2])(?!')(.*)/$1$2$_[0]$4/) {
#    printOut("$2$_[0]$4 [SUBSTITUTED FOR ->] $2$3$4\n");
#    if(!$verbose) { print "."; }
#  }
#}
#printBreak("Whitespace: Extracting...");
#for(my $i = 0; $i < @filestrings; $i++) {
#  printOut("[$filenames[$i]]\n");
#
#  # = + -
#  removeWS('=', $filestrings[$i], '\s+=\s+');
#  removeWS('+', $filestrings[$i], '\s+\+\s+');
#  removeWS('-', $filestrings[$i], '\s+-\s+');
#
#  # < > || && ==
#  removeWS('<', $filestrings[$i], '\s+<\s+');
#  removeWS('>', $filestrings[$i], '\s+>\s+');
#  removeWS('||', $filestrings[$i], '\s+\|\|\s+');
#  removeWS('&&', $filestrings[$i], '\s+\&\&\s+');
#  removeWS('==', $filestrings[$i], '\s+==\s+');
#  
#  # ( ) { }
#  removeWS('(', $filestrings[$i], '\s+\(|\(\s+');
#  removeWS(')', $filestrings[$i], '\s+\)|\)\s+');
#  removeWS('{', $filestrings[$i], '\s+\{|\{\s+');
#  removeWS('}', $filestrings[$i], '\s+\}|\}\s+');
#
#  # leading and trailing whitespace
#  $filestrings[$i] =~ s/;\s+/;/g;
#  $filestrings[$i] =~ s/\n\s*//g;
#
#  printOut("[$filenames[$i]]\n");
#  printOut("$filestrings[$i]\n");
#}
#printBreak("Whitespace: Extracted!");
#
#}
#### Done crunching whitespace #########################################################################
#
#
#### Output files ###
#printBreak("Output files: Writing...");
#for(my $i = 0; $i < @filenames; $i++) {
#  printOut("$outputPath$filenames[$i]\n");
#  open EXTERNAL, "> $outputPath$filenames[$i]" or die "$outputPath$filenames[$i] - $!\n";
#  print EXTERNAL $filestrings[$i];
#  close EXTERNAL;
#  if(!$verbose) { print "."; }
#}
#printBreak("Output files: Written!");
#
#printBreak("CodeCruncher Finished!");
#

print "</body>\n</html>\n";

undef $log;

print STDOUT "\n\n";







