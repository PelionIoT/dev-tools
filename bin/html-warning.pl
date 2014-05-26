#!/usr/bin/perl
use strict;
use warnings;

while (my $dataline = <STDIN>) {
    chomp($dataline);
    print "<b><font color=\"#FFe400\">" . $dataline . "</font></b><br>\n";
}
