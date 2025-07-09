#!/usr/bin/perl
use XMMX::Utils;
use strict;
use warnings;


my $mdfile = '';
while (my $line = <STDIN>) {
    $mdfile .= $line;
}

$mdfile =~ s/\`\{\{.*?\}\}\`\{=mediawiki\}//gs;
$mdfile =~ s/\xc2\xa0/ /gs;
$mdfile =~ s/## Latest GitHub Commits.*//gs;
$mdfile =~ s/\`\`\`\s(?:\{\.|)(.+?)\b.*?\n/\`\`\`\L$1\n/gs;
$mdfile =~ s/\`\`\`mysql/\`\`\`sql/gs;


while ($mdfile =~ m/\[#?([-A-Za-z0-9_\n ]*?)\]\([^)]*?\)\{.wikilink\}/s) {
    my $text = $1;
	my $link;
	($link = $1) =~ s/[\s_]/-/g;
	$link = lc('#h-'.$link);
	my $newlink = "[$text]($link)";
#	print STDERR "$text\n$newlink\n";
	$mdfile =~ s/\[#?[-A-Za-z0-9_\n ]*?\]\([^)]*?\)\{.wikilink\}/$newlink/s;
}

print $mdfile;

__END__
