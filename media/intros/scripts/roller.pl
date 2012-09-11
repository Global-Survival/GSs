#!/usr/bin/perl -wT
use strict;

# roller.pl
#
# path-to-scripts/roller.pl input.html output.html
#
# This script takes a single .html file as input
# and should be called from the same dir in which
# the .html file is located.
# This file will be parsed and all external resources,
# including CSS, Fonts, Images, Media  and Scripts
# will have thier references stripped out and their 
# contents embedded into the contents of the html file,
# producing a new, single resource (html + everything).
# Base64 encoding will be used to insert binary data.
#
# Incomplete

#Required Perl modules:
use Fcntl qw(:flock SEEK_END);
use MIME::Base64::URLSafe;

#subroutines for using flock on data files
sub lock {
  my ($fh) = @_;
  flock($fh, LOCK_EX) or die "Cannot lock data file - $!\n";
}
sub unlock {
  my ($fh) = @_;
  flock($fh, LOCK_UN) or die "Cannot unlock data file - $!\n";
}

#Create file handle and open/lock the input file
my $inputf;
my $file = $ARGV[0] or die "Invalid input filename";
open $inputf, '<', $file or die "Can't open $file: $!\n";
lock($inputf);

#Do the same for the output file, but check filename for safe chars
my $outputf; 
$file = $ARGV[1] or die "Invalid output filename"; 
my ($safe_file_name) = $file =~ /^(\w+.*)$/; 
if ( !$safe_file_name ) { 
  die "Invalid output filename";
}
open $outputf, '>', $safe_file_name or die "Can't open $file: $!\n"; 
lock($outputf); 
print "\n"; 

while (my $line = <$inputf>) { 
  my $fline = $line;
  chop $fline;
  if ( ($fline =~ /^(<link)/) and ($fline =~ /stylesheet/) and ($fline =~ /(href=){1}(\'?)(\"?)((\w|\-|\_|\/|\.)+)(\'?)(\"?)/) ) {
    my $resname = $4;
    print '<!--Resource @ ', $resname, "-->\n"; 
    my $resf;
    open $resf, '<', $resname or die "Can't open $file: $!\n";
    lock($resf);
    print "<style type=\'text\/css\' >\n";
    print $outputf "<style type=\'text\/css\' >\n";
    while ($line = <$resf>) {
      my $resline = $line;
      chop $resline;
      chop $resline;
      print $resline, "\n";
      print $outputf $resline, "\n";
    }
    print "<\/style>\n";
    print $outputf "<\/style>\n";

  } elsif ( ($fline =~ /^(<script)/) and ($fline =~ /(src=){1}(\'?)(\"?)((\w|\-|\_|\/|\.)+)(\'?)(\"?)/) ) {
    my $resname = $4;
    print '<!--Resource @ ', $resname, "-->\n"; 
    my $resf;
    open $resf, '<', $resname or die "Can't open $file: $!\n";
    lock($resf);
    print "<script>\n";
    print $outputf "<script>\n";
    while ($line = <$resf>) {
      my $resline = $line;
      chop $resline;
      print $resline, "\n";
      print $outputf $resline, "\n";
    }
    print "<\/script>\n";
    print $outputf "<\/script>\n";

  } else {
    print $fline, "\n";
    print $outputf $fline, "\n";
  }
}
close $inputf;
close $outputf;
print "\n";
