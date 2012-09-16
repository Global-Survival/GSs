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

#Note the current directory
my $wkdir = $ENV{PWD};
my ($safe_file_name) = $wkdir =~ /^((\/|\w|\-|\_|.)+)+$/; 
if ( !$safe_file_name ) { 
  die "Invalid output filename";
} else {
  $wkdir = $safe_file_name;
}
#foreach my $env (sort keys %ENV) {
#  print $env,": ",$ENV{$env},"\n"; 
#}

#Create file handle and open/lock the input file
my $inputf;
my $file = $ARGV[0] or die "Invalid input filename";
open $inputf, '<', $file or die "Can't open $file: $!\n";
lock($inputf);

#Do the same for the output file, but check filename for safe chars
my $outputf; 
$file = $ARGV[1] or die "Invalid output filename"; 
($safe_file_name) = $file =~ /^(\w+.*)$/; 
if ( !$safe_file_name ) { 
  die "Invalid output filename";
}
open $outputf, '>', $safe_file_name or die "Can't open $safe_file_name: $!\n"; 
lock($outputf); 
print "\n"; 

while (my $line = <$inputf>) { 
  my $fline = $line;
  chop $fline;
  if ( ($fline =~ /^(<link)/) and ($fline =~ /stylesheet/) and ($fline =~ /(href=){1}(\'?)(\"?)((\w|\-|\_|\/|\.)+)(\'?)(\"?)/) ) {
    my $resname = $4;
    my $respath = $resname;
    if ( $resname =~ /\.?\.?\/?((\w|\-|\_|\.)+)?\/?((\w|\-|\_|\.)+)?\/?((\w|\-|\_|\.)+)?\/?((\w|\-|\_|\.)+)?\/?((\w|\-|\_|\.)+)?\/?((\w|\-|\_|\.)+)?\/?((\w|\-|\_|\.)+)?\/?((\w|\-|\_|\.)+)?\/?((\w|\-|\_|\.)+)?\/?((\w|\-|\_|\.)+)?\// ) {
      $respath = $&;
      my $restmp = $resname;
      $restmp =~ s/$respath//;
      $resname = $restmp;
    }
    print '<!--Resource ', $resname, ' @ ', $respath, "-->\n";
    chdir $respath; 
    my $resf;
    open $resf, '<', $resname or die "Can't open $resname: $!\n";
    lock($resf);
    print "<style type=\'text\/css\' >\n";
    print $outputf "<style type=\'text\/css\' >\n";
    while ($line = <$resf>) {
      my $resline = $line;
      chop $resline;
      if ( ($resline =~ /(src:)?(\s?)(url\(){1}(\'?)(\"?)((\.|\/|\w|\_|\-)+)/s) ) {
        my $URLline = $6;
        #print "Current working directory $ENV{PWD}\n";
        #print $outputf "Current working directory $ENV{PWD}\n";
        my $base64f;
        open $base64f, '<', $URLline or die "Can't open $URLline: $!\n";
        lock($base64f);
        binmode $base64f;
        my $encodedData;
        if ($resline =~ /woff/) {
          $encodedData = "data:application/x-font-woff; base64, ";
        } else {
          $encodedData = "data:application/x-font-ttf; base64, ";
        }
        while ($line = <$base64f>) {
          my $b64line = $line;
          chop $b64line;
          $encodedData = $encodedData . urlsafe_b64encode($b64line);
        }
        $resline =~ s/$URLline/$encodedData/;
        print $resline, "\n";
        print $outputf $resline, "\n";
        unlock($base64f);
        close($base64f);

      } else {
        print $resline, "\n";
        print $outputf $resline, "\n";
      }
    }

    print "<\/style>\n";
    print $outputf "<\/style>\n";
    unlock($resf);
    close $resf;
    chdir $wkdir;

  } elsif ( ($fline =~ /^(<script)/) and ($fline =~ /(src=){1}(\'?)(\"?)((\w|\-|\_|\/|\.)+)(\'?)(\"?)/) ) {
    my $resname = $4;
    my $respath = $resname;
    if ( $resname =~ /\.?\.?\/?((\w|\-|\_|\.)+)?\/?((\w|\-|\_|\.)+)?\/?((\w|\-|\_|\.)+)?\/?((\w|\-|\_|\.)+)?\/?((\w|\-|\_|\.)+)?\/?((\w|\-|\_|\.)+)?\/?((\w|\-|\_|\.)+)?\/?((\w|\-|\_|\.)+)?\/?((\w|\-|\_|\.)+)?\/?((\w|\-|\_|\.)+)?\// ) {
      $respath = $&;
      my $restmp = $resname;
      $restmp =~ s/$respath//;
      $resname = $restmp;
    }
    print '<!--Resource ', $resname, ' @ ', $respath, "-->\n";
    chdir $respath; 
    my $resf;
    open $resf, '<', $resname or die "Can't open $resname: $!\n";
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
    unlock($resf);
    close $resf;
    chdir $wkdir;

  } else {
    print $fline, "\n";
    print $outputf $fline, "\n";
  }
}

unlock($inputf);
close $inputf;
unlock($outputf);
close $outputf;
print "\n";