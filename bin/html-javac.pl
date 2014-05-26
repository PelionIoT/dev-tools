#!/usr/bin/perl -w  
use strict;
use warnings;

## options can inlude the style requied                                                   
while (my $dataline = <STDIN>) {
    chomp($dataline);
    $dataline =~ s/</&lt/g;
    $dataline =~ s/>/&gt/g;
    $dataline =~ s/\s/&nbsp/g;
    $dataline =~ s/&nbspERROR/&nbsp<b><font color="#FF0000">ERROR<\/font><\/b>/g;
    $dataline =~ s/&nbspWARNING/&nbsp<b><font color="#ffe400">WARNING<\/font><\/b>/g;
    $dataline =~ s/\[javac\]/<font color="#CFCFCF">\[javac\]<\/font>/g;
    $dataline =~ s/\[delete\]/<font color="#CFCFCF">\[delete\]<\/font>/g;
    $dataline =~ s/\[mkdir\]/<font color="#CFCFCF">\[mkdir\]<\/font>/g;
    print $dataline . "<br>\n";
}
