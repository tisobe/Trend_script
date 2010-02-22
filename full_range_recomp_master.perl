#!/usr/bin/perl 

#################################################################################################################
#														#
#	full_range_recomp_master.perl: control: find_limit_envelope_control_plot_only_new.perl to create plots	#
#					of all msids								#
#														#
#		author: t. isobe (tisobe@cfa.harvard.edu)							#
#														#
#		last update: Feb. 22, 2010									#
#														#
#################################################################################################################

$bin_dir  = '/data/mta/MTA/bin/';

$mta_dir  = '/data/mta/Script/Fitting/Trend_script/';
$save_dir = "$mta_dir/Save_data/";
$input    = ` cat $save_dir/data_file_list`;
@list     = split(/\s+/, $input);

foreach $ent (@list){
	print "$ent\n";
	system("/opt/local/bin/perl  /data/mta/Script/Fitting/find_limit_envelope_control_plot_only_new.perl $ent y f mta");
}
