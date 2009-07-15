#/opt/local/bin/perl

#########################################################################################
#											#
#	find_limit_envelope_long_term_plot_control_ds.perl: cotrol long term plots	#
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
#$bin_dir = './';

$mta_dir  = '/data/mta/Script/Fitting/Trend_script/';
$save_dir = "$mta_dir/Save_data/";
$www_dir  = '/data/mta/www/mta_envelope_trend/';
$www_dir2 = '/data/mta/www/mta_envelope_trend/SnapShot/';

#$www_dir  = './';
#$www_dir2 = './';


$b_list   = $ARGV[0];	#---- e.g. oba_list
$limit    = $ARGV[1];	#---- yellow (y) or red (r) limit
$range    = $ARGV[2];   #---- whether it is full (f), quarterly (q), or week (w)
$both     = $ARGV[3];	#---- whether you want to create both mta and p009 plots
$all      = $ARGV[4];	#---- if all, retrieve the entire data from dataseeker

@atemp    = split(/_list/, $b_list);
$ldir     = uc($atemp[0]);
$data_dir = "$www_dir/".'Full_range/'."$ldir/".'Fits_data/';
#$data_dir = '/data/mta/Script/Fitting/Ztemp/Temp2/'."$ldir/".'Fits_data/';

#
#---- find today's year date
#

($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

$this_year    = $uyear + 1900;
$ydate        = $uyday + 1;

#
#--- full range
#

$start    =  63071999;     #---- 1999:001:00:00:00
$end      = "$this_year:$ydate:00:00:00";
#$end      = `axTime3 $end t d u s`;
$end      =  ydate_to_y1998sec($end);

$out_dir  = "$www_dir".'Full_range/'."$ldir/";
$out_dir2 = "$www_dir2".'Full_range/'."$ldir/";

#
#--- break points
#

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
        $msid      = lc($msid_list[$i]);
        $col2      = "$msid".'_avg';
###	$fits_name = "$data_dir/"."$msid".'_data.fits.gz';
	$fits_name = "$data_dir/"."$msid".'_data.fits';

#
#---- now call the script actually plots the data
#

print "$col2\n";
	system("/opt/local/bin/perl $bin_dir/find_limit_plot_long_term.perl $fits_name  $col2 $degree[$i]  $limit $range $both $b_point1[$i] $b_point2[$i] $b_point3[$i] $b_point4[$i] $b_point5[$i] $b_point6[$i] $b_point7[$i]");

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
		
