#!/usr/bin/env perl
use strict;
use warnings;

# Flag to track whether we're inside the mediawiki fence
my $skipping = 0;

while (<>) {
	chomp;
	# Enter skip mode on the exact opening fence
	# print "raw: $_\n";
	if (!$skipping and ($_ =~ /{=mediawiki}$/)) {
		$skipping = 1;
		next;
	}
	# Exit skip mode on the exact closing fence
	if ($skipping and $_ =~ /\`\`\`$/) {
		$skipping = 0;
	 	next;
	 }
	# If not skipping, print the line
	print "$_\n" unless $skipping;
}
