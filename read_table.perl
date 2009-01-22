#!/usr/bin/perl 

$data_name = $ARGV[0];
$range     = $ARGV[1];


find_data_location();


print "DATA NAME:            $data_name\n";
print "Lower Violation Date: $low_v\n";
print "Upper Violation Date: $top_v\n";
print "Fits file Location:   $fits_location\n";


print "\nLower\t\t\t\t\t\t\t\t\t\t\t\tUpper\n";
print "Break\t\tInt\t\tSlope\t\t\t2nd\t\t\t";
print "Int\t\tSlope\t\t\t2nd\n";
for($i = 0; $i < $n_brk; $i++){
	print "$break[$i]: ";
	print "$l_int[$i]\t$l_slope[$i]\t $l_quad[$i]\t##\t";
	print "$t_int[$i]\t$t_slope[$i]\t $t_quad[$i]\n";
	print "\n";
}

#####################################################################################
### find_data_location: read data table and extract data for a given msid         ###
#####################################################################################

sub find_data_location {

#---------------------------------------------------------------------------------------
#
#	Input: 	$data_name: msid: case sensitive
#		$range:     full range (f), quarterly (q), or weekly (w)
#
#	Ooutput:
#		$low_v:		estimated date of lower yellow violation
#		$top_v:		estimated date of upper yellow violation
#				if these are "today's" date, it is already in yellow
#		$fits_location:	fits data location
#		$n_brk:		the number of the segments
#		$break[$i]:	$i-th segment starting point
#		$l_int[$i]:	$i-th lower envelope intercept
#		$l_slope[$i]:	$i-th lower envelope slope
#		$l_quad[$i]:	$i-th lower envelope quadraple 
#		$u_int[$i]:	$i-th upper envelope intercept
#		$u_slope[$i]:	$i-th upper envelope slope
#		$u_quad[$i]:	$i-th upper envelope quadraple 
#
#---------------------------------------------------------------------------------------

#
#--- set which data range we are looking for
#

	if($range =~ /f/i){
		$in_data = '/data/mta/www/mta_envelope_trend/full_range_results';
		$dat_dir = '/data/mta/www/mta_envelope_trend/Full_range';
	}elsif($range =~ /q/i){
		$in_data = '/data/mta/www/mta_envelope_trend/quarterly_results';
		$dat_dir = '/data/mta/www/mta_envelope_trend/Quarterly';
	}elsif($range =~ /w/i){
		$in_data = '/data/mta/www/mta_envelope_trend/weekly_results';
		$dat_dir = '/data/mta/www/mta_envelope_trend/Weekly';
	}

	open(FH, "$in_data");
	@break   = ();
	@low_v   = ();
	@top_v   = ();
	@l_int   = ();
	@l_slope = ();
	@l_quad  = ();
	@t_int   = ();
	@t_slope = ();
	@t_quad  = ();
	$n_brk   = 0;

	OUTER:
	while(<FH>){
		chomp $_;
		if($_ =~ /$data_name/i){
			@atemp = split(/<>/, $_);

			$low_v =  $atemp[9];
			$top_v =  $atemp[10];
			for($i = 1; $i < 9; $i++){
				@btemp = split(/=l=/, $atemp[$i]);
				push(@break, $btemp[0]);

				@ctemp = split(/=u=/, $btemp[1]);
				@dtemp = split(/:/,   $ctemp[0]);

				if($dtemp[0] eq ''){
					last OUTER;
				}

				push(@l_int,   $dtemp[0]);
				push(@l_slope, $dtemp[1]);
				push(@l_quad,  $dtemp[2]);

				@dtemp = split(/:/,   $ctemp[1]);
				push(@t_int,   $dtemp[0]);
				push(@t_slope, $dtemp[1]);
				push(@t_quad,  $dtemp[2]);

				$n_brk++;
			}
			last OUTER;
		}
	}
	close(FH);

#
#---- find a fits file location
#

	$input     = `ls $dat_dir/*/Fits_data/*`;
	@fits_list = split(/\s+/, $input);

	OUTER:
	foreach $ent (@fits_list){
		if($ent =~ /$data_name/i){
			$fits_location = $ent;
			last OUTER;
		}
	}
}
