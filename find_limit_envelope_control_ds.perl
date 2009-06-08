#/opt/local/bin/perl

#########################################################################################
#											#
#	find_limit_envelope_control_ds.perl: this is dataseeker data version		#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		last update: Jun 08, 2009						#
#											#
#########################################################################################

#
#---- directory
#

$bin_dir  = '/data/mta/MTA/bin/';

$mta_dir  = '/data/mta/Script/Fitting/Trend_script/';
$save_dir = "$mta_dir/Save_data/";
$www_dir  = '/data/mta/www/mta_envelope_trend/';
$www_dir2 = '/data/mta/www/mta_envelope_trend/SnapShot/';

$b_list   = $ARGV[0];	#---- e.g. oba_list
$limit    = $ARGV[1];	#---- yellow (y) or red (r) limit
$range    = $ARGV[2];   #---- whether it is full (f), quarterly (q), or week (w)
$both     = $ARGV[3];	#---- whether you want to create both mta and p009 plots
$all      = $ARGV[4];	#---- if all, retrieve the entire data from dataseeker

@atemp    = split(/_list/, $b_list);
$ldir     = uc($atemp[0]);

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
	
	$start    = "$wkago_year:$wkago_ydate:00:00:00";
	$start    = `axTime3 $start t d u s`;
	$end      = "$this_year:$ydate:00:00:00";
	$end      = `axTime3 $end t d u s`;

	$out_dir  = "$www_dir".'Weekly/'."$ldir/";
	$out_dir2 = "$www_dir2".'Weekly/'."$ldir/";
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
	
	$start    = "$qrtago_year:$qrtago_ydate:00:00:00";
	$start    = `axTime3 $start t d u s`;
	$end      = "$this_year:$ydate:00:00:00";
	$end      = `axTime3 $end t d u s`;

	$out_dir  = "$www_dir".'Quarterly/'."$ldir/";
	$out_dir2 = "$www_dir2".'Quarterly/'."$ldir/";
}else{
#
#--- full range
#
	$start    =  63071999;     #---- 1999:001:00:00:00
	$end      = "$this_year:$ydate:00:00:00";
	$end      = `axTime3 $end t d u s`;

	$out_dir  = "$www_dir".'Full_range/'."$ldir/";
	$out_dir2 = "$www_dir2".'Full_range/'."$ldir/";
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

	if($range =~ /f/i){
		$r_dir = 'Full_range';
	}elsif($range =~ /q/i){
		$r_dir = 'Quarterly';
	}else{
		$r_dir = 'Weekly';
	}

	@atemp     = split(/_list/, $b_list);
	$ms_dir    = uc (@atemp[0]);
	$saved_dir = "$www_dir"."$r_dir/"."$ms_dir/"."Fits_data/";
	$fits     = "$msid".'.fits';
	$fitsgz   = "$fits".'.gz';

#
#--- extract data using dataseeker
#

	$line = "columns=$col timestart=$start timestop=$end";

	system("dataseeker.pl infile=test outfile=merged.fits search_crit=\"$line\" ");

#
#---- now call the script actually plots the data
#

print "$col\n";
	system("/opt/local/bin/perl $bin_dir/find_limit_envelope.perl merged.fits $col2 $degree[$i]  $limit $range $both $b_point1[$i] $b_point2[$i] $b_point3[$i] $b_point4[$i] $b_point5[$i] $b_point6[$i] $b_point7[$i]");

	system("gzip -f merged.fits");
	system("mv merged.fits.gz $saved_dir/$fitsgz");

##	system("rm merged.fits");

#
#---- if both mta and p009 plots are created, save them in different directories
#
	if($both =~/both/i){
		$gif_file = `ls *2.gif`;
		chomp $gif_file;
		$gif_file =~ s/2\.gif/\.gif/;
		system("mv *2.gif             $out_dir2/Plots/$gif_file");
		$result_file = `ls *fitting_results2`;
		chomp $result_file;
		$result_file =~ s/fitting_results2/fitting_results/;
		system("mv *fitting_results2  $out_dir2/Results/$result_file");
	}
	
	system("mv *gif             $out_dir/Plots/");
	system("mv *fitting_results $out_dir/Results/");
	
	if($range != /f/){
		system("rm zstat");
	}else{
		system("rm trimed.fits zstat");
	}
}
