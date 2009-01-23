#!/usr/bin/perl

#########################################################################################
#											#
#	create_master.perl: create master scripts to compute data envelopes		#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		last update: Jan 23, 2008						#
#											#
#########################################################################################

#
#---- directory
#

$bin_dir = '/data/mta/MTA/bin/';
$mta_dir = '/data/mta/Script/Fitting/Trend_script/';
$www_dir = '/data/mta_www/mta_envelope_trend/';


$location = $ARGV[0];    #--- top directroy location for running the scripts
$limit    = $ARGV[1];    #---- limit y or r
$range    = $ARGV[2];    #---  whether this is full (f), quarterly (q), or weekly (w)
chomp $location;

#
#--- dataseeker data run
#

$in_list  =`cat $mta_dir/Save_data/dataseeker_input_list`;
@list     = split(/\s+/, $in_list);

open(OUT, "> $location/wrap_ds_script");

print OUT "/bin/tcsh  < $location/main_ds_script\n";

close(OUT);

open(OUT, "> $location/main_ds_script");

print OUT "cd $location\n";
print OUT 'source /home/mta/.ascrc',"\n";
print OUT '',"\n";
print OUT 'rm -rf param',"\n";
print OUT 'mkdir param',"\n";
print OUT 'source /home/mta/bin/reset_param',"\n";
print OUT 'setenv PFILES "${PDIRS}:${SYSPFILES}"',"\n";
print OUT 'set path = (/home/ascds/DS.release/bin/  $path)',"\n";
print OUT 'set path = (/home/ascds/DS.release/otsbin/  $path)',"\n";
print OUT "\n";

print OUT "cp $mta_dir/Save_data/test $location/$dir_name/test\n";
print OUT "\n";

foreach $ent (@list){
	@atemp = split(/_list/, $ent);
	$data_name = $atemp[0];
	$dir_name  = uc($data_name);

	print OUT "perl $bin_dir/find_limit_envelope_control_ds.perl $ent $limit $range\n";
}
#
#--- remove older results
#

print OUT "\n";

if($range =~ /f/i){
	print OUT "mv $www_dir/full_range_results $www_dir/full_range_results~\n";
	print OUT "mv $www_dir/full_range_results_temp $www_dir/full_range_results\n";
}elsif($range =~ /q/i){
	print OUT "mv $www_dir/quarterly_results $www_dir/quarterly_results~\n";
	print OUT "mv $www_dir/quarterly_results_temp $www_dir/quarterly_results\n";
}elsif($range =~ /w/i){
	print OUT "mv $www_dir/weekly_results $www_dir/weekly_results~\n";
	print OUT "mv $www_dir/weekly_results_temp $www_dir/weekly_results\n";
}

if($range =~ /f/i){
	print OUT "\n";
	print OUT "perl $bin_dir/find_limit_envelope_mk_html.perl\n";
}

close(OUT);

#
#---- deriv data run
#

$in_list  =`cat $mta_dir/Save_data/deriv_input_list`;
@list     = split(/\s+/, $in_list);

open(OUT, "> $location/wrap_deriv_script");

print OUT "/bin/tcsh  < $location/main_deriv_script\n";

close(OUT);

open(OUT, "> $location/main_deriv_script");

print OUT "cd $location\n";
print OUT 'source /home/mta/.ascrc',"\n";
print OUT '',"\n";
print OUT 'rm -rf param',"\n";
print OUT 'mkdir param',"\n";
print OUT 'source /home/mta/bin/reset_param',"\n";
print OUT 'setenv PFILES "${PDIRS}:${SYSPFILES}"',"\n";
print OUT 'set path = (/home/ascds/DS.release/bin/  $path)',"\n";
print OUT 'set path = (/home/ascds/DS.release/otsbin/  $path)',"\n";
print OUT '',"\n";

foreach $ent (@list){
	@atemp = split(/_list/, $ent);
	$data_name = $atemp[0];
	$dir_name  = uc($data_name);

	 print OUT "perl $bin_dir/find_limit_envelope_control_deriv.perl $ent $limit $range\n";
}
close(OUT);

system("chmod 777 $location/*");
