#!/usr/bin/perl
#
#	src => "Johns Hopkins CSSE",
#	src_url => "https://github.com/beoutbreakprepared/nCoV2019",
#	prefix => "jhccse_",
#
#	Functions must define
#	new => \&new,
#	aggregate => \&aggregate,
#	download => \&download,
#	copy => \&copy,
#
#
package ccse;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(ccse);

use strict;
use warnings;
use Data::Dumper;
use config;
use csvgpl;
use jhccse;
use dp;
use params;

#
#	Initial 
#
my $DEBUG = 0;
my $DLM = $config::DLM;
my $WIN_PATH = $config::WIN_PATH;
my $infopath = $config::INFOPATH->{ccse} ;


#
#	Parameter set
#
my $EXCLUSION = "Others,US";
my $CCSE_BASE_DIR = "/home/masataka/who/COVID-19/csse_covid_19_data/csse_covid_19_time_series";



our $PARAMS = {			# MODULE PARETER        $mep
	comment => "**** CCSE PARAMS ****",
	src => "Johns Hopkins CSSE",
	src_url => "https://github.com/beoutbreakprepared/nCoV2019",
	prefix => "jhccse_",
	src_file => {
		NC => "$CCSE_BASE_DIR/time_series_covid19_confirmed_global.csv",
		ND => "$CCSE_BASE_DIR/time_series_covid19_deaths_global.csv",
		CC => "$CCSE_BASE_DIR/time_series_covid19_confirmed_global.csv",
		CD => "$CCSE_BASE_DIR/time_series_covid19_deaths_global.csv",
		NR  => "$CCSE_BASE_DIR/time_series_covid19_recovered_global.csv",
		CR => "$CCSE_BASE_DIR/time_series_covid19_recovered_global.csv",
	},
	base_dir => $CCSE_BASE_DIR,

	new => \&new,
	aggregate => \&aggregate,
	download => \&download,
	copy => \&copy,
	DLM => $DLM,

	AGGR_MODE => {DAY => 1, POP => 1},									# Effective AGGR MODE
	#MODE => {NC => 1, ND => 1, CC => 1, CD => 1, NR => 1, CR => 1},		# Effective MODE

	COUNT => {			# FUNCTION PARAMETER    $funcp
		EXEC => "US",
		graphp => [		# GPL PARAMETER         $gplp					# Old version of graph parameter
			@params::PARAMS_COUNT, 
			{ext => "#KIND# Taiwan (#LD#) #SRC#", start_day => 0, lank =>[0, 999], exclusion => $EXCLUSION, target => "Taiwan", label_skip => 3, graph => "lines"},
			{ext => "#KIND# China (#LD#) #SRC#", start_day => 0,  lank =>[0, 19], exclusion => $EXCLUSION, target => "China", label_skip => 3, graph => "lines"},
		],
		graphp_mode => {												# New version of graph pamaeter for each MODE
			NC => [
				@params::PARAMS_COUNT, 
				{ext => "#KIND# Taiwan (#LD#) #SRC#", start_day => 0, lank =>[0, 999], exclusion => $EXCLUSION, target => "Taiwan", label_skip => 3, graph => "lines"},
				{ext => "#KIND# China (#LD#) #SRC#", start_day => 0,  lank =>[0, 19], exclusion => $EXCLUSION, target => "China", label_skip => 3, graph => "lines"},
			],
			ND => [
				@params::PARAMS_COUNT, 
				{ext => "#KIND# Taiwan (#LD#) #SRC#", start_day => 0, lank =>[0, 999], exclusion => $EXCLUSION, target => "Taiwan", label_skip => 3, graph => "lines"},
				{ext => "#KIND# China (#LD#) #SRC#", start_day => 0,  lank =>[0, 19], exclusion => $EXCLUSION, target => "China", label_skip => 3, graph => "lines"},
			],
			CC => [
				 @params::ACCD_PARAMS, 
			],
			CD => [
				 @params::ACCD_PARAMS, 
			],
		},

	},
	FT => {
		EXC => "Others",  # "Others,China,USA";
		ymin => 10,
		average_date => 7,
		graphp => [
			@params::PARMS_FT
		],
	},
	ERN => {
		EXC => "Others",
		ip => 5,
		lp => 8,
		average_date => 7,
		graphp => [
			@params::PARMS_RT
		],
	},
};

#
#	For initial (first call from cov19.pl)
#
sub	new 
{
	return $PARAMS;
}

#
#	Download data from the data source
#
sub	download
{
	my ($info_path) = @_;
	system("(cd ../COVID-19; git pull origin master)");
	&copy($info_path);
	
}

#
#	Copy download data to Windows Path
#
sub	copy
{
	my ($info_path) = @_;
	my $BASE_DIR = $info_path->{base_dir};
	system("cp $BASE_DIR/*.csv $WIN_PATH/CSV");
}

#
#	Aggregate JH CCSE CSV FILE
#
my ($colum, $record , $start_day, $last_day);
my %JHCCSE = ();
sub	aggregate
{
	my ($fp) = @_;

	my $aggr_mode = $fp->{aggr_mode};
	#dp::dp "AGGREGATE: " . join("\n", $fp->{src_file}, $fp->{stage1_csvf}, $aggr_mode, $fp->{dlm}) . "\n";

	if(1 || ! defined $JHCCSE{$aggr_mode}){
		my $param = {
			mode => $fp->{mode},
			input_file => $fp->{src_file},
			output_file => $fp->{stage1_csvf},
			aggr_mode	=> $fp->{aggr_mode},
			delimiter => $fp->{dlm},
		};
		($colum, $record , $start_day, $last_day) = jhccse::jhccse($param);
		$JHCCSE{$aggr_mode} = [$colum, $record , $start_day, $last_day];
	}
	return @{$JHCCSE{$aggr_mode}};
}
	
1;
