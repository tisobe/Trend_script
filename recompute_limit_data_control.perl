#/opt/local/bin/perl

#########################################################################################
#											#
#	recompute_limit_data_control.perl: control recompute_limit_data.perl      	#
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


$b_list = $ARGV[0];	#---- e.g. oba_list

$range = 'f';

@atemp     = split(/_list/, $b_list);
$ldir      = uc($atemp[0]);
$saved_dir = "$data_dir"."Full_range/"."$ldir/"."Fits_data/";

$new_dir   = './Temp2/'."$ldir/".'Fits_data/';
$chk       =`ls ./Temp2/`;
if($chk !~ /$ldir/){
	system("mkdir ./Temp2/$ldir");
}

$chk       =`ls ./Temp2/$ldir/`;
if($chk !~ /Fits_data/){
	system("mkdir ./Temp2/$ldir/Fits_data");
}

#
#---- read break points for each data
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
	$fits   = "$msid_list[$i]".'_data.fits';
	$fits   = lc($fits);
	$fitsgz = "$fits".'*';
	$col    = "$msid_list[$i]"."_avg";
	$col    = lc($col);
#
#---- now call the script actually create data file ------
#

print "$col\n";
	system("$op_dir/perl $bin_dir/recompute_limit_data.perl $saved_dir/$fitsgz $col 2000  $b_point1[$i] $b_point2[$i] $b_point3[$i] $b_point4[$i] $b_point5[$i] $b_point6[$i] $b_point7[$i]");

	system("mv *_min_max.fits $new_dir/");
}
