#!/usr/bin/perl
#
#

use strict;
use warnings;

use Data::Dumper;
use Time::Local 'timelocal';
# use lib qw(../gsfh);
use csvgpl;
use csvaggregate;
use csvlib;
use ft;

my $DEBUG = 1;
my $MODE = "NC";
my $DOWNLOAD = 0;
my $src_url = "https://dl.dropboxusercontent.com/s/6mztoeb6xf78g5w/COVID-19.csv";
my $WIN_PATH = "/mnt/f/OneDrive/cov";
my $transaction = "$WIN_PATH/gis-jag-japan.csv.txt";
my $GRAPH_HTML = "$WIN_PATH/JapanPref.html";
my $aggregate = "$WIN_PATH/JapanPref.csv.txt";

my $aggr_total = "$WIN_PATH/Japan_total.csv.txt";
my $TOTAL_CSVF = "$WIN_PATH/japan_total$MODE" . ".csv.txt";
my $TOTAL_GRAPH_HTML = "$WIN_PATH/japan_total$MODE" . ".html";
my $DLM = ",";
#
#	引数処理	
#
for(my $i = 0; $i <= $#ARGV; $i++){
	$_ = $ARGV[$i];
	$DOWNLOAD = 1 if(/-dl/i);
}

#
#	Download CSV file
#
if($DOWNLOAD){
	print("wget $src_url -O $transaction\n");
	system("wget $src_url -O $transaction");
}

#
#	パラメータの設定と集計の実施
#
my $params = {
	input_file => $transaction,
	output_file => $aggregate,
	delemiter => ",",
	#agr_items_name => ["確定日#:#1/2/0","居住都道府県"],
	date_item => "確定日",
	date_format => [2, 0, 1],
	aggr_mode => "",		# "TOTAL",
	
	select_item => "居住都道府県",
#	select_keys  => [qw(東京都 神奈川県)],
	exclude_keys => [],
	agr_total => 0,
	agr_count => 0,
	total_item_name => "",
	sort_keys_name => [qw (確定日) ],		# とりあえず、今のところ確定日にフォーカス（一般化できずにいる）
};

csvaggregate::csv_aggregate($params);		# 集計処理
#system("more $aggregate");


my $ymin = '10';

my $src = "src J.A.G JAPAN ";
my $EXCLUSION = "";
my $src_ref = "J.A.G JAPAN : <a href=\"$src_url\"> $src_url</a>";
my @PARAMS = (
    {ext => "#KIND# Japan 01-05 (#LD#) $src", start_day => "02/15",  lank =>[0, 4] , exclusion => "Others", target => "", label_skip => 2, graph => "lines"},
    {ext => "#KIND# Japan 01-05 (#LD#) $src", start_day => "02/15",  lank =>[0, 4] , exclusion => "Others", target => "", label_skip => 2, graph => "lines"},
    {ext => "#KIND# Japan 02-05 (#LD#) $src", start_day => "02/15",  lank =>[1, 4] , exclusion => "Others", target => "", label_skip => 2, graph => "lines"},
    {ext => "#KIND# Japan 06-10 (#LD#) $src", start_day => "02/15",  lank =>[5, 9] , exclusion => "Others", target => "", label_skip => 2, graph => "lines"},
    {ext => "#KIND# Japan 11-15 (#LD#) $src", start_day => "02/15",  lank =>[10, 14] , exclusion => "Others", target => "", label_skip => 2, graph => "lines"},
    {ext => "#KIND# Japan 16-20 (#LD#) $src", start_day => "02/15",  lank =>[15, 20] , exclusion => "Others", target => "", label_skip => 2, graph => "lines"},
    {ext => "#KIND# Japan 01-10 log (#LD#) $src", start_day => "02/15",  lank =>[0, 9] , exclusion => "Others", target => "", label_skip => 2, graph => "lines",
		 logscale => "y", average => 7},

    {ext => "#KIND# taget cities  (#LD#) $src", start_day => "02/01",  lank =>[0, 99] , exclusion => "Others", 
		target => "東京,大阪,神戸,北海道", label_skip => 2, graph => "lines"},
);
my @csvlist = (
	{ name => "New cases", csvf => $aggregate, htmlf => $GRAPH_HTML, kind => "NC", src_ref => $src_ref, xlabel => "", ylabel => ""},
);


foreach my $clp (@csvlist){
	my %params = (
		debug => $DEBUG,
		win_path => $WIN_PATH,
		data_rel_path => "cov_data",
		clp => $clp,
		params => \@PARAMS,
	);	
	csvgpl::csvgpl(\%params);
}

####################################
#
#	TOTAL
#
#
#	パラメータの設定と集計の実施
#
$params = {
	input_file => $transaction,
	output_file => $aggr_total,
	delemiter => ",",
	#agr_items_name => ["確定日#:#1/2/0","居住都道府県"],
	date_item => "確定日",
	date_format => [2, 0, 1],
	aggr_mode => "TOTAL",
	
	select_item => "居住都道府県",
#	select_keys  => [qw(東京都 神奈川県)],
	exclude_keys => [],
	agr_total => 0,
	agr_count => 0,
	total_item_name => "",
	sort_keys_name => [qw (確定日) ],		# とりあえず、今のところ確定日にフォーカス（一般化できずにいる）
};

csvaggregate::csv_aggregate($params);		# 集計処理
#system("more $aggregate");


$EXCLUSION = "";
@PARAMS = (
    {ext => "#KIND# Japan total 02/01 (#LD#) $src", start_day => "02/01",  lank =>[0, 4] , exclusion => "Others", target => "TOTAL", label_skip => 2, graph => "lines"},
    {ext => "#KIND# Japan TOTAL 3w (#LD#) $src", start_day => -21,  lank =>[0, 4] , exclusion => "Others", target => "TOTAL", label_skip => 2, graph => "lines"},
);
@csvlist = (
	{ name => "New cases", csvf => $aggr_total, htmlf => $TOTAL_GRAPH_HTML, kind => "NC", src_ref => $src_ref, xlabel => "", ylabel => ""},
);


foreach my $clp (@csvlist){
	my %params = (
		debug => $DEBUG,
		win_path => $WIN_PATH,
		data_rel_path => "cov_data",
		clp => $clp,
		params => \@PARAMS,
	);	
	csvgpl::csvgpl(\%params);
}

