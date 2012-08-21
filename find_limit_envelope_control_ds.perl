#/opt/local/bin/perl

#########################################################################################
#											#
#	find_limit_envelope_control_ds.perl: this is dataseeker data version		#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		last update: Aug 21, 2012						#
#											#
#########################################################################################

#
#---- directory
#

open(FH, "/data/mta/Script/Fitting_linux/hosue_keeping/dir_list");

while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);


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
#	$start    = `axTime3 $start t d u s`;
	$start    = ydate_to_y1998sec($start);
	$end      = "$this_year:$ydate:00:00:00";
#	$end      = `axTime3 $end t d u s`;
	$end      = ydate_to_y1998sec($end);

	$out_dir  = "$www_dir".'Weekly/'."$ldir/";
	$out_dir2 = "$www_dir2".'Weekly/'."$ldir/";
	$odata_dir = "$data_dir".'Weekly/'."$ldir/";
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
#	$start    = `axTime3 $start t d u s`;
	$start    = ydate_to_y1998sec($start);
	$end      = "$this_year:$ydate:00:00:00";
#	$end      = `axTime3 $end t d u s`;
	$end      = ydate_to_y1998sec($end);

	$out_dir  = "$www_dir".'Quarterly/'."$ldir/";
	$out_dir2 = "$www_dir2".'Quarterly/'."$ldir/";
	$odata_dir = "$data_dir".'Quarterly/'."$ldir/";
}else{
#
#--- full range
#
	$start    =  63071999;     #---- 1999:001:00:00:00
	$end      = "$this_year:$ydate:00:00:00";
#	$end      = `axTime3 $end t d u s`;
	$end      = ydate_to_y1998sec($end);

	$out_dir  = "$www_dir".'Full_range/'."$ldir/";
	$out_dir2 = "$www_dir2".'Full_range/'."$ldir/";
	$odata_dir = "$data_dir".'Full_range/'."$ldir/";
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

OUTER:
for($i = 0; $i < $total; $i++){
        $msid_list[$i]= uc($msid_list[$i]);
        $msid   = lc($msid_list[$i]);
	if($msid eq '' || $msid =~ /\s/){
		next OUTER;
	}

        if($msid =~ /3FAMTRAT/i || $msid =~ /3FAPSAT/i || $msid =~ /3FASEAAT/i
                || $msid =~ /3SMOTOC/i || $msid =~ /3SMOTSTL/i || $msid =~ /3TRMTRAT/i){
                $col = "$msid_list[$i]".'_AVG';
#                $col    = '_'."$msid".'_avg';
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
	$saved_dir = "$data_dir"."$r_dir/"."$ms_dir/"."Fits_data/";
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
	if($b_point1[$i]  >  2000){
		system("$op_dir/perl $bin_dir/find_limit_envelope.perl merged.fits $col2 $degree[$i]  $limit $range $both 2000  $b_point1[$i] $b_point2[$i] $b_point3[$i] $b_point4[$i] $b_point5[$i] $b_point6[$i] $b_point7[$i]");
	}else{
		system("$op_dir/perl $bin_dir/find_limit_envelope.perl merged.fits $col2 $degree[$i]  $limit $range $both $b_point1[$i] $b_point2[$i] $b_point3[$i] $b_point4[$i] $b_point5[$i] $b_point6[$i] $b_point7[$i]");
	}

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
		$rout_dir = "$data_dir"."$r_dir/"."$ms_dir"."/Results/$result_file";
		system("mv *fitting_results2  $rout_dir");
	}
	
	system("mv *gif             $out_dir/Plots/");
	system("mv *fitting_results $odata_dir/Results/");
	
#	if($range != /f/){
#		system("rm zstat");
#	}else{
#		system("rm trimed.fits zstat");
#	}
}
	
######################################################################################
### ydate_to_y1998sec: 20009:033:00:00:00 format to 349920000 fromat               ###
######################################################################################

sub ydate_to_y1998sec{
#
#---- this script computes total seconds from 1998:001:00:00:00
#---- to whatever you input in the same format. it is equivalent of
#---- axTime3 2008:001:00:00:00 t d m s
#---- there is no leap sec corrections.
#

	my($date, $atemp, $year, $ydate, $hour, $min, $sec, $yi);
	my($leap, $ysum, $total_day);

	($date)= @_;
	
	@atemp = split(/:/, $date);
	$year  = $atemp[0];
	$ydate = $atemp[1];
	$hour  = $atemp[2];
	$min   = $atemp[3];
	$sec   = $atemp[4];
	
	$leap  = 0;
	$ysum  = 0;
	for($yi = 1998; $yi < $year; $yi++){
		$chk = 4.0 * int(0.25 * $yi);
		if($yi == $chk){
			$leap++;
		}
		$ysum++;
	}
	
	$total_day = 365 * $ysum + $leap + $ydate -1;
	
	$total_sec = 86400 * $total_day + 3600 * $hour + 60 * $min + $sec;
	
	return($total_sec);
}

######################################################################################
### y1999sec_to_ydate: format from 349920000 to 2009:33:00:00:00 format            ###
######################################################################################

sub y1999sec_to_ydate{
#
#----- this chage the seconds from 1998:001:00:00:00 to (e.g. 349920000)
#----- to 2009:033:00:00:00.
#----- it is equivalent of axTime3 349920000 m s t d
#

	my($date, $in_date, $day_part, $rest, $in_hr, $hour, $min_part);
	my($in_min, $min, $sec_part, $sec, $year, $tot_yday, $chk, $hour);
	my($min, $sec);

	($date) = @_;

	$in_day   = $date/86400;
	$day_part = int ($in_day);
	
	$rest     = $in_day - $day_part;
	$in_hr    = 24 * $rest;
	$hour     = int ($in_hr);
	
	$min_part = $in_hr - $hour;
	$in_min   = 60 * $min_part;
	$min      = int ($in_min);
	
	$sec_part = $in_min - $min;
	$sec      = int(60 * $sec_part);
	
	OUTER:
	for($year = 1998; $year < 2100; $year++){
		$tot_yday = 365;
		$chk = 4.0 * int(0.25 * $year);
		if($chk == $year){
			$tot_yday = 366;
		}
		if($day_part < $tot_yday){
			last OUTER;
		}
		$day_part -= $tot_yday;
	}
	
	$day_part++;
	if($day_part < 10){
		$day_part = '00'."$day_part";
	}elsif($day_part < 100){
		$day_part = '0'."$day_part";
	}
	
	if($hour < 10){
		$hour = '0'."$hour";
	}
	
	if($min  < 10){
		$min  = '0'."$min";
	}
	
	if($sec  < 10){
		$sec  = '0'."$sec";
	}
	
	$time = "$year:$day_part:$hour:$min:$sec";
	
	return($time);
}
		
