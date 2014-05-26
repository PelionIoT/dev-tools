#!/usr/bin/perl
use strict;
use warnings;

while (my $dataline = <STDIN>) {
    chomp($dataline);
    print "<b><font color=\"#FF0000\">" . $dataline . "</font></b><br>\n";
}
