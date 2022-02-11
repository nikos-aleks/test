#!/usr/bin/env perl

use warnings;
use strict;
use File::Copy qw(move);
use File::Temp qw(tempfile);
use LWP::UserAgent;
use JSON;
use Encode qw(encode);
use MIME::Base64;

$| = 1;

sub checkresponse {
	my $input = <STDIN>;
	my @values;

	chomp $input;
	if ($input =~ /^200 result=(-?\d+)\s?(.*)$/) {
		@values = ("$1", "$2");
	} else {
		$input .= <STDIN> if ($input =~ /^520-Invalid/);
		@values = (-1, -1);
	}
	return @values;
}
