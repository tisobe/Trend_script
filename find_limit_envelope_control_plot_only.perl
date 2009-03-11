#/usr/bin/perl

#########################################################################################
#											#
#	find_limit_envelope_control_plot_only.perl: this is dataseeker data version	#
#											#
#		---- this is to run the script on a second set of limit table		#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		last update: Mar 11, 2009						#
#											#
#########################################################################################

#
#---- directory
#

$bin_dir  = '/data/mta/MTA/bin/';
$mta_dir  = '/data/mta/Script/Fitting/Trend_script/';
$save_dir = "$mta_dir/Save_data/";
$www_dir1 = '/data/mta_www/mta_envelope_trend/';
$www_dir2 = '/data/mta_www/mta_envelope_trend/SnapShot';

#
#---- read argments
#

$b_list = $ARGV[0];	#---- e.g. oba_list
$limit  = $ARGV[1];	#---- yellow (y) or red (r) limit
$range  = $ARGV[2];     #---- whether it is full (f), quarterly (q), or week (w)
$lim_slc= $ARGV[3];	#---- which limit data tables mta or op. default is op

#
#--- set web directory 
#

if($lim_slc =~ /mta/){
	$www_dir = $www_dir1;
}else{
	$lim_slc = 'op';
	$www_dir = $www_dir2;
}

@atemp  = split(/_list/, $b_list);
$ldir   = uc($atemp[0]);

#
#---- read break point data
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

#
#--- find a path to the data location
#

@atemp  = split(/_list/, $b_list);
$ms_dir = uc (@atemp[0]);

if($range =~ /f/i){
	$s_dir = 'Full_range';
}elsif($range =~ /q/i){
	$s_dir = 'Quarterly';
}elsif($range =~ /w/i){
	$s_dir = 'Weekly';
}

$saved_dir = "$www_dir"."$s_dir/"."$ms_dir/"."Fits_data/";

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
	$fitsgz = "$fits".'.gz';
#
#---- now call the script actually plots the data
#

	system("perl $bin_dir/find_limit_envelope2.perl $saved_dir/$fitsgz $col2 $degree[$i]  $limit $range $lim_slc $b_point1[$i] $b_point2[$i] $b_point3[$i] $b_point4[$i] $b_point5[$i] $b_point6[$i] $b_point7[$i]");

	system("mv *gif             $out_dir/Plots/");
	system("mv *fitting_results $out_dir/Results/");
}
