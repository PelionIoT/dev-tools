#!/usr/bin/perl -w  
use strict;
use warnings;

## options can inlude the style requied                                                   
while (my $dataline = <STDIN>) {
    chomp($dataline);
    my $S = "";
    if ($#ARGV >= 0) {
	$S = "style=\"" . join(" ", @ARGV) . "\"";
    }
    print "<h1 " . $S . ">" . $dataline . "</h1>\n";
}


