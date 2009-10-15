#!/usr/bin/perl 

#########################################################################################################
#													#
#	create_break_point_master_html.perl: create a master table of breaking point listing		#
#													#
#		author: t. isobe (tisobe@cfa.harvard.edu)						#
#													#
#		last update: Oct 15, 2009 								#
#													#
#########################################################################################################

#
#--- read a table of cause of the break
#

open(FH, "/data/mta/Script/Fitting/Trend_script/Save_data/break_point_cause");
@date_c = ();
@cause  = ();
$c_cnt  = 0;
while(<FH>){
	chomp $_;
	@atemp = split(/\t+/, $_);
	push(@date_c, $atemp[0]);
	push(@cause,  $atemp[1]);
	$c_cnt++;
}
close(FH);

#
#--- read a table of affected systems
#

open(FH, "/data/mta/Script/Fitting/Trend_script/Save_data/break_point_table");
@date_b = ();
@entry  = ();
$b_cnt  = 0;
while(<FH>){
	chomp $_;
	@atemp = split(/\t+/, $_);
	push(@date_b, $atemp[0]);
	push(@entry,  $atemp[1]);
	$b_cnt++;
}
close(FH);

open(OUT, ">break_point_master_table.html");

print OUT '<!DOCTYPE     html PUBLIC "-//W3C//DTD XHTML 1.0 strict//EN"',"\n";
print OUT '"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',"\n";
print OUT '',"\n";
print OUT '<html xmlns="http://www.w3.org/1999/xhtml">',"\n";
print OUT '',"\n";
print OUT '<head>',"\n";
print OUT '     <title>Break Point List</title>',"\n";
print OUT '     <meta http-equiv="Cntent-Type" content="text/html; charset=utf=8" />',"\n";
print OUT '</head>',"\n";
print OUT '<body>',"\n";
print OUT '',"\n";
print OUT '<h2>Break Point List</h2>',"\n";

print OUT "<p>\n";
print OUT "During the course of Chandra operation, there were several incidences which caused  a sudden jump on \n";
print OUT "trending envelopes. The table below lists all incidences we used in the trending. If the cause is \n";
print OUT "clear, we indicated in the second column. A system named in the \"affected systems\" column is linked \n";
print OUT "to a list of msids of that system so that you can see which msids are affected by that incidence. \n";
print OUT "</p>\n";


print OUT '<br />',"\n";

print OUT '<p>',"\n";
print OUT '<table border=1 cellpadding=4 cellspacing=4>',"\n";

print OUT '<tr>',"\n";
print OUT '<th>Date</th>',"\n";
print OUT '<th>Reason</th>',"\n";
print OUT '<th>Affected Systems</th>',"\n";
print OUT '</tr>',"\n";

for($i = 0; $i < $b_cnt; $i++){
	print OUT "<tr>\n";
	print OUT "<th>$date_b[$i]</th>\n";
	OUTER:
	for($j = 0; $j < $c_cnt; $j++){
		if($date_b[$i] == $date_c[$j]){
			$reason = $cause[$j];
			if($reason =~ /NA/i){
				$reason = '&#160';
			}
			last OUTER;
		}
	}
	print OUT "<td>$reason</td>\n";
	print OUT "<td>\n";
	
	@system = split(/\s+/, $entry[$i]);
	print OUT "<table border=0 cellspacing='2' cellpadding='4'>\n";
	$k = 0;
	foreach $ent (@system){
		if($k == 0){
			print OUT "<tr>\n";
		}

		$html_address = 'http://asc.harvard.edu/mta_days/mta_envelope_trend/break_point_tables/';
		$name         = uc($ent);
		$html_address = "$html_address"."$name".'.html';
		
		$line         = '<a href='."$html_address".'>'."$name".'</a>';

		print OUT "<td>$line</td>\n";
		$k++;
		if($k > 4){
			$k = 0;
			print OUT "</tr>\n";
		}
	}
	if($k != 0){
		print OUT "</tr>\n";
	}
	print OUT "</table>\n";

	print OUT "</td>\n";
	print OUT "</tr>\n";
}

print OUT "</table>\n";
print OUT "</p>\n";
print OUT '<br /> <br />',"\n";

print OUT '<a href="http://asc.harvard.edu/mta_days/mta_envelope_trend/mta_envelope_trend.html">Back To Main Page</a>',"\n";

print OUT "</body>\n";
print OUT "</html>\n";

close(OUT);

system("mv break_point_master_table.html /data/mta_www/mta_envelope_trend/");


