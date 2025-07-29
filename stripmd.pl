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
$mdfile =~ s/###?[^#]*?\n*?Lorem ipsum .*?magna aliqua\.\n//gs;


while ($mdfile =~ m/\[#?([-A-Za-z0-9_\n ]*?)\]\([^)]*?\)\{.wikilink\}/s) {
    my $text = $1;
	my $link;
	($link = $1) =~ s/[\s_]/-/g;
	$link = lc('#h-'.$link);
	my $newlink = "[$text]($link)";
#	print STDERR "$text\n$newlink\n";
	$mdfile =~ s/\[#?[-A-Za-z0-9_\n ]*?\]\([^)]*?\)\{.wikilink\}/$newlink/s;
}
$mdfile =~ s/<div style="float: right; margin-left: 10pt">.*?<\/div>//s;
$mdfile =~ s/<table">.*?<\/table>//s;

$mdfile =~ s/<a.*?href="([^"]*?)".*?>(.*?)<\/a\>/\[$2\]\($1\)/gs;
$mdfile =~ s/<\/?div.*?>//gs;
$mdfile =~ s/\[Category:.*?\)//gs;

print $mdfile;

__END__
