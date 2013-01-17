#!/usr/bin/perl 

#########################################################################################################
#													#
#	create_break_point_master_html.perl: create a master table of breaking point listing		#
#													#
#		author: t. isobe (tisobe@cfa.harvard.edu)						#
#													#
#		last update: Jan 15, 2013 								#
#													#
#########################################################################################################

#
#--- if this is a test case, set comp_test to "test"
#

$comp_test = $ARGV[0];
chomp $comp_test;

#
#--- directory setting
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


#
#--- read a table of cause of the break
#

open(FH, "$save_dir/break_point_cause");
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

open(FH, "$save_dir/break_point_table");
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

open(OUT, ">$www_dir/break_point_master_table.html");

print OUT '<!DOCTYPE  html>',"\n";
print OUT "<html>\n";
print OUT '<head>',"\n";
print OUT '     <title>Break Point List</title>',"\n";
print OUT "     <meta http-equiv='Content-Type' content='text/html; charset=utf-8' />\n";
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

print OUT '<div style="padding-top:20px;padding-bottom:20px">',"\n";
print OUT '<table border=1>',"\n";

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
				$reason = '&#160;';
			}
			last OUTER;
		}
	}
	print OUT "<td>$reason</td>\n";
	print OUT "<td>\n";
	
	@system = split(/\s+/, $entry[$i]);
	print OUT "<table style='border-width:0px'>\n";
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
print OUT "</div>\n";

print OUT '<p><a href="http://asc.harvard.edu/mta_days/mta_envelope_trend/mta_envelope_trend.html">Back To Main Page</a></p>',"\n";

print OUT "</body>\n";
print OUT "</html>\n";

close(OUT);
