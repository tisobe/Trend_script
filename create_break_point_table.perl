#!/usr/bin/perl 

#################################################################################################################
#														#
#	create_break_point_table.perl: create a html pages which lists msids and their break points.		#
#														#
#		author: t. isobe (tisobe@cfa.harvard.edu)							#
#														#
#		last update: Jan 15, 2013									#
#														#
#################################################################################################################

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
#--- read a list of main categories
#
open(FH, "$save_dir/Break_points/mta_main_msids");

@list1 = ();
while(<FH>){
	chomp $_;
	$category = lc($_);
	$input = "$save_dir/Break_points/"."$category".'_list';
	push(@list1, $input);
}
close(FH);

#
#--- read a list of secondary categories
#
open(FH, "$save_dir/Break_points/mta_secondary_msids");

@list2 = ();
while(<FH>){
	chomp $_;
	$category = lc($_);
	$input = "$save_dir/Break_points/"."$category".'_list';
	push(@list2, $input);
}
close(FH);

#
#--- start writing a main html page.
#

open(OUT, '>$www_dir/break_point_list.html');

print OUT '<!DOCTYPE	 html PUBLIC "-//W3C//DTD XHTML 1.0 strict//EN"',"\n";
print OUT '"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',"\n";
print OUT "\n";
print OUT '<html xmlns="http://www.w3.org/1999/xhtml">',"\n";
print OUT "\n";
print OUT '<head>',"\n";
print OUT '	<title>Break Point List Table</title>',"\n";
print OUT '	<meta http-equiv="Cntent-Type" content="text/html; charset=utf=8" />',"\n";
print OUT '</head>',"\n";
print OUT '<body>',"\n";
print OUT "\n";

print OUT '<h2>Break Point List Table</h2>',"\n";


print OUT "<p>To find the break points of each msid, select a category from the tables below. \n";
print OUT "It will open up a new window for the table of the category which lists all msids and their break points. \n";
print OUT "If the break point column is empty, that particular msid does not have any break point \n";
print OUT "from year 2000. \n";
print OUT '<br /> <br />',"\n";

print OUT '<h3>MTA Main Data Trend Break Point List Table</h3>',"\n";

#
#---- start creating the main category table
#
print OUT '<table border=1 cellpadding=4 cellspacing=4>',"\n";

$j = 0;
OUTER:
foreach $ent (@list1){
	@atemp = split(/Break_points\//, $ent);
	$name  = $atemp[1];
	if($name =~ /input/i){
		next OUTER;
	}
	$name  =~ s/_list//;
	$name  = uc($name);
	$table = "$name".'.html';
	$link = '<a href="./break_point_tables/'."$table".'" target="break">'."$name".'</a>';

#
#--- create a sub html page for each category
#
	create_subpage($ent);

	if($j == 0){
		print OUT "<tr>\n";
		print OUT "<td>\n";
	}else{
		print OUT "</td>\n";
		print OUT "<td>\n";
	}
	print OUT "$link\n";

	if($j == 5){
		$j = 0;
		print OUT "</td>\n";
		print OUT "</tr>\n";
	}else{
		$j++;
		print OUT "</td>\n";
	}
}

for($k = $j; $k < 6; $k++){
	print OUT '<td>&#160</td>',"\n";
}
print OUT "</tr>\n";
print OUT "</table>\n";
print OUT "<br /><br />\n";

#
#--- start creating the secondary category table
#

print OUT '<h3>MTA Secondary Data Trend Break Point List Table</h3>',"\n";

print OUT '<table border=1 cellpadding=4 cellspacing=4>',"\n";

$j = 0;
OUTER:
foreach $ent (@list2){
	@atemp = split(/Break_points\//, $ent);
	$name  = $atemp[1];
	if($name =~ /input/i){
		next OUTER;
	}
	$name  =~ s/_list//;
	$name  = uc($name);
	$table = "$name".'.html';
	$link = '<a href="./break_point_tables/'."$table".'" target="break">'."$name".'</a>';

#
#--- create a sub html page for each category
#
	create_subpage($ent);

	if($j == 0){
		print OUT "<tr>\n";
		print OUT "<td>\n";
	}else{
		print OUT "</td>\n";
		print OUT "<td>\n";
	}
	print OUT "$link\n";

	if($j == 5){
		$j = 0;
		print OUT "</td>\n";
		print OUT "</tr>\n";
	}else{
		$j++;
		print OUT "</td>\n";
	}
}

for($k = $j; $k < 6; $k++){
	print OUT '<td>&#160</td>',"\n";
}
print OUT "</tr>\n";
print OUT "</table>\n";
print OUT "<br />\n";


print OUT "<a href='http://asc.harvard.edu/mta_days/mta_envelope_trend/mta_envelope_trend.html'>Back to Main Page</a>\n";

print OUT "</body>\n";
print OUT "</html>\n";
close(OUT);

system("chgrp mtagroup $www_dir/*html $www_dir/break_point_tables/*");


######################################################################################################
### create_subpage: create a table for a gien category                                             ###
######################################################################################################

sub create_subpage{

	my($path, $name, $i, $j, $link);
	($path) = @_;

	@atemp = split(/Break_points\//, $path);
	$name  = $atemp[1];
	$name  =~ s/_list//;
	$name  = uc($name);
	$table = "$name".'.html';
	$link  = "$www_dir/break_point_tables/"."$table";

	open(OUT2, ">$link");

	print OUT2 '<!DOCTYPE     html PUBLIC "-//W3C//DTD XHTML 1.0 strict//EN"',"\n";
	print OUT2 '"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',"\n";
	print OUT2 "\n";
	print OUT2 '<html xmlns="http://www.w3.org/1999/xhtml">',"\n";
	print OUT2 "\n";
	print OUT2 '<head>',"\n";
	print OUT2 '     <title>',"$name Break Point List",'</title>',"\n";
	print OUT2 '     <meta http-equiv="Cntent-Type" content="text/html; charset=utf=8" />',"\n";


	print OUT2 "<script type='text/javascript'>\n";
	print OUT2 "function WindowOpener(imgname) {\n";
	print OUT2 "	msgWindow = open('','displayname','toolbar=no,directories=no,menubar=no,location=no,scrollbars=no,status=no,width=650,height=470,resize=no');\n";
	print OUT2 "	msgWindow.document.clear();\n";
	print OUT2 "	msgWindow.document.write('<html><title>Trend plot:   '+imgname+'</title>');\n";
	print OUT2 "	msgWindow.document.write(\"<body bgcolor='white'>\");\n";
	print OUT2 "	msgWindow.document.write(\"<p><img src='../Full_range/\"+imgname+\"' border=0>\")\n";
	print OUT2 "    msgWindow.document.write(\"</p></body></html>\")\n";
	print OUT2 "	msgWindow.document.close();\n";
	print OUT2 "	msgWindow.focus();\n";
	print OUT2 "}\n";
	print OUT2 "</script>\n";

	print OUT2 '</head>',"\n";
	print OUT2 '<body>',"\n";
	print OUT2 "\n";
	
	print OUT2 '<h2>',"$name Break Point List",'</h2>',"\n";
	print OUT2 '<br /> <br />',"\n";
	
	print OUT2 '<table border=1 cellpadding=4 cellspacing=4>',"\n";

	print OUT2 '<tr>',"\n";
	print OUT2 '<td>MSID</td>',"\n";
	print OUT2 '<td>Break Point(s)</td>',"\n";
	print OUT2 '</tr>',"\n";
	print OUT2 '<tr>',"\n";

	open(IN, "$path");
	while(<IN>){
		chomp $_;
		@btemp = split(/\s+/, $_);
		$msid  = $btemp[0];
		print OUT2 "<td>\n";

		$low_msid = lc($msid);
		$imgname = "$name".'/Plots/'."$low_msid".'_plot.gif';
		print OUT2 "<a href=\"javascript:WindowOpener('$imgname')\">$msid</a>\n";

		print OUT2 "</td>\n";
		shift(@btemp);
		shift(@btemp);
		if($btemp[0] == 2000){
			shift(@btemp);
		}
		$cnt = 0;
		foreach(@btemp){
			$cnt++;
		}
		if($cnt == 0){
			print OUT2 "<td>&#160</td>\n";
		}else{
			print OUT2 "<td>";
			foreach $date (@btemp){
				print OUT2 "$date\t";
			}
			print OUT2 "</td>\n";
		}
		print OUT2 "</tr>\n";
	}
	close(IN);
	print OUT2 '</table>',"\n";
	print OUT2 '<br /><br />',"\n";
	print OUT2 '</body>',"\n";
	print OUT2 '</html>',"\n";
	close(OUT2);
}
				
			






