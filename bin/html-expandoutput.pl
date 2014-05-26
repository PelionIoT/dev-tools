#!/usr/bin/perl -w  
use strict;
use warnings;

## options can inlude the style requied                                                   
while (my $dataline = <STDIN>) {
    chomp($dataline);
    $dataline =~ s/</&lt/g;
    $dataline =~ s/>/&gt/g;
    $dataline =~ s/\s/&nbsp/g;
    $dataline =~ s/(\S*inflating.*)/<font color="#DDDDDD">$1<\/font>/g;
    $dataline =~ s/[Ee]rror/<font color="#FF0000">error<\/font>/g;
    $dataline =~ s/[Ww]arning/<font color="#FFE400">warning<\/font>/g;
    print $dataline . "<br>\n";
}
