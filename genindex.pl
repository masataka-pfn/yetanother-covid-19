#!/usr/bin/perl
#
#	Generate HTML INDEX  file
#
use strict;
use warnings;
use config;

my $DEBUG = 0;
my $WIN_PATH = $config::WIN_PATH;
my $INDEX_HTML = "$WIN_PATH/covid_index.html";
my $FRAME_HTML = "$WIN_PATH/covid_frame.html";

my @src_list = qw (jhccse who jag jagtotal);
my @mode_list = qw (NC ND CC CD NR CR);
my @submode_list = qw (COUNT FT ERN);
my @aggr_list = qw (DAY POP);

my $INDEX = << "_EOI_";
<html>
<head>
<title>INDEX COVID-19 </title>
</head>

<frameset cols="300,*">
    <frame src="covid_frame.html" name="index">
    <frame src="covid_frame.html" name="graph">
    </frameset>
</frameset>
</html> 
_EOI_

my $CSS = $config::CSS;

my $TBL_SIZE = 10;
my $class = "class=\"c\"";

print "Generate index.html and frame.html\n";
open(INDEX, ">$INDEX_HTML") || die "cannot create file $INDEX_HTML";
print INDEX $INDEX;
close(INDEX);

open(FRAME, "> $FRAME_HTML") || die "Cannot create file $FRAME_HTML";
print FRAME "<HTML>\n";
print FRAME "<HEAD>\n";
print FRAME "<TITLE> COVID-19 INDEX </TITLE>\n";
print FRAME $CSS;
print FRAME "</HEAD>\n";
print FRAME "<BODY>\n";

print FRAME "<span class=\"c\"> ";
print FRAME "<H1>INDEX COVID-19</H1>\n";
print FRAME "<ul type=\"disc\">\n";
foreach my $src (@src_list){
	foreach my $aggr (@aggr_list){
		foreach my $sub (@submode_list){
			foreach my $mode (@mode_list){
				next if($aggr eq "POP" && ($sub ne "COUNT" || $src ne "jhccse"));
				next if($mode eq "ND" && $sub eq "ERN"); 
				if($mode =~ /NR/){
					next if($sub ne "COUNT" || !( $src =~ /ccse/));
				}
				if($mode =~ /^C/){ 
					next if($mode =~ /CR/ && $src =~ /who/);
					next if($sub ne "COUNT" || !( $src =~ /ccse/ || $src =~ /who/));
				}
				next if($src =~ /jag/ && $mode eq "ND");
				my $relp = join("_", $src, $mode, $sub, $aggr) . ".html";

				print FRAME "<li><a href =\"HTML/$relp\" target=\"graph\">$relp</a></li>\n";
				print $relp . "\n" if($DEBUG);
			}
		}
		print FRAME "<br>\n";
	}
	#print FRAME "<br>\n";
}
print FRAME "</ul>\n";
print FRAME "</span>\n";
print FRAME "</BODY>\n";
print FRAME "</HTML>\n";
close(FRAME);

