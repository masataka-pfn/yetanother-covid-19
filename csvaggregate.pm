#!/usr/bin/perl
#
#	Transaction File
#		2020/01/01	Tokyo	1
#		2020/01/01	Kanaga 	1
#		2020/01/02	Tokyo	1
#		2020/01/02	Saitama	1
#
#	Aggrigate
#					Tokyo	Kanagawa	Saitama
#		2020/01/01		1		1			0
#		2020/01/02		1		0			1
#
package csvaggregate;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(csvaggregate);

use strict;
use warnings;

use Data::Dumper;
use Time::Local 'timelocal';
use csvgpl;

my $DEBUG = 1;

#
#	Date/Time, dispay_item[0], [1], [2],,,,
#
#my $params = {
#	input_file => $transaction,			
#	output_file => $aggregate,
#	#agr_items_name => ["確定日#:#1/2/0","居住都道府県"],
#	date_item => "確定日",
#	
#	select_item => "居住都道府県",
##	select_keys  => [qw(東京都 神奈川県)],
##	exclude_keys => [],
#	agr_total => 0,
#	agr_count => 0,
#	date_format => [2, 0, 1],
#	total_item_name => "",
#	sort_keys_name => [qw (確定日) ],		# とりあえず、今のところ確定日にフォーカス（一般化できずにいる）
#};


my @item_name = ();
my %item_name_col = ();
my $DLM = ",";
sub	csv_aggregate
{
	my ($p) = @_;
	
	my %select_items= ();
	my %count_ymd = ();
	my %total_ymd = ();
	my $total = 0;
	my $count = 0;
	$DLM = $p->{deleimiter} if(defined $p->{delimiter}); # "," "\t";

	my $start_time = time;
		
	print "### open $p->{input_file}: " . (time - $start_time) . "\n";
	open(TRN, $p->{input_file}) || die "cannot open $p->{input_file} file\n";

	$_ = <TRN>; chop;
	&item_name_and_col($_);

	my $datetime = $item_name_col{$p->{date_item}};
	my @date_fmt = @{$p->{date_format}};	# mm/dd/yyyy を yy/mm/dd で見た位置
	my $select_items_col = "";
	my $select_item_names = "";
	my $select_keys = ();
	$select_item_names = &valdef($p->{select_item}, "");
	if($select_item_names){
		$select_items_col = $item_name_col{$select_item_names};
		$select_keys  = (defined $p->{select_keys}) ? [@{$p->{select_keys}}] : "";
	}
	my $total_item_col = ""; #  $item_name_col{somthing};
	my %date_ymd = ();

	# print join(",", $datetime, $select_item_0, $select_key_0, $total_item_col), "\n";

	#
	#	Read Data and aggregate;
	#
	my $date_start = 9999999999;
	my $date_final = 0;
	my @date_list = ();
	print "### start read data $p->{input_file}: " . (time - $start_time) . "\n" ;
	while(<TRN>){
		chop;
		my @w = split(/,/, $_);
		my $v = ($total_item_col) ? $w[$total_item_col] : 1;	# 1 -> count the records
		
		#
		#	Date format convert
		#
		my $dt_raw = $w[$datetime];
		if(!defined $date_ymd{$dt_raw}) {						# Date format 
			next if(!$dt_raw);

			my $tm = &date2ut($dt_raw, "/", @date_fmt);
			$date_ymd{$dt_raw} = &ut2d($tm, "");				# 変換が重いので、連想配列に記録

			$date_start = $tm if($tm < &valdef($date_start, 999999999));	# データ中の最初の日と
			$date_final = $tm if($tm > &valdef($date_final, 0));			# 最後の日を抽出
		}
		my $dt_ymd = $date_ymd{$dt_raw};						# 変換済みの日付をセット
		my $sk = $w[$select_items_col];							# 選択した項目名を記録
		$select_items{$sk}++;									# 

		my $dk = $dt_ymd .= "\t" . $sk;							# 日付+項目名を記録
		$count_ymd{$dk} ++;
		$total_ymd{$dk} += $v;

		$count++;												# レコード数と合計を計算
		$total += $v;
	}
	close(TRN);
	print "### close $p->{input_file}: " . (time - $start_time) . "\n";

	#
	#	欠損している日時に補完するために最小から最大までの日をセットする
	#
	print "### make no data date \n";
	for(my $tm = $date_start; $tm <= $date_final; $tm += 60 * 60 * 24){
		my $ymd = &ut2d($tm, "");
		push(@date_list, $ymd);
	}

	#
	#	日付けでsortし、データを出力
	#
	print "### set sort key : " . (time - $start_time) . "\n";
	
	#	選択した項目をソートして配列に入れておく（ソートを一回で済ますため）I
	my @sorted_select_items = (sort {$select_items{$b} <=> $select_items{$a}} keys %select_items);
	#print CSV "#" . join($DLM, @sorted_select_items), "\n";

	#	CSV出力用の日付けの変換	(最初からこのフォーマットでやればよかったか？）
	my @dts = ();
	foreach my $dt (@date_list){
			my $dts = $dt;
			$dts =~ s#([0-9]{4})([0-9]{2})([0-9]{2})#$2/$3#;
			push(@dts, $dts);
	}

	#
	#	CSVの出力	
	#
	open(CSV, "> $p->{output_file}") || die "cannot create $p->{output_file}";

	#	1行目：項目名など
	print CSV "#" . join($DLM, "date", "total", @dts), "\n";

	#
	#	1日分のデータの出力
	#
	my $aggr_mode = &valdefs($p->{aggr_mode}, "");
	if(! $aggr_mode){
		foreach my $sk (@sorted_select_items){
			my @records = ();
			my $total_count = 0;
			foreach my $dt (@date_list){
				my $k = $dt . "\t" . $sk;
				my $count = (defined $count_ymd{$k}) ? $count_ymd{$k} : 0;
				my $total = (defined $total_ymd{$k}) ? $total_ymd{$k} : 0;
				push(@records, $count);
				$total_count += $count;
			}

			print CSV join($DLM, $sk, $total_count, @records), "\n";
		}
	}
	else {
		my $agg_total = 0;
		my @records = ();
		foreach my $dt (@date_list){
			my $total_count = 0;
			foreach my $sk (@sorted_select_items){
				my $k = $dt . "\t" . $sk;
				my $count = (defined $count_ymd{$k}) ? $count_ymd{$k} : 0;
				my $total = (defined $total_ymd{$k}) ? $total_ymd{$k} : 0;
				$total_count += $count;
			}
			if($aggr_mode eq "TOTAL"){
				$agg_total += $total_count;
				push(@records, $total_count);
			}
			elsif($aggr_mode eq "AVERAGE"){
				$agg_total += $total_count / ($#date_list + 1);
				push(@records, ($total_count / ($#date_list + 1)));
			}
		}
		print CSV join($DLM, $aggr_mode, $agg_total, @records), "\n";
	}
	close(CSV);

	print "### done sort : " . (time - $start_time) . "\n";
	print join($DLM, "total", $count, $total), "\n";
}

#
#
#
sub	item_name_and_col
{
	my ($v) = @_;

	@item_name = split(/,/, $v);
	my $col_number = $#item_name;

	#
	#	Read and set the header of CSV
	#
	for(my $i = 0; $i <= $col_number; $i++){
		my $item_name = $item_name[$i];
		$item_name_col{$item_name} = $i;
		#print "[$item_name] $i\n";
	}
}

#
#
#	
sub valdef
{
	my ($v, $d) = @_;
	$d = 0 if(! defined $d);
	my $rt = (defined $v && $v) ? $v : $d;

	#print "valdef:[$v]:[$d]:[$rt]\n";
	return $rt;
}	

sub valdefs
{
	my ($v, $d) = @_;
	$d = "" if(! defined $d);
	my $rt = (defined $v && $v) ? $v : $d;

	#print "valdef:[$v]:[$d]:[$rt]\n";
	return $rt;
}	

#
#
#
sub ymd2tm
{
	my ($y, $m, $d, $h, $mn, $s) = @_;

	#print "ymd2tm: " . join("/", @_), "\n";

	#$y -= 2100 if($y > 2100);
	my $tm = timelocal($s, $mn, $h, $d, $m - 1, $y);
	# print "ymd2tm: " . join("/", $y, $m, $d, $h, $mn, $s), " --> " . &ut2d($tm, "/") . "\n";
	return $tm;
}

sub ut2t
{
	my ($tm, $dlm) = @_;

	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($tm);
	my $s = sprintf("%02d%s%02d%s%02d", $hour, $dlm, $min, $dlm, $sec);
	return $s;
}

sub ut2d
{
	my ($tm, $dlm) = @_;

	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($tm);
	my $s = sprintf("%04d%s%02d%s%02d", $year + 1900, $dlm, $mon+1, $dlm, $mday);
	return $s;
}

sub search_list
{
	my ($key, @w) = @_;

	#print "search: " . join(",", @w) , "\n";
	foreach my $item (@w){
		if($key =~ /$item/){
			# print "search_list: $key:$item\n";
			return 1;
		}
	}
	return "";
}

#
#
#
sub	date2ut
{
	my ($dt, $dlm, $yn, $mn, $dn, $hn, $mnn, $sn) = @_;

	my @w = split(/$dlm/, $dt);
	my ($y, $m, $d, $h, $mi, $s) = ();
	
	$y = &valdef($w[$yn], 0);
	$m = &valdef($w[$mn], 0);
	$d = &valdef($w[$dn], 0);

	if(! defined $hn){
		return &ymd2tm($y, $m, $d, 0, 0, 0);
	}

	$h  = &valdef($w[$hn], 0);
	$mi = &valdef($w[$mnn], 0);
	$s  = &valdef($w[$sn], 0);

	return &ymd2tm($y, $m, $d, $h, $mi, $s);
} 

sub	date_format
{
	my ($dt, $dlm, $y, $m, $d, $h, $mn, $s) = @_;

	my @w = split(/$dlm/, $dt);
	my @dt = ();
	my @tm = ();
	
	$dt[0] = &valdef($w[$y], 0);
	$dt[1] = &valdef($w[$m], 0);
	$dt[2] = &valdef($w[$d], 0);

	my $dts = join("/", @dt);
	if(! defined $h){
		retunr $dts;
	}
	
	$tm[0] = &valdef($w[$h], 0);
	$tm[1] = &valdef($w[$mn], 0);
	$tm[2] = &valdef($w[$s], 0);
	my $tms = join(":", @tm);

	return "$dts $tms";
} 
1;
