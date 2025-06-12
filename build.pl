#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

`mkdir -p images`;

open( my $file, "test.roff" );
my $body    = -1;
my $collect = 0;
my $i       = 0;
while (<$file>) {
    if ( $_ =~ /\.PS\s*\n/ ) {
        $body    = "";
        $collect = 1;
    }
    elsif ( $_ =~ /\.PE\s*\n/ ) {
        my $filename = "images/test-$i.png";
        printf "$filename:\n";
        printf "$body\n";
        $body =~ s/"/\\"/g;
        $body =~ s/\n/\\n/g;
        system
"printf \".PS\n$body.PE\" | groff -p -ms -Tps | magick - -trim $filename";
        $i += 1;

        $collect = 0;
    }
    elsif ( $collect == 1 ) {
        $body .= "$_";
    }
}
close $file;
