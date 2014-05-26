#!/usr/bin/perl
use strict;
use warnings;

while (my $dataline = <STDIN>) {
    chomp($dataline);
    print "<b>" . $dataline . "</b><br>\n";
}
