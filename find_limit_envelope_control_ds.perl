#/usr/bin/perl

#########################################################################################
#											#
#	find_limit_envelope_control_ds.perl: this is dataseeker data version		#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		last update: Jan 22, 2009						#
#											#
#########################################################################################

#
#---- directory
#

$bin_dir  = '/data/mta/MTA/bin/';
$mta_dir  = '/data/mta/Script/Fitting/Trend_script/';
$save_dir = "$mta_dir/Save_data/";
$www_dir  = '/data/mta_www/mta_envelope_trend/';

$b_list = $ARGV[0];	#---- e.g. oba_list
$limit  = $ARGV[1];	#---- yellow (y) or red (r) limit
$range  = $ARGV[2];     #---- whether it is full (f), quarterly (q), or week (w)

@atemp  = split(/_list/, $b_list);
$ldir   = uc($atemp[0]);

#
#---- find today's year date
#

($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

$this_year    = $uyear + 1900;
$ydate        = $uyday + 1;
if($range =~ /w/i){
#
#---- weekly case
#
	$wkago_year   = $this_year;
	$wkago_ydate  = $ydate - 20;
	
	if($wkago_ydate < 0){
		$wkago_year--;
		$chk = 4.0 * int(0.25 * $wkago_year);
		if($chk == $wkago_year){
			$ylength = 366;
		}else{
			$ylength = 365;
		}
		$wkago_ydate = $ylength + $wkago_ydate;
	}
	
	$start  = "$wkago_year:$wkago_ydate:00:00:00";
	$start  = `axTime3 $start t d u s`;
	$end    = "$this_year:$ydate:00:00:00";
	$end    = `axTime3 $end t d u s`;

	$out_dir = "$www_dir".'Weekly/'."$ldir/";
}elsif($range =~ /q/i){
#
#--- quarterly case
#
	$qrtago_year  = $this_year;
	$qrtago_ydate = $ydate - 92;

	if($qrtago_ydate < 0){
        	$qrtago_year--;
        	$chk = 4.0 * int(0.25 * $qrtago_year);
        	if($chk == $qrtago_year){
                	$ylength = 366;
        	}else{
                	$ylength = 365;
        	}
        	$qrtago_ydate = $ylength + $qrtago_ydate;
	}
	
	$start  = "$qrtago_year:$qrtago_ydate:00:00:00";
	$start  = `axTime3 $start t d u s`;
	$end    = "$this_year:$ydate:00:00:00";
	$end    = `axTime3 $end t d u s`;

	$out_dir = "$www_dir".'Quarterly/'."$ldir/";
}else{
#
#--- full range
#
	$start =  63071999;     #---- 1999:001:00:00:00
	$end   = "$this_year:$ydate:00:00:00";
	$end   = `axTime3 $end t d u s`;

	$out_dir = "$www_dir".'Full_range/'."$ldir/";
}

open(FH, "$save_dir/Break_points/$b_list");

@msid_list = ();
@degree    = ();
@b_point1  = ();
@b_point2  = ();
@b_point3  = ();
@b_point4  = ();
@b_point5  = ();
@b_point6  = ();
@b_point7  = ();
$total     = 0;

while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	push(@msid_list, $atemp[0]);
	push(@degree,    $atemp[1]);
        push(@b_point1,  $atemp[2]);
        push(@b_point2,  $atemp[3]);
        push(@b_point3,  $atemp[4]);
        push(@b_point4,  $atemp[5]);
        push(@b_point5,  $atemp[6]);
        push(@b_point6,  $atemp[7]);
        push(@b_point7,  $atemp[8]);
	$total++;
}
close(FH);

for($i = 0; $i < $total; $i++){
	$msid_list[$i]= uc($msid_list[$i]);
	$msid   = lc($msid_list[$i]);
	if($msid =~ /3FAMTRAT/i || $msid =~ /3FAPSAT/i || $msid =~ /3FASEAAT/i
		|| $msid =~ /3SMOTOC/i || $msid =~ /3SMOTSTL/i || $msid =~ /3TRMTRAT/i){
		$col = "$msid_list[$i]".'_AVG';
	}elsif($msid =~ /^DEA/i){
		$col    = "$msid_list[$i]".'_avg';
	}else{
		$col    = '_'."$msid".'_avg';
	}
	$col2   = "$msid".'_avg';
	$fits   = "$msid".'.fits';

	$line = "columns=$col timestart=$start timestop=$end";
	
	$fchk = `ls `;
	if($fchk =~/temp.fits/){
		system("rm temp.fits");
	}

	system("dataseeker.pl infile=test outfile=temp.fits search_crit=\"$line\" ");

	system("perl $bin_dir/find_limit_envelope.perl temp.fits $col2 $degree[$i]  $limit $range $b_point1[$i] $b_point2[$i] $b_point3[$i] $b_point4[$i] $b_point5[$i] $b_point6[$i] $b_point7[$i]");

	system("mv temp.fits        $out_dir/Fits_data/$fits");
	system("gzip -f             $out_dir/Fits_data/$fits");
	system("mv *gif             $out_dir/Plots/");
	system("mv *fitting_results $out_dir/Results/");
}
