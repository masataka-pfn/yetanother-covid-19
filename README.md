#
#	COVID-19 のデータをダウンロードして、CSVとグラフを生成する
#

	cov19.pl [ccse who jag jagtotal] -NC -ND -POP -FT -RT -FULL -full -dl
		-NC 		New cases
		-ND 		New deathes
		-POP		count/population (M)
		-FT			Finatial Times like graph
		-ERN(RT)	Effective reproduction number
		-full		do all all data srouces and functions 
		-FULL		-full with download

	cov19.pl -> ccse	 ccse.pm 	John Hopkins univ. ccse
			 -> who		 who.pm		WHO situation report
			 -> jag		 jag.pm		J.A.G Japan data of Japan
			 -> jagtotal jagtotal.pm	Total of all prefectures on J.A.A Japan 

		DAY				Daily count of the source data
		POP				Daily count / population (M)
		FT(ft.pm)		Finatial Times like 
		ERN(ern.pm)		Effective reproduction number




 our $PARAMS = {			# MODULE PARETER		$mep
    comment => "**** J.A.G JAPAN PARAMS ****",
    src => "JAG JAPAN",
	  src_url => $src_url,
    prefix => "jag_",
    src_file => {
		NC => $transaction,
		ND => "",
    },

    new => \&new,
    aggregate => \&aggregate,
    download => \&download,
    copy => \&copy,

	COUNT => {			# FUNCTION PARAMETER		$funcp
		EXEC => "",
		graphp => [		# GPL PARAMETER				$gplp
			{ext => "#KIND# Japan 01-05 (#LD#) #SRC#", start_day => "02/15",  lank =>[0, 4] , exclusion => $EXCLUSION, target => "", abel_skip => 2, graph => "lines"},



