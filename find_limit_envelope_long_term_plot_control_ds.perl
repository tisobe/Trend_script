#/usr/bin/perl

#########################################################################################
#											#
#	find_limit_envelope_long_term_plot_control_ds.perl: cotrol long term plots	#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		last update: Apr 13, 2009						#
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
$end      = `axTime3 $end t d u s`;

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
	system("perl $bin_dir/find_limit_plot_long_term.perl $fits_name  $col2 $degree[$i]  $limit $range $both $b_point1[$i] $b_point2[$i] $b_point3[$i] $b_point4[$i] $b_point5[$i] $b_point6[$i] $b_point7[$i]");

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
