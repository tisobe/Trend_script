#!/opt/local/bin/perl

#########################################################################################################
#													#
#	find_limit_envelope_mk_html.perl: making a web page for the envelope fitting			#
#													#
#		author: t. isobe (tisobe@cfa.harvard.edu)						#
#													#
#		last update: Mar 22, 2011								#
#													#
#########################################################################################################

#
#--- set directory location etc
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


$inlist   = "$save_dir/dataseeker_input_list";
$inlist2  = "$save_dir/deriv_input_list";

#
#---- find today's year date
#

($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

$this_year = $uyear + 1900;
$ydate     = $uyday + 1;
$chk       = 4.0 * int (0.25 * $this_year);
if($chk == $this_year){
	$y_length = 366;
}else{
	$y_length = 365;
}

$today     = $this_year + ($ydate + 1)/$y_length;     #---- add one day to make sure include 
						      #---- tasted date is included

#
#---- read all about limit violation
#

open(FH, "$data_dir/Results/full_range_results");

while(<FH>){
	chomp $_;
	@atemp = split(/<>/, $_);
	if($atemp[0] =~ /_AVG/){
		@btemp = split(/_AVG/, $atemp[0]);
	}else{
		@btemp = split(/_avg/, $atemp[0]);
	}

	$low   = $atemp[9];
	$top   = $atemp[10];
	$name  = lc($btemp[0]);
	%{limit.$name} = (low =>["$low"], top => ["$top"]);
}
close(FH);

#
#---- open the top html page
#

open(TOP, ">$www_dir/mta_envelope_trend.html");
print TOP "<html>\n";
print TOP "<body>\n\n";
print TOP "<h2>MTA Trending: Envelope Trending</h2><br>\n\n";

print TOP "<p>\n";

print TOP "<b>The upper and lower envelope on the data are esitimated as follows.</b>\n";
print TOP "</p>\n";

print TOP "<ul>\n";
print TOP "<li>\n";
print TOP 'Extract data using dataseeker. The dataseeker data are 5 min',"\n";
print TOP 'averaged values.',"\n";

print TOP "<li>\n";
print TOP 'Check the data range. If a data set contains zero and/or positive values only,',"\n";
print TOP 'check how many are "zero". If more than or equal to 3% of data',"\n";
print TOP 'are non-zero, then all "zero" data points are dropped from the data set.',"\n";
print TOP 'Otherwise, keep all data points.',"\n";

print TOP "<li>\n";
print TOP 'For full range data, the data are further averaged out to one hour',"\n";
print TOP 'interval. For the quarterly and weekly data, the 5 min average is used.',"\n";

print TOP "<li>\n";
print TOP 'Divide the data into sub data sets. Due to change of environments,',"\n";
print TOP 'the data often have discontinuities. These discontinuities are identified',"\n";
print TOP 'by eye, and recorded in a file for each data set. Using these',"\n";
print TOP 'breaking points, divide the data into sub data sets.',"\n";

print TOP "<li>\n";
print TOP 'Find the minimum and maximum data points for a given interval.',"\n";
print TOP 'For the full range data set, one week is the length of the interval,',"\n";
print TOP 'two days for quarterly, and 30 mins for the weekly data set.',"\n";

print TOP "<li>\n";
print TOP 'Fit a regression line on the maximum or minimum data points.',"\n";
print TOP 'Although a straight line is good for most data, there are a dozen cases',"\n";
print TOP 'which required a quadratic line fit.',"\n";

print TOP "<li>\n";
print TOP 'Using the fitted result, find a standard deviation around the line, then',"\n";
print TOP 'select out data point outside of an estimated value (from the fitted',"\n";
print TOP 'line) plus 0.2 * standard deviation.',"\n";

print TOP "<li>\n";
print TOP 'Re-fit a line to the selected data set, and the result is given',"\n";
print TOP 'as an outer envelope.',"\n";

print TOP "<li>\n";
print TOP 'Extend the envelope line for the next 10 years, and check whether',"\n";
print TOP 'the envelope will violate upper or lower yellow limits. If so,',"\n";
print TOP 'find an approximate date of the violation. Note that this',"\n";
print TOP 'estimation is done with the full range data; quarterly and weekly',"\n";
print TOP 'data are not used for this purpose.',"\n";

print TOP "</ul>\n";

print TOP "<ul>\n";
print TOP "<li>\n";
print TOP "For the secondary data sets which are computed from the main data sets (e.g., gradients)\n";
print TOP "or selected with extra criteria (e.g., HRC I/S/OFF), only difference is that\n";
print TOP "the data are obtained from /data/mta4/Deriv/, not from dataseeker.\n";
print TOP "Most data are hour averaged data, and hence lower in resolution, especially for the weekly data.\n";
print TOP "</ul>\n";

print TOP "<ul>\n";
print TOP "<li>\n";
print TOP "Estimations of the envelopes of the full range data are updated once a month, \n";
print TOP "those of the quaterly data are updated weekly, and those of the weekly data are updated daily.\n";
print TOP "</ul>\n";


print TOP "<p>\n";
print TOP "If you like to check all yellow violations, go to \n";
print TOP "<a href='http://asc.harvard.edu/mta_days/mta_envelope_trend/violation_table.html'>\n";
print TOP "MTA Estimated Date of Yellow Limit Violations</a> page.\n";
#print TOP " or \n";
#print TOP "<a href='http://asc.harvard.edu/mta_days/mta_envelope_trend/SnapShot/violation_table.html'>\n";
#print TOP "Snapshot Estimated Date of Yellow Limit Violations</a> page.\n";
print TOP "</p>\n";

print TOP "<p>\n";
print TOP "If you like to check the break points of the plots, go to \n";
print TOP "<a href='http://asc.harvard.edu/mta_days/mta_envelope_trend/break_point_master_table.html'>\n";
print TOP "Break Point Table</a>.\n";
print TOP "</p>\n";



print TOP "<hr><BR>\n";

print TOP "<center>\n";
print TOP "<table cellspacing=30 >\n";
print TOP "<tr><th>\n";
print TOP "<h2>MTA Main Data Trend</h2>\n";
print TOP "</th><th>\n";
print TOP "<h2>MTA Secondary Data Trend</h2>\n";
print TOP "</th></tr>\n";
print TOP "<tr><td valign=top>\n";

print TOP "<center>\n";
print TOP "<table border=2 cellpadding=2 cellspan=2>\n";

$k = 0; 
open(FH, "$inlist");
while(<FH>){
	chomp $_;
	$infile = $_;

	@name_list = ();
	@in_list   = ();
	$cnt       = 0;
#
#---- read indivisual entries
#
	open(IN, "$save_dir/Break_points/$infile");
	while(<IN>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		$msid  = lc($atemp[0]);
		$name  = "$msid".'_plot.gif';
		push(@name_list, $msid);
		push(@in_list, $name);
		$cnt++;
	}
	close(IN);

	@atemp    = split(/_list/, $infile);
	$data_dir = uc ($atemp[0]);
	$table    = "$atemp[0]".'_table.html';

	$chk = 2.0 * int(0.5 * $k);
	if($chk == $k){
		print TOP "<tr><td><a href='./Html_dir/$table'>$data_dir</a></td>\n";
	}else{
		print TOP "<td>&#160</td>\n";
		print TOP "<td><a href='./Html_dir/$table'>$data_dir</a></td></tr>\n";
	}
	$k++;
#
#---- create indivisual html pages
#
	open(OUT, ">$www_dir/Html_dir/$table");

	print OUT "<html>\n";
	print OUT "<body>\n\n";

#
#--- java script header
#
	print OUT '<script language="JavaScript">',"\n";
	print OUT '  function WindowOpener(imgname) {',"\n";
	print OUT '    msgWindow = open("","displayname","toolbar=no,directories=no,menubar=no,location=no,scrollbars=no,status=no,width=750,height=600,resize=no");',"\n";
	print OUT '    msgWindow.document.clear();',"\n";
	print OUT '    msgWindow.document.write("<HTML><TITLE>Trend plot:   "+imgname+"</TITLE>");',"\n";
	print OUT "    msgWindow.document.write(\"<BODY TEXT='white' BGCOLOR='white'>\");","\n";
	print OUT "    msgWindow.document.write(\"<IMG SRC='\"+imgname+\"' BORDER=0><P></BODY></HTML>\");","\n";
	print OUT '    msgWindow.document.close();',"\n";
	print OUT '    msgWindow.focus();',"\n";
	print OUT '  }',"\n";
	print OUT '</script>',"\n";
	print OUT "\n\n";


	print OUT "<h2>$data_dir</h2>\n";
	print OUT "<table border=1 cellpadding=2 cellspacing=2>\n";
	print OUT "<tr><th>MSID</th>";
	print OUT "<th>Entire Period</th>";
	print OUT "<th>Last Quarter</th>";
	print OUT "<th>Recent Week</th>";
	print OUT "<th>Limit Violation</th></tr>\n";
	
	OUTER:
	for($i = 0; $i < $cnt; $i++){
	
		$low = ${limit.$name_list[$i]}{low}[0];
		$top = ${limit.$name_list[$i]}{top}[0];
	
		$warning = 0;
		if($low =~ /\d/ || $top =~ /\d/){
			$warning = 1;
		}
	
		if($warning == 0){
			print OUT "<tr>\n<th>$name_list[$i]</th>\n";
		}else{
			print OUT "<tr><th><font color=red>$name_list[$i]</font></th>\n";
		}
	
		$h_name = '../Full_range/'."$data_dir".'/Plots/'."$in_list[$i]";
		print OUT "<td><a href=\"javascript:WindowOpener('$h_name')\">Full_range</a></td>\n";
	
		$h_name = '../Quarterly/'."$data_dir".'/Plots/'."$in_list[$i]";
		print OUT "<td><a href=\"javascript:WindowOpener('$h_name')\">Last Quarter</a></td>\n";
	
		$h_name = '../Weekly/'."$data_dir".'/Plots/'."$in_list[$i]";
		print OUT "<td><a href=\"javascript:WindowOpener('$h_name')\">Recent Week</a></td>\n";
	
#
#---- printing upper and/or lower limit violations
#
		if($warning == 0){
			print OUT "<td>no violation</td>\n";
		}else{
			print OUT "<td>";
			$chk = 0;
			if($low =~ /\d/){
				if($low <= $today){
					print OUT "<font color=red>Low: in Violation</font>";
				}else{
					$out = sprintf "%5.2f", $low;
					print OUT  "<font color=red>Low: $out</font>";
				}
				$chk = 1;
			}
			if($top =~ /\d/){
				if($chk > 0){
					print OUT "<br>";
				}
				if($top <= $today){
					print OUT "<font color=red>Top:in  Violation</font>";
				}else{
					$out = sprintf "%5.2f", $top;
					print OUT  "<font color=red>Top: $out</font>";
				}
			}
			print OUT "</td>\n";
		}
		print OUT "</tr>\n";
	}
	print OUT "</table>\n";
	print OUT "<br><br>\n";
	print OUT "<a href='http://asc.harvard.edu/mta_days/mta_envelope_trend/mta_envelope_trend.html'>Back to a Top Page</a>\n";
	close(OUT);
}

print TOP "</table>\n";
print TOP "</center>\n";

print TOP "</td><td valign=top>\n";


#
#----- data from /data/mta4/Derive
#


print TOOP "<center>\n";
print TOP "<table border=2 cellpadding=2 cellspan=2>\n";

$k = 0; 
open(FH, "$inlist2");
while(<FH>){
	chomp $_;
	$infile = $_;

	@name_list = ();
	@in_list   = ();
	$cnt       = 0;
#
#---- read indivisual entries
#
	open(IN, "$save_dir/Break_points/$infile");
	while(<IN>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		$msid  = lc($atemp[0]);
		$name  = "$msid".'_plot.gif';
		push(@name_list, $msid);
		push(@in_list, $name);
		$cnt++;
	}
	close(IN);

	@atemp    = split(/_list/, $infile);
	$data_dir = uc ($atemp[0]);
	$table    = "$atemp[0]".'_table.html';

	$chk = 2.0 * int(0.5 * $k);
	if($chk == $k){
		print TOP "<tr><td><a href='./Html_dir/$table'>$data_dir</a></td>\n";
	}else{
		print TOP "<td>&#160</td>\n";
		print TOP "<td><a href='./Html_dir/$table'>$data_dir</a></td></tr>\n";
	}
	$k++;
#
#---- create indivisual html pages
#
	open(OUT, ">$www_dir/Html_dir/$table");

	print OUT "<html>\n";
	print OUT "<body>\n\n";

#
#--- java script header
#

	print OUT '<script language="JavaScript">',"\n";
	print OUT '  function WindowOpener(imgname) {',"\n";
	print OUT '    msgWindow = open("","displayname","toolbar=no,directories=no,menubar=no,location=no,scrollbars=no,status=no,width=750,height=600,resize=no");',"\n";
	print OUT '    msgWindow.document.clear();',"\n";
	print OUT '    msgWindow.document.write("<HTML><TITLE>Trend plot:   "+imgname+"</TITLE>");',"\n";
	print OUT "    msgWindow.document.write(\"<BODY TEXT='white' BGCOLOR='white'>\");","\n";
	print OUT "    msgWindow.document.write(\"<IMG SRC='\"+imgname+\"' BORDER=0><P></BODY></HTML>\");","\n";
	print OUT '    msgWindow.document.close();',"\n";
	print OUT '    msgWindow.focus();',"\n";
	print OUT '  }',"\n";
	print OUT '</script>',"\n";
	print OUT "\n\n";

	print OUT "<h2>$data_dir</h2>\n";
	print OUT "<table border=1 cellpadding=2 cellspacing=2>\n";
	print OUT "<tr><th>MSID</th>";
	print OUT "<th>Entire Period</th>";
	print OUT "<th>Last Quarter</th>";
	print OUT "<th>Recent Week</th>";
	print OUT "<th>Limit Violation</th></tr>\n";
	
	OUTER:
	for($i = 0; $i < $cnt; $i++){
		$name_ext = $name_list[$i];
#
#---- we need a special treatement for HRC I/S/OFF cases (/data/mta4/Deriv/ data only)
#
		if($data_dir =~ /_i/i){
			$name_ext = 'hrci.'."$name_list[$i]";
		}elsif($data_dir =~ /_s/i){
			$name_ext = 'hrcs.'."$name_list[$i]";
		}elsif($data_dir =~ /_off/i){
			$name_ext = 'hrco.'."$name_list[$i]";
		}
	
		$low = ${limit.$name_ext}{low}[0];
		$top = ${limit.$name_ext}{top}[0];
	
		$warning = 0;
		if($low =~ /\d/ || $top =~ /\d/){
			$warning = 1;
		}
	
		if($warning == 0){
			print OUT "<tr>\n<th>$name_list[$i]</th>\n";
		}else{
			print OUT "<tr><th><font color=red>$name_list[$i]</font></th>\n";
		}
	
		$h_name = '../Full_range/'."$data_dir".'/Plots/'."$in_list[$i]";
		print OUT "<td><a href=\"javascript:WindowOpener('$h_name')\">Full_range</a></td>\n";
	
		$h_name = '../Quarterly/'."$data_dir".'/Plots/'."$in_list[$i]";
		print OUT "<td><a href=\"javascript:WindowOpener('$h_name')\">Last Quarter</a></td>\n";
	
		$h_name = '../Weekly/'."$data_dir".'/Plots/'."$in_list[$i]";
		print OUT "<td><a href=\"javascript:WindowOpener('$h_name')\">Recent Week</a></td>\n";
	
#
#---- printing upper and/or lower limit violations
#
		if($warning == 0){
			print OUT "<td>no violation</td>\n";
		}else{
			print OUT "<td>";
			$chk = 0;
			if($low =~ /\d/){
				if($low <= $today){
					print OUT "<font color=red>Low: in Violation</font>";
				}else{
					$out = sprintf "%5.2f", $low;
					print OUT  "<font color=red>Low: $out</font>";
				}
				$chk = 1;
			}
			if($top =~ /\d/){
				if($chk > 0){
					print OUT "<br>";
				}
				if($top <= $today){
					print OUT "<font color=red>Top: in Violation</font>";
				}else{
					$out = sprintf "%5.2f", $top;
					print OUT  "<font color=red>Top: $out</font>";
				}
			}
			print OUT "</td>\n";
		}
		print OUT "</tr>\n";
	}
	print OUT "</table>\n";
	print OUT "<br><br>\n";
	print OUT "<a href='http://asc.harvard.edu/mta_days/mta_envelope_trend/mta_envelope_trend2.html'>Back to a Top Page</a>\n";
	close(OUT);
}

print TOP "</td></tr>\n";
print TOP "</table>\n";
print TOP "</center>\n";

print TOP "</td></tr>\n";
print TOP "<tr><td>\n";


#-------------------------------------------------------------------------------

if($xxxx == 99999){		#---- a fake loop to ignore the following section.
#
#---- read all about limit violation for op
#

open(FH, "$data_dir/Results/full_range_results");

while(<FH>){
	chomp $_;
	@atemp = split(/<>/, $_);
	if($atemp[0] =~ /_AVG/){
		@btemp = split(/_AVG/, $atemp[0]);
	}else{
		@btemp = split(/_avg/, $atemp[0]);
	}

	$low   = $atemp[9];
	$top   = $atemp[10];
	$name  = lc($btemp[0]);
	%{limit.$name} = (low =>["$low"], top => ["$top"]);
}
close(FH);



print TOP "<hr><BR>\n";

print TOP "<center>\n";
print TOP "<table cellspacing=30 >\n";
print TOP "<tr><th>\n";
print TOP "<h2>Snapshot  Data Trend</h2>\n";
print TOP "</th><th>\n";
print TOP "</th></tr>\n";
print TOP "<tr><td valign=top>\n";

print TOP "<table border=2 cellpadding=2 cellspan=2>\n";

$k = 0; 
open(FH, "$inlist");
while(<FH>){
	chomp $_;
	$infile = $_;

	@name_list = ();
	@in_list   = ();
	$cnt       = 0;
#
#---- read indivisual entries
#
	open(IN, "$save_dir/Break_points/$infile");
	while(<IN>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		$msid  = lc($atemp[0]);
		$name  = "$msid".'_plot.gif';
		push(@name_list, $msid);
		push(@in_list, $name);
		$cnt++;
	}
	close(IN);

	@atemp    = split(/_list/, $infile);
	$data_dir = uc ($atemp[0]);
	$table    = "$atemp[0]".'_table.html';

	$chk = 2.0 * int(0.5 * $k);
	if($chk == $k){
		print TOP "<tr><td><a href='./Html_dir2/$table'>$data_dir</a></td>\n";
	}else{
		print TOP "<td>&#160</td>\n";
		print TOP "<td><a href='./Html_dir2/$table'>$data_dir</a></td></tr>\n";
	}
	$k++;
#
#---- create indivisual html pages
#
	open(OUT, ">$www_dir/Html_dir2/$table");

	print OUT "<html>\n";
	print OUT "<body>\n\n";

#
#--- java script header
#
	print OUT '<script language="JavaScript">',"\n";
	print OUT '  function WindowOpener(imgname) {',"\n";
	print OUT '    msgWindow = open("","displayname","toolbar=no,directories=no,menubar=no,location=no,scrollbars=no,status=no,width=750,height=600,resize=no");',"\n";
	print OUT '    msgWindow.document.clear();',"\n";
	print OUT '    msgWindow.document.write("<HTML><TITLE>Trend plot:   "+imgname+"</TITLE>");',"\n";
	print OUT "    msgWindow.document.write(\"<BODY TEXT='white' BGCOLOR='white'>\");","\n";
	print OUT "    msgWindow.document.write(\"<IMG SRC='\"+imgname+\"' BORDER=0><P></BODY></HTML>\");","\n";
	print OUT '    msgWindow.document.close();',"\n";
	print OUT '    msgWindow.focus();',"\n";
	print OUT '  }',"\n";
	print OUT '</script>',"\n";
	print OUT "\n\n";


	print OUT "<h2>$data_dir</h2>\n";
	print OUT "<table border=1 cellpadding=2 cellspacing=2>\n";
	print OUT "<tr><th>MSID</th>";
	print OUT "<th>Entire Period</th>";
	print OUT "<th>Last Quarter</th>";
	print OUT "<th>Recent Week</th>";
	print OUT "<th>Limit Violation</th></tr>\n";
	
	OUTER:
	for($i = 0; $i < $cnt; $i++){
	
		$low = ${limit.$name_list[$i]}{low}[0];
		$top = ${limit.$name_list[$i]}{top}[0];
	
		$warning = 0;
		if($low =~ /\d/ || $top =~ /\d/){
			$warning = 1;
		}
	
		if($warning == 0){
			print OUT "<tr>\n<th>$name_list[$i]</th>\n";
		}else{
			print OUT "<tr><th><font color=red>$name_list[$i]</font></th>\n";
		}
	
		$h_name = '../SnapShot/Full_range/'."$data_dir".'/Plots/'."$in_list[$i]";
		print OUT "<td><a href=\"javascript:WindowOpener('$h_name')\">Full_range</a></td>\n";
	
		$h_name = '../SnapShot/Quarterly/'."$data_dir".'/Plots/'."$in_list[$i]";
		print OUT "<td><a href=\"javascript:WindowOpener('$h_name')\">Last Quarter</a></td>\n";
	
		$h_name = '../SnapShot/Weekly/'."$data_dir".'/Plots/'."$in_list[$i]";
		print OUT "<td><a href=\"javascript:WindowOpener('$h_name')\">Recent Week</a></td>\n";
	
#
#---- printing upper and/or lower limit violations
#
		if($warning == 0){
			print OUT "<td>no violation</td>\n";
		}else{
			print OUT "<td>";
			$chk = 0;
			if($low =~ /\d/){
				if($low <= $today){
					print OUT "<font color=red>Low: in Violation</font>";
				}else{
					$out = sprintf "%5.2f", $low;
					print OUT  "<font color=red>Low: $out</font>";
				}
				$chk = 1;
			}
			if($top =~ /\d/){
				if($chk > 0){
					print OUT "<br>";
				}
				if($top <= $today){
					print OUT "<font color=red>Top:in  Violation</font>";
				}else{
					$out = sprintf "%5.2f", $top;
					print OUT  "<font color=red>Top: $out</font>";
				}
			}
			print OUT "</td>\n";
		}
		print OUT "</tr>\n";
	}
	print OUT "</table>\n";
	print OUT "<br><br>\n";
	print OUT "<a href='http://asc.harvard.edu/mta_days/mta_envelope_trend/mta_envelope_trend.html'>Back to a Top Page</a>\n";
	close(OUT);
}


print TOP "</td></tr>\n";
print TOP "</table>\n";

}		#------ end of the fake loop $xxxxx == 99999

print TOP "</table>\n";
print TOP "</center>\n";

print TOP "<br><hr><br>\n";
print TOP "Web Site Last Update: May 01, 2009<br>\n";
print TOP "If you have questions, contact T. Isobe (<a href='mailto:isobe\@head.cfa.harvard.edu'>";
print TOP "isobe\@head.cfa.harvard.edu</a>)\n";

close(TOP);
close(FH);
