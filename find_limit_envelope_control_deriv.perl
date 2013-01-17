#/opt/local/bin/perl

#########################################################################################
#											#
#	find_limit_envelope_control_deriv.perl: this is deriv data version		#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		last update: Jan 16, 2013						#
#											#
#########################################################################################

#
#--- if this is a test case, set comp_test to "test"
#

OUTER:
for($i = 0; $i < 10; $i++){
	if($ARGV[$i] =~ /test/i){
		$comp_test = 'test';
		last OUTER;
	}elsif($ARGV[$i] eq ''){
		$comp_test = '';
		last OUTER;
	}
}

#
#---- directory
#
if($comp_test =~ /test/i){
	open(FH, "/data/mta/Script/Fitting_linux/hosue_keeping/dir_list_test");
}else{
	open(FH, "/data/mta/Script/Fitting_linux/hosue_keeping/dir_list");
}

while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
    }
close(FH);

$b_list = $ARGV[0];	#---- e.g. oba_list
$limit  = $ARGV[1];	#---- yellow (y) or red (r) limit
$range  = $ARGV[2];     #---- whether it is full (f), quarterly (q), or week (w)

@btemp    = split(/_list/, $b_list);
$file_nam = $btemp[0];

$ldir     = uc($file_nam);
#
#--- if it is for the test, outputs go to a different directory
#
if($comp_test =~ /test/i){
	$ldir = "$ldir".'_out';
}

if($range =~ /w/i){
	$out_dir  = "$www_dir".'Weekly/'."$ldir/";
	$out_dir2 = "$data_dir".'Weekly/'."$ldir/";
}elsif($range =~ /q/i){
	$out_dir  = "$www_dir".'Quarterly/'."$ldir/";
	$out_dir2 = "$data_dir".'Quarterly/'."$ldir/";
}else{
	$out_dir  = "$www_dir".'Full_range/'."$ldir/";
	$out_dir2 = "$data_dir".'Full_range/'."$ldir/";
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

	if($comp_test =~ /test/){
		system("$op_dir/perl $bin_dir/find_limit_envelope.perl  $fits $col $degree[$i]  $limit  $range mta  $b_point1[$i] $b_point2[$i] $b_point3[$i] $b_point4[$i] $b_point5[$i] $b_point6[$i] $b_point7[$i] test");
	}else{
		system("$op_dir/perl $bin_dir/find_limit_envelope.perl $fits $col $degree[$i]  $limit  $range mta  $b_point1[$i] $b_point2[$i] $b_point3[$i] $b_point4[$i] $b_point5[$i] $b_point6[$i] $b_point7[$i]");
	}

	system("mv *gif             $out_dir/Plots/");
	system("mv *fitting_results $out_dir2/Results/");
}
