#/usr/bin/perl

$b_list = $ARGV[0];	#---- e.g. oba_list

@btemp    = split(/_list/, $b_list);
$file_nam = $btemp[0];

open(FH, "$b_list");
$total  = 0;
@msid_list = ();
@degree    = ();
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	push(@msid_list, $atemp[0]);
	push(@degree,    $atemp[1]);
	$total++;
}
close(FH);

$i = 0;
for($i = 0; $i < $total; $i++){
	$msid_list[$i]= uc($msid_list[$i]);
	$msid   = lc($msid_list[$i]);
	$col    = "$msid_list[$i]".'_AVG';
	@btemp  = split(//, $col);
	if($btemp[0] =~ /\d/){
		$col = 'X'."$col";
	}
	$fits   = "/data/mta4/Deriv/$file_nam".'.fits';
print "$col\n";

	system("perl ./find_limit_envelope_sun_angle.perl $fits $col $degree[$i]");

	system("mv *gif ./Plots/");
	system("mv *fitting_results ./Results/");
	system("rm pgplots.ps");
}
