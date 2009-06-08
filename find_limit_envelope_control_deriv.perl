#/opt/local/bin/perl

#########################################################################################
#											#
#	find_limit_envelope_control_deriv.perl: this is deriv data version		#
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
$www_dir  = '/data/mta_www/mta_envelope_trend/';


$b_list = $ARGV[0];	#---- e.g. oba_list
$limit  = $ARGV[1];	#---- yellow (y) or red (r) limit
$range  = $ARGV[2];     #---- whether it is full (f), quarterly (q), or week (w)

@btemp    = split(/_list/, $b_list);
$file_nam = $btemp[0];

$ldir     = uc($file_nam);
if($range =~ /w/i){
	$out_dir = "$www_dir".'Weekly/'."$ldir/";
}elsif($range =~ /q/i){
	$out_dir = "$www_dir".'Quarterly/'."$ldir/";
}else{
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

$i = 0;
for($i = 0; $i < $total; $i++){
	$msid_list[$i]= uc($msid_list[$i]);
	$msid   = lc($msid_list[$i]);
	$col    = "$msid_list[$i]".'_AVG';
	@btemp  = split(//, $col);
	if($b_list !~ /comp/ && $btemp[0] =~ /\d/){
		$col = 'X'."$col";
	}
	$fits   = "/data/mta4/Deriv/$file_nam".'.fits';

	system("/opt/local/bin/perl $bin_dir/find_limit_envelope.perl $fits $col $degree[$i]  $limit  $range mta  $b_point1[$i] $b_point2[$i] $b_point3[$i] $b_point4[$i] $b_point5[$i] $b_point6[$i] $b_point7[$i]");

	system("mv *gif             $out_dir/Plots/");
	system("mv *fitting_results $out_dir/Results/");
}
