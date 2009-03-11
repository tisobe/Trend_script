#!/usr/bin/perl 

#########################################################################################
#											#
#	find_limit_violation_table.perl: create a html table of yellow violation	#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		last update: Mar 11, 2009						#
#											#
#########################################################################################


#
#---- directory
#

$bin_dir  = '/data/mta/MTA/bin/';
$mta_dir  = '/data/mta/Script/Fitting/Trend_script/';
$save_dir = "$mta_dir/Save_data/";
$www_dir1 = '/data/mta_www/mta_envelope_trend/';
$www_dir2 = '/data/mta_www/mta_envelope_trend2/';

#
#---- read argument
#

$lim_slc  = $ARGV[0];	#--- which limit table to use mta or op

#
#---- select a limit table ans output web directory
#

if($lim_slc =~ /mta/){
	$www_dir = $www_dir1;
	$limit_table = '/data/mta/Test/op_limits.db';
}else{
	$www_dir = $www_dir2;
	$limit_table = "$save_dir/limit_table";
}

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

$chk_date  = $this_year + ($ydate + 3)/$y_length;     #---- add a few days to make sure include
                                                      #---- tasted date is included

$chk_date2 = $chk_date + 2;

#
#---- find lower and upper limits
#

open(FH, "$limit_table");

OUTER:
while(<FH>){
        chomp $_;
        @l_temp = split(/\s+/, $_);
        if($l_temp[0] =~ /\#/){
                next OUTER;
        }
	$name   = lc($l_temp[0]);
        $y_low  = $l_temp[1];
        $y_top  = $l_temp[2];
        $r_low  = $l_temp[3];
        $r_top  = $l_temp[4];

	%{limit.$name} = (y_low =>["$y_low"],
			  y_top =>["$y_top"],
			  r_low =>["$r_low"],
			  r_top =>["$r_top"]
			);

}
close(FH);


#
#---- find violations
#

open(FH, "$www_dir/full_range_results");
while(<FH>){
	chomp $_;
	@atemp = split(/<>/, $_);
	%{data.$atemp[0]} = (
				lower => ["$atemp[9]"],
			     	upper => ["$atemp[10]"]
			    );
}
close(FH);


$input =` cat $mta_dir/Save_data/dataseeker_input_list $mta_dir/Save_data/deriv_input_list`;
@main_list = split(/\s+/, $input);

open(OUT, ">$www_dir/violation_table.html");
print OUT "<html>\n";
print OUT "<body>\n";

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


print OUT "<h2>Estimated Date of Yellow Limit Violations</h2>\n";
print OUT "<br>\n";
print OUT "<p>\n";
print OUT 'Following tables show a potential yellow limit violation date for each msid.',"\n";
print OUT 'The unit is in Years. If the values are already in the yellow limit, it',"\n";
print OUT 'is marked by <font color=red>"Already in Violation"</font>.',"\n";
print OUT "</p>\n";
print OUT "<p>\n";
print OUT 'For the case that  estimated violation date is less than 2 years, it is',"\n";
print OUT 'also colored in <b><font color=red>RED</font></b>.',"\n";
print OUT "</p>\n";


foreach $ent (@main_list){
	open(FH, "$mta_dir/Save_data/Break_points/$ent");
	@msid  = ();
	$v_cnt = 0;
	while(<FH>){
		chomp $_;
		@btemp = split(/\s+/, $_);
		$name  = $btemp[0];
		$name2 = "$name".'_avg';
		$name2 = lc($name2);
		$name3 = uc($name2);

		$bot   = ${data.$name2}{lower}[0];
		$top   = ${data.$name2}{upper}[0];
		if($bot =~ /\d/ || $top =~ /\d/){
			push(@msid, $name2);
			$v_cnt++;
		}

		$bot   = ${data.$name3}{lower}[0];
		$top   = ${data.$name3}{upper}[0];
		if($bot =~ /\d/ || $top =~ /\d/){
			push(@msid, $name3);
			$v_cnt++;
		}
	}
	close(FH);

	if($v_cnt > 0){
		@dtemp = split(/_list/, $ent);
		print OUT "<h3>$dtemp[0]</h3>\n";
		print OUT "<table border=2, cellpadding=2, cellspacing=2>\n";
		print OUT "<tr><th>MSID</th><th>Lower Limit</th><th>(Limit Value)</th>";
		print OUT "<th>Upper Limit</th><th>(Limit Value)</th></tr>\n";

		for($i = 0; $i < $v_cnt; $i++){
			$bot   = ${data.$msid[$i]}{lower}[0];
			$top   = ${data.$msid[$i]}{upper}[0];
			if($bot !~ /\d/){
				$bot = '&#160';
			}elsif($bot < $chk_date){
				$bot = '<font color=red>Already in Violation</font>';
			}
			if($top !~ /\d/){
				$top = '&#160';
			}elsif($top < $chk_date){
				$top = '<font color=red>Already in Violation</font>';
			}
			print OUT "<tr>\n";
			if($msid[$i] =~ /_avg/){
				@ctemp = split(/_avg/, $msid[$i]);
			}else{
				@ctemp = split(/_AVG/, $msid[$i]);
			}
			$data_dir  = uc($dtemp[0]);
			$plot_name = "$ctemp[0]".'_plot.gif';
			$plot_name = lc($plot_name);
			$h_name = './Full_range/'."$data_dir".'/Plots/'."$plot_name";
			print OUT "<th><a href=\"javascript:WindowOpener('$h_name')\">$ctemp[0]</a></th>\n";
			if($bot =~ /\d/ && $bot < $chk_date2){
				print OUT "<td><b><font color=red>$bot</font></b></td>\n";
			}else{
				print OUT "<td>$bot</td>\n";
			}
			$msid_lc = lc($msid[$i]);
			$msid_lc =~ s/_avg//;

			if($msid_lc =~ /hrc\./){
				$msid_lc = s/hrc\.//;
			}
			print OUT "<td>${limit.$msid_lc}{y_low}[0]</td>\n";
			if($top =~ /\d/ && $top < $chk_date2){
				print OUT "<td><b><font color=red>$top</font></b></td>\n";
			}else{
				print OUT "<td>$top</td>\n";
			}
			print OUT "<td>${limit.$msid_lc}{y_top}[0]</td>\n";
			print OUT "</tr>\n";
		}
		print OUT "</table>\n";
	}
}

print OUT "</body>\n";
print OUT "</html>\n";
close(OUT);

