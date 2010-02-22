#!/usr/bin/perl 

#################################################################################################
#												#
#	feed_for_limit_comp.perl: feeding data into recompute_limit_data_control.perl 		#
#												#
#		author: t. isobe (tisobe@cfa.harvard.edu)					#
#												#
#		last update: Feb 17, 2010							#
#												#
#################################################################################################

#
#---- directory
#

$bin_dir  = '/data/mta/MTA/bin/';
$mta_dir  = '/data/mta/Script/Fitting/Trend_script/';
$save_dir = "$mta_dir/Save_data/";
$www_dir  = '/data/mta_www/mta_envelope_trend/';


$input = `cat $save_dir/data_file_list`;
@list  = split(/\s+/, $input);

foreach $ent (@list){
	print "$ent\n";
	system("/opt/local/bin/perl $bin_dir/recompute_limit_data_control.perl $ent");
}

#
#--- move the results to proper locations
#

$input = `ls ./Temp2/`;
@list  = split(/\s+/, $input);
foreach $ent (@list){
        print "$ent\n";
        system("mv ./Temp2/$ent/Fits_data/* /data/mta_www/mta_envelope_trend/Full_range/$ent/Fits_data/.");
}

system("rm ./Temp2");

