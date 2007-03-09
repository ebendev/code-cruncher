#!perl -w

### Pragmas ######################
use strict;
use FileHandle;
use Cwd;


### Globals ######################
 # Path strings
my $inputPath = '';
my $outputPath;

my @names; # all identifiers in the general namespace: functions, variables, ids
my @avoid = qw(); # list of strings not to crunch

 # Source files
my @filenames;
my @filestrings;
my @updatePaths;

my $logPath;
my $profilePath;
my $log;

# Command line variables
my $crunchNames = 1; # default ON
my $crunchWS = 0; # default off
my $warningsOn = 1; # default ON
my $verbose = 0; # default off
my $append = 0; # default off


### Subroutines ######################
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
  for(@names) { return 1 if $str eq $_; }
}

sub isAvoid {
  my ($str) = @_;
  for(@avoid) { return 1 if $str eq $_; }
}

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

sub tRow {
  my $boldstr = shift @_;
  my @cells = @_;
  my @bold;

  if(defined $boldstr) {
    while($boldstr =~ /\|?([^|]+)/g) {
      push(@bold, $1);
    }
    for my $el (@cells) {
      for(@bold) {
        my $re = my $str = $_;
        $str =~ s/\\//g;
        $el =~ s/$re/<strong>$str<\/strong>/;
      }
    }
  }
  printTableRow(@cells);
}

sub printTableFoot {
  print "</table>\n\n";
}

sub cleanHTML {
  (my $str) = @_;
  $str =~ s/</&lt;/g;
  $str =~ s/>/&gt;/g;
  $str =~ s/\n$//;
  $str;
}

### -> Script Execution Entry Point <- #################################################################################
print "\n";
### Process command line options #################################################################################################
## -ws            crunch whitespace
## --ws-only      crunch only whitespace
## --no-warnings  crunch without asking for user approval
## --append-log   append to the log file, instead of replacing it
## -root:path     specify path to index.html or equivalent starting point (only one root may be given)
## -output:path   specify path to the output root (only one output root may be given)
## -update:path   specify path (relative to root) to any unconnected, but dependent modules, like tests, that need to have the updated names
## -avoid:name    specify the name of a function, variable, or ID that should not be crunched
## -log:path      specify the path to the log file (default is log.html in current working directory)
## -profile:path  specify the path to a config file which holds the command line options desired (any given command line options
##                  will override those found in the profile - not yet implemented
##################################################################################################################################
for(@ARGV) {
  $_ =~ s/\\/\//g;
  if($_ =~ /-ws(?!.)/) { $crunchWS = 1; }
  elsif($_ =~ /--ws-only/) { $crunchWS = 1; $crunchNames = 0; }
  elsif($_ =~ /--no-warnings/) { $warningsOn = 0; }
  elsif($_ =~ /--append-log/) { $append = 1; }
  elsif($_ =~ /-root:(.+)/) {
    if(@filenames) { print "$_ ignored. You may only specify one root.\n"; }
    else { ($inputPath, $filenames[0]) = $1 =~ '(.*/)?([^/]+)$'; }
  }
  elsif($_ =~ /-output:(.+)/) {
    if(defined($outputPath)) { print "$_ ignored. You may only specify one output root.\n"; }
    else { $outputPath = $1; }
  }
  elsif($_ =~ /-update:(.+)/) { push @updatePaths, $1; }
  elsif($_ =~ /-avoid:(.+)/) { push @avoid, $1; }
  elsif($_ =~ /-log:(.+)/) {
    if(defined($logPath)) { print "$_ ignored. You may only specify one log file.\n"; }
    else { $logPath = $1; }
  }
  elsif($_ =~ /-profile:(.+)/) {
    if(defined($profilePath)) { print "$_ ignored. You may only specify one profile.\n"; }
    else { print "Profile option not yet supported.\n"; }
  }
  else { print "'$_' ignored. Unrecognized option.\n"; }
}

print "\n";

if(!defined($logPath)) { $logPath = "log.html"; }
if(!defined($outputPath)) { $outputPath = $inputPath; }

if(@ARGV < 1 or !@filenames) {
  print "\nRoot page not specified.  Correct form must include:\n\$ cruncher.pl -root:path/to/index.html/or/equivalent\n";
  exit 1;
}

print "\n";

### Useful to check/debug command line processing ################################
#print "crunchNames = $crunchNames\n";
#print "crunchWS = $crunchWS\n";
#print "warningsOn = $warningsOn\n";
#print "append = $append\n";
#print "filenames = @filenames\n";
#if(defined($outputPath)) { print "outputPath = $outputPath\n"; }
#print "updatePaths = @updatePaths\n";
#print "avoid = @avoid\n";
#if(defined($logPath)) { print "logPath = $logPath\n"; }
#if(defined($profilePath)) { print "profilePath = $profilePath\n"; }
#exit;
##################################################################################

# Open root
{
  my $fh = new FileHandle "< $inputPath$filenames[0]";
  if(!defined($fh)) {
    print "Could not open root page: '$inputPath$filenames[0]'\n\nExiting...\n\n";
    exit 1;
  }
  while(<$fh>) { $filestrings[0] .= $_; }
}

# Open Log
{
  if($append) { $log = new FileHandle ">>$logPath"; }
  else { $log = new FileHandle "> $logPath"; }
  if(!defined($log)) {
    print "Could not open log file for writing.\nExiting...\n\n";
    exit 1;
  }
  else { select $log; }
}

print STDOUT "Please wait while code is crunched.\n\n" if $crunchNames;
print STDOUT "Please wait while whitespace is crunched.\n\n" if($crunchWS && !$crunchNames);

#####################################
## Begin Meaningful HTML Logging
#####################################
unless($append) {
  print '<?xml version="1.0" encoding="UTF-8"?>', "\n";
  print '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN""http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">', "\n";
  print '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">', "\n";
  print "<head>\n<title>Cruncher Log</title>\n";

  print "<style>\n";
  print 'body { font: 75%/1.6 "Myriad Pro", Frutiger, "Lucida Grande", "Lucida Sans", "Lucida Sans Unicode", Verdana, sans-serif; }';
  print 'table { border-collapse: collapse; width: 85em; border: 1px solid #666; }';
  print 'caption { font-size: 1.2em; font-weight: bold; margin: 1em 0; }';
  print 'col { border-right: 1px solid #ccc; }';
  print 'th { background: #bbb; font-weight: normal; text-align: left; }';
  print 'th, td { padding: 0.1em 1em; }';
  print 'td { font: 10pt "Courier New", monospace; }';
  print 'tr:hover { background-color: #3d80df; color: #fff; }';
  print 'thead tr:hover { background-color: transparent; color: inherit; }';
  print "\n</style>\n";

  print "<script>\n";
  print "\n</script>\n</head>\n<body>\n";
}

print "<h1>CodeCruncher &copy; 2007 Eben Geer</h1>\n";
print "<h2>Input Path: $inputPath</h2>\n";

# search for external files only goes one level deep
### Identify JavaScript source files ###
printTableHead("External source files (.js)", "File", "From Source Line");
while($filestrings[0] =~ m/\n?(.*src="(.*\.js).*)/g) {
  push @filenames, $2;
  tRow($2, $2, cleanHTML($1));
  print STDOUT ".";
}
printTableFoot;


### Identify CSS source files ###
printTableHead("External source files (.css)", "File", "From Source Line");
while($filestrings[0] =~ m/\n?(.*url\((.*\.css)\).*)/g) {
  push @filenames, $2;
  tRow($2, $2, cleanHTML($1));
  print STDOUT ".";
}
printTableFoot;


printTableHead("Opening External Source Files...", "File", "Status");
for(my $i = 1; $i < @filenames; $i++) {
  my $fh = new FileHandle("< $inputPath$filenames[$i]");
  while(<$fh>) { $filestrings[$i] .= $_; }
  printTableRow($filenames[$i], "Opened"); # this is a stub!!!
  print STDOUT ".";
}
printTableFoot;

### Crunch Names #########################################################################
if($crunchNames) {

for(my $i = 0; $i < @filenames; $i++) {
  printTableHead("External Source File: $filenames[$i]", "");
  printTableRow('<pre>'.cleanHTML($filestrings[$i]).'</pre>');
  print STDOUT ".";
}

printTableHead("Extracting Comments...", "Comment", "From File");
for(my $i = 0; $i < @filestrings; $i++) {
  # HTML-style comments <!-- -->
  while($filestrings[$i] =~ s/(<!--(?!.{1,10}import).*?-->)//s) { tRow('&lt;!--|--&gt;', cleanHTML($1), $filenames[$i]); }

  # C-style block comments /* */
  while($filestrings[$i] =~ s"(/\*.*?\*/)""s) { tRow('\/\*|\*\/', '<pre>'.cleanHTML($1).'</pre>', $filenames[$i]); }

  # C++ style single-line comments // - and then ;//
  while($filestrings[$i] =~ s"(^//.*)""m) { tRow('//', cleanHTML($1), $filenames[$i]); }
  while($filestrings[$i] =~ s"(\s//.*)"") { tRow('//', cleanHTML($1), $filenames[$i]); }
  while($filestrings[$i] =~ s";(//.*)";") { tRow('//', cleanHTML($1), $filenames[$i]); }

  print STDOUT ".";
}
printTableFoot;

sub identifyNames {
  my ($type, $re) = @_;
  for(my $i = 0; $i < @filestrings; $i++) {
    while($filestrings[$i] =~ m/$re/g) {
      if(isAvoid($2)) { 
        tRow($2, "Avoid", $type, $2, cleanHTML($1), $filenames[$i]);
      }
      elsif(isCollision($2)) {
        tRow($2, "Ignore", $type, $2, cleanHTML($1), $filenames[$i]);
      }
      else {
        push @names, $2;
        tRow($2, "Rename", $type, $2, cleanHTML($1), $filenames[$i]);
      }
      print STDOUT ".";
    }
  }
}

printTableHead("Identifying Functions, Variables, and ID's", "Status", "Type", "Name", "From Source Line", "File");
identifyNames("Variable", '\n?(.*var\s+(\w+).*)');
identifyNames("Function", '\n?(.*function\s+(\w+)\s*\(.*)');
identifyNames("ID", '\n?(.*id="(\w+)".*)');
identifyNames("Name", '\n?(.*(?<!meta )name="(\w+)".*)');
printTableFoot;

my @abbr;
my $n = @names;
my $offset = 0;
for(my $k = 0; $k < $n; $k++) {
  while(isKeyword($abbr[$k] = alphabase($k + $offset))) {
    $offset++;
  }
  print STDOUT ".";
}

### Substitute crunched names ###
for(my $j = 0; $j < @names; $j++) {
  printTableHead("'$abbr[$j]' substituted for '$names[$j]' in the following lines:", "Abbr.", "Source Line", "Name", "From Source Line", "File");
  for(my $i = 0; $i < @filestrings; $i++) {
    while($filestrings[$i] =~ s/(\n?)(.*)(?<![\w<])(?<!== ')($names[$j])(?! ?[\w])(?![>])(.*)/$1$2$abbr[$j]$4/) {
      tRow("$abbr[$j]|$3", $abbr[$j], cleanHTML("$2$abbr[$j]$4"), $3, cleanHTML("$2$3$4"), $filenames[$i]);
      print STDOUT ".";
    }
  }
}
printTableFoot;

for my $el (@updatePaths) {
  printTableHead("Updating dependent module: $el", "Abbr.", "Source Line", "Name", "From Source Line", "From File");
  open MODULEIN, "< $inputPath$el" or die "$inputPath$el  could not be opened for input. - $!\n";
  my $fstr;
  while(<MODULEIN>) { $fstr .= $_; }
  close MODULEIN;

  for(my $j = 0; $j < @names; $j++) {
    while($fstr =~ s/(\n?)(.*)(?<![\w<"])(?<!== ')($names[$j])(?! ?[\w])(?![">])(.*)/$1$2$abbr[$j]$4/) {   # only difference is " & "
      tRow("$abbr[$j]|$3", $abbr[$j], cleanHTML("$2$abbr[$j]$4"), $3, cleanHTML("$2$3$4"), $el);
      print STDOUT ".";
    }
  }
  open MODULEOUT, "> $outputPath$el" or die "$outputPath$el could not be opened for output. - $!\n";
  print MODULEOUT $fstr;
  close MODULEOUT;
  printTableFoot;
}

unless($crunchWS) {
  for(my $i = 0; $i < @filenames; $i++) {
    printTableHead("Crunched Source File: $filenames[$i]", "");
    printTableRow('<pre>'.cleanHTML($filestrings[$i]).'</pre>');
    printTableFoot;
    print STDOUT ".";
  }
}

}
### Done crunching names ############################################################################


### Crunch whitespace ###############################################################################
if($crunchWS) {

unless($append) {
  for(my $i = 0; $i < @filenames; $i++) {
    printTableHead("Source File Before Whitespace Removal: $filenames[$i]", "");
    printTableRow('<pre>'.cleanHTML($filestrings[$i]).'</pre>');
    printTableFoot;
    print STDOUT ".";
  }
}

sub removeWS {
  # 0 - item, 1 - filestring, 2 - regular expression
  while($_[1] =~ s/(\n?)(.*)(?<!')($_[2])(?!')(.*)/$1$2$_[0]$4/) {
    my $re = $_[0];

    if($_[0] eq "+") { $re = '\+'; }
    elsif($_[0] eq "(" or $_[0] eq ")" or $_[0] eq "{" or $_[0] eq "}") { $re = '\\'.$_[0]; }
    elsif($_[0] eq "||") { $re = '\|\|'; }

    tRow($re, "$2$_[0]$4", cleanHTML("$2$3$4"));
    print STDOUT ".";
  }
}

#printBreak("Whitespace: Extracting...");
for(my $i = 0; $i < @filestrings; $i++) {
  printTableHead("Extracting Whitespace From: $filenames[$i]", "Extracted", "Original");

  # = + -
  removeWS('=', $filestrings[$i], '\s+=\s+');
  removeWS('+', $filestrings[$i], '\s+\+\s+');
#  removeWS('-', $filestrings[$i], '\s+-\s+');

  # < > || && ==
#  removeWS('<', $filestrings[$i], '\s+<\s+');
#  removeWS('>', $filestrings[$i], '\s+>\s+');
#  removeWS('||', $filestrings[$i], '\s+\|\|\s+');
#  removeWS('&&', $filestrings[$i], '\s+\&\&\s+');
#  removeWS('==', $filestrings[$i], '\s+==\s+');

  # ( ) { }
#  removeWS('(', $filestrings[$i], '\s+\(|\(\s+');
#  removeWS(')', $filestrings[$i], '\s+\)|\)\s+');
#  removeWS('{', $filestrings[$i], '\s+\{|\{\s+');
#  removeWS('}', $filestrings[$i], '\s+\}|\}\s+');

  # leading and trailing whitespace
  $filestrings[$i] =~ s/;\s+/;/g;
  $filestrings[$i] =~ s/\n\s*//g;

  printTableFoot;

  printTableHead("Crunched File: $filenames[$i]", "");
  printTableRow(cleanHTML($filestrings[$i]));
  printTableFoot;

  print STDOUT ".";
}

}
### Done crunching whitespace #########################################################################


### Output files ###
printTableHead("Writing Output Files", "");
for(my $i = 0; $i < @filenames; $i++) {
  printTableRow($outputPath . $filenames[$i]);
  open EXTERNAL, "> $outputPath$filenames[$i]" or die "$outputPath$filenames[$i] - $!\n";
  print EXTERNAL $filestrings[$i];
  close EXTERNAL;
  print STDOUT ".";
}
printTableFoot;

print '<h2>CodeCruncher Finished!</h2>';
print "</body>\n</html>\n" if $crunchWS;

undef $log;

print STDOUT "\n\n";
