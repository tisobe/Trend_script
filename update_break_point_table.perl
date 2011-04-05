#!/usr/bin/perl 

#########################################################################################################
#													#
#	update_break_point_table.perl: updating break_point_table					#
#													#
#		author: t. isobe (tisobe@cfa.harvard.edu)						#
#													#
#		last update: Apr. 5, 2011								#
#													#
#########################################################################################################

#
#--- directory setting
#

open(FH, "/data/mta/Script/Fitting/hosue_keeping/dir_list");

@atemp = ();
while(<FH>){
        chomp $_;
        push(@atemp, $_);
}
close(FH);

$bin_dir       = $atemp[0];
$www_dir       = $atemp[1];
$www_dir2      = $atemp[2];
$mta_dir       = $atemp[3];
$save_dir      = $atemp[4];
$data_dir      = $atemp[5];
$hosue_keeping = $atemp[6];

#
#---- read all breaking point from the table
#

system("mv $save_dir/break_point_table $save_dir/break_point_table~");
$input = `ls $save_dir/Break_points/*`;
@list  = split(/\s+/, $input);

@years = ();
foreach $ent (@list){
	open(FH, "$ent");
	@ylist = ();
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		$cnt   = 0;
		foreach(@atemp){
			$cnt++;
		}

		OUTER:
		for($i = 2; $i < $cnt; $i++){
			if($atemp[$i] == 2000){
				next OUTER;
			}
			if($atemp[$i] == 2003.975 || $atemp[$i] == 2008.275){
				$rounded = $atemp[$i];
			}else{
				$rounded = int (($atemp[$i] + 0.05) * 10) /10;
			}
			push(@ylist, $rounded);
		}
	}
	close(FH);
	@atemp = sort{$a<=>$b} @ylist;
	$cnt  = 0;
	foreach(@atemp){
		$cnt++;
	}
	if($cnt > 0){
		@btemp = split(/Break_points\//, $ent);
		$name  = uc($btemp[1]);
		$name  =~ s/_LIST//g;
		$line = ${data.$atemp[0]}{data}[0];
		if($line eq ''){
			%{data.$atemp[0]} = (data => ["$name"]);
			push(@years, $atemp[0]);
		}else{
			$line = "$line".' '. "$name";
			%{data.$atemp[0]} = (data => ["$line"]);
		}
		for($i= 1; $i < $cnt; $i++){
			if($atemp[$i] != $atemp[$i-1]){
				$line = ${data.$atemp[$i]}{data}[0];
				if($line eq ''){
					%{data.$atemp[$i]} = (data => ["$name"]);
					push(@years, $atemp[$i]);
				}else{
					$line = "$line".' '. "$name";
					%{data.$atemp[$i]} = (data => ["$line"]);
				}
			}
		}
	}
}

#
#--- re order them by year
#

@ysorted = sort{$a<=>$b} @years;

open(OUT, ">$save_dir/break_point_table");
foreach $year (@ysorted){
	print OUT "$year\t${data.$year}{data}[0]\n";
}
close(OUT);

system("chgrp mtagroup $save_dir/break_point_table");
