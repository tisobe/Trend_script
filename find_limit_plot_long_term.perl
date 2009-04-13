#!/usr/bin/perl
use PGPLOT;

#################################################################################################
#												#
#	find_limit_plot_long_term.perl: estimate limit envelope around given data for a long	#
#					term data. use saved data.				#
#												#
#		data are in dataseeker format	(col names are in  <col>_avg)			#
#												#
#		author: t. isobe (tisobe@cfa.harvard.edu)					#
#												#
#		last update Apr 13, 2009							#
#												#
#################################################################################################

#
#--- directory setting
#

$www_dir1 = '/data/mta/www/mta_envelope_trend/';
$www_dir2 = '/data/mta/www/mta_envelope_trend/SnapShot/';
$save_dir = '/data/mta/Script/Fitting/Trend_script/Save_data/';

#$www_dir1 = './';
#$www_dir2 = './';

#
#--- setting:
#

#------------------------------------------------------------------------------------------------

$datastart = 2000; 		#--- pre-set plotting range start date for envelopes for full range estimate

$hour_binning = 1;		#--- if you want, hour binning, set this to 1.
				#--- otherwise, it will use the given binning 
				#--- for the data.

$widen        = 0.0;		#--- widen factor for the envelope

$out_range    = 0.2;		#--- when calcurate the envelopes, how much sigma out from 
				#--- from the average position you want to incude in the computation.
				#--- the larger the vale, far from the average, and wider envelopes.

$limit_table1 = "/data/mta/Test/op_limits.db";
$limit_table2 = "$save_dir/limit_table";



#------------------------------------------------------------------------------------------------

#
#--- read data file name  etc
#

$fits   = $ARGV[0];		#--- input fits file, long term data saved format
$col    = $ARGV[1];		#--- data column name e.g. oobthr44_avg
$nterms = $ARGV[2];		#--- degree of polynomial fit, 2 or 3 (linear and quad)
$lim_c  = $ARGV[3];		#--- operational limit: yellow (y) or red (r) 
$range  = $ARGV[4];		#--- whether this is full, quarterly, or weekly
$lim_s  = $ARGV[5];		#--- limit selection: mta, op, or both

#
#--- set name of min/max envelope data file name
#

$lfits  = $fits;
$lfits  =~ s/_data\.fits/_min_max\.fits/;

#
#--- set which limit table to use
#

if($lim_s =~ /mta/i){
	$www_dir     = $www_dir1;
	$limit_table = $limit_table1;
}elsif($lim_s =~ /op/i){
	$www_dir     = $www_dir2;
	$limit_table = $limit_table2;
}elsif($lim_s =~ /both/i){
	$www_dir     = $www_dir1;
	$limit_table = $limit_table1;
}else{
	$www_dir     = $www_dir2;
	$limit_table = $limit_table2;
}

#
#--- if it is not a full range plot, give winder envelope to cover the
#--- deficiencies of data points
#

if($range !~ /f/i){
	$widen     = 0.2;
	$out_range = 0.4;
	if($range =~ /w/i){
		$hour_binning = 0;
		$nterms       = 2;
	}
}

#
#---  a short help will display if no ARGVs are added
#

if($fits eq ''  || $fits =~ /-h/i){
	print "\n\n";
	print 'USAGE: perl  find_limit_envelope.perl <ARGV....>',"\n\n";
	print '$fits   = $ARGV[0];     #--- input fits file, dataseeker format',"\n";
	print '$col    = $ARGV[1];     #--- data column name e.g. oobthr44_avg',"\n";
	print '$nterms = $ARGV[2];     #--- degree of polynomial fit, 2 or 3 (linear and quad)',"\n";
	print '$lim_c  = $ARGV[3];     #--- operational limit: yellow (y) or red (r) ',"\n";
	print '$range  = $ARGV[4];     #--- whether this is full (f), quarterly (q), or weekly (w)',"\n";
	print '$fstart1= $ARGV[5];     #--- first break point, if not given, the script compute one fitting for the entire data',"\n";
	print '$fstart2= $ARGV[6];     #--- second break point',"\n";
	print '$fstart3= $ARGV[7];     #--- third break point',"\n";
	print '..... (you can add as many brek points as you wnat',"\n";
	print "\n\n";
	print '$fstart2 and $fstart3 can be blank, but $fstart1 must be provided (e.g. 2000)',"\n";

	print "\n\n";

	exit 1;
}

#
#---- find today's year date
#

($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

$today    = $uyear + 1900;
$y_length = 365;
$chk      = 4.0 * int(0.25 * $today);

if($chk == $today){
	$y_length = 366;
}

$today    = $today + $uyday/$y_length;

#
#---- set data ranges, and a box size.
#

$end_time = $uyear + 1900 + 1;
$box_length   = 0.019178082;    	#--- binning size: one week in year

#
#--- read break points in year
#

@break_point = ($datastart);

$m           = 6;
$num_break   = 0;
OUTER:
while($ARGV[$m] =~ /\d/ && $ARGV[$m] ne ''){
	if($ARGV[$m] > $break_point[$num_break]){
		push(@break_point, $ARGV[$m]);
		$m++;
		$num_break++;
	}else{
		last OUTER;
	}
}

push(@break_point, $end_time);
$num_break++;

#
#--- check file name, modify it, and create output file names
#

@atemp = split(/_avg/i, $col);
$msid  = uc($atemp[0]);
$line  = '';

@atemp     = split(/\_avg/i, $col);
$col_name  = uc ($atemp[0]);
$col_name2 = lc ($atemp[0]);
$msid      = $col_name2;
$c_name    = $msid;

#
#--- some msid comes with prefix "x", since they actually start from # which
#--- may cause a problem with some software. remove "x" from the before procceding
#--- to name data files. 
#

if($msid =~ /^X/i){
	@mtemp = split(//, $msid);
	if($mtemp[0] =~ /X/i && $mtemp[1] =~ /\d/){
		$c_name = '';
		$c_cnt  = 0;
		foreach $ment (@mtemp){
			if($c_cnt > 0){
				$c_name = "$c_name"."$ment";
			}
			$c_cnt++;
		}
	}
}

$out_name  = "$c_name".'_plot.gif';		#--- plot file name
$out_data  = "$c_name".'_fitting_results';	#--- fitted result output file name

#
#---- find lower and upper limits
#

open(FH, "$limit_table");

$line = '';
OUTER:
while(<FH>){
        chomp $_;
        if($_ =~ /^$c_name\b/i){
                @l_temp = split(/\s+/, $_);
                if($l_temp[0] =~ /\#/){
                        next OUTER;
                }
                $line = $_;
        }
}
close(FH);

if($line =~ /$c_name/i){
	@l_temp = split(/\s+/, $line);
        $y_low  = $l_temp[1];
        $y_top  = $l_temp[2];
        $r_low  = $l_temp[3];
        $r_top  = $l_temp[4];
}else{

#
#--- if the limits are not found, set them very wide...
#
        $y_low  = -1e14;
        $y_top  =  1e14;
        $r_low  = -1e14;
        $r_top  =  1e14;
}

#
#--- if which limits are used is not specified, use yellow limits
#

if($lim_c !~ /r/i || $lim_c !~ /y/i){
	$lim_c = 'y';
}

if($lim_c =~ /y/){
	$bot = $y_low;
	$top = $y_top;
}else{
	$bot = $r_low;
	$top = $r_top;
}

#
#--- extract data needed
#

$line = "$fits".'[cols col1,col2]';

$in_line = `dmlist \"$line\" opt=data`;
@in_data = split(/\n/, $in_line);


#
#--- read data
#

@time      = ();
@data      = ();
$total     = 0;	

OUTER:
foreach $ent (@in_data){
	@atemp = split(/\s+/, $ent);
	if($ent =~ /col/){
		next OUTER;
	}
	if($atemp[1] =~/\d/){
		if($atemp[1] =~ /\d/){
			if($atemp[0] =~ /\d/){
				push(@time, $atemp[1]);
				push(@data, $atemp[2]);
				$total++;
			}else{
				push(@time, $atemp[2]);
				push(@data, $atemp[3]);
				$total++;
			}
		}	
	}
}

#
#--- if there is no data, say so and quite
#

if($total == 0){
	open(OUT, ">$out_data");
	print OUT "Fitting Reuslts for $msid\n\n";
	print OUT "Fitting Failed\n";
	close(OUT);

	system("cp $save_dir/null_data_s.gif $out_name");
	exit 1;
}

#
#--- read min and max envelope data
#--- col1: time, col2: min, col3: max, col4: period
#

$line = "$lfits".'[cols col1,col2,col3,col4]';

$in_line = `dmlist \"$line\" opt=data`;
@in_data = split(/\n/, $in_line);

@ltime  = ();
@min    = ();
@max    = ();
$ltotal = 0;	
$rg_min = 1e14;
$rg_max = -1e14;

OUTER:
foreach $ent (@in_data){
	@atemp = split(/\s+/, $ent);
	if($ent =~ /col/){
		next OUTER;
	}
	if($atemp[1] =~/\d/){
		if($atemp[1] =~ /\d/){
			if($atemp[0] =~ /\d/){
#
#--- save only the last period of data
#
				if($atemp[4] > $num_break -2){
					push(@ltime, $atemp[1]);
					push(@min,   $atemp[2]);
					push(@max,   $atemp[3]);
					$ltotal++;
				}
				if($atemp[2] < $rg_min){
					$rg_min = $atemp[2];
				}
				if($atemp[3] > $rg_max){
					$rg_max = $atemp[3];
				}
			}else{
				if($atemp[5] > $num_break -2){
					push(@ltime, $atemp[2]);
					push(@min,   $atemp[3]);
					push(@max,   $atemp[4]);
					$ltotal++;
				}
				if($atemp[3] < $rg_min){
					$rg_min = $atemp[3];
				}
				if($atemp[4] > $rg_max){
					$rg_max = $atemp[4];
				}
			}
		}	
	}
}

#
#---- plotting start here
#

pgbegin(0, '"./pgplot.ps"/cps',1,1);
pgsubp(1,1);
pgsch(1);
pgslw(5);

#
#--- establish  x axis range 
#

$xmin     = 1999;
$xmax     = $end_time;
$xdiff    = $xmax - $xmin;
$xmin    -= 0.05 * $ xdiff;
$xmax    += 0.05 * $ xdiff;
$xdiff    = $xmax - $xmin;
$xmid     = $xmin + 0.5 * $xdiff;
$xtxt     = $xmin + 0.1 * $xdiff;


#
#--- setting y plotting range
#

$ymin  = $rg_min;
$ymax  = $rg_max;
$ydiff = $ymax - $ymin;
$ymin -= 0.10 * $ydiff;
$ymax += 0.10 * $ydiff;
$ydiff = $ymax - $ymin;

#
#--- if the plotting range is too small, fix it
#
if($ydiff < 0.01){
	$ymin  = $test_avg - 0.01;
	$ymax  = $test_avg + 0.01;
	$ydiff = 0.02;
}

$ytxt  = $ymax - 0.1 * $ydiff;

pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);

#
#--- plot data points
#

for($i = 0; $i < $total; $i++){
	if($data[$i] >= $y_low && $data[$i] <= $y_top){
		pgsci(1);
	}elsif($data[$i] <= $r_low || $data[$i] >= $r_top){
		pgsci(2);
	}else{
		pgsci(6);
	}
	pgpt(1,$time[$i], $data[$i], 1);
	pgsci(1);
}


#
#---- read previously fitted envelope data
#

$tcol = $col;
if($tcol !~ /_avg/i){
	$tcol = "$col"."_avg";
}
$ucol = uc($tcol);
$e_results = `cat /data/mta/www/mta_envelope_trend/full_range_results|grep $ucol`;
if($e_results !~ /$ucol/i){
	$lcol = lc($tcol);
	$e_results = `cat /data/mta/www/mta_envelope_trend/full_range_results|grep $lcol`;
}

@break_year = ();
@low_a0     = ();
@low_a1     = ();
@low_a2     = ();
@top_a3     = ();
@top_a0     = ();
@top_a1     = ();
@top_a2     = ();
@top_a3     = ();
$sep_cnt    = 0;
@atemp = split(/<>/, $e_results);
OUTER:
for($i = 1; $i < $num_break; $i++){
	@btemp = split(/=l=/, $atemp[$i]);
	if($btemp[0] eq ''){
		last OUTER;
	}
	push(@break_year, $btemp[0]);
	@ctemp = split(/=u=/, $btemp[1]);
	@dtemp = split(/:/,   $ctemp[0]);
	push(@{low_a.0}, $dtemp[0]);
	push(@{low_a.1}, $dtemp[1]);
	push(@{low_a.2}, $dtemp[2]);
	push(@{low_a.3}, $dtemp[3]);
	@dtemp = split(/:/,   $ctemp[1]);
	push(@{top_a.0}, $dtemp[0]);
	push(@{top_a.1}, $dtemp[1]);
	push(@{top_a.2}, $dtemp[2]);
	push(@{top_a.3}, $dtemp[3]);
	$sep_cnt++;
}

#
#--- plot envelope except the last break period
#

for($k = 0; $k < $sep_cnt; $k++){
	pgsci(4);
	$x_range = $break_point[$k+1] - $break_point[$k];
	$step = $x_range/100;
	pgmove($break_point[$k], ${low_a.0}[$k]);
	for($j = 1; $j < 100; $j++){
		$x_adj = $step * $j;
		$y_est = 0;
		for($n = 0; $n <= $nterms; $n++){
			$y_est += ${low_a.$n}[$k] * power($x_adj, $n);
		}
		$x_est = $x_adj + $break_point[$k];
		pgdraw($x_est, $y_est);
	}


	pgmove($break_point[$k], ${top_a.0}[$k]);
	for($j = 1; $j < 100; $j++){
		$x_adj = $step * $j;
		$y_est = 0;
		for($n = 0; $n <= $nterms; $n++){
			$y_est += ${top_a.$n}[$k] * power($x_adj, $n);
		}
		$x_est = $x_adj + $break_point[$k];
		pgdraw($x_est, $y_est);
	}

#
#--- save in a different format for future use
#
	for($n = 0; $n <= $nterms; $n++){
		${p_min.$n.$k} = ${low_a.$n}[$k];
		${p_max.$n.$k} = ${top_a.$n}[$k];
	}
}

	
#
#--- estimate envelopes of the last period
#

#
#--- svdfit is a polynomial fit routine; it works well if the data means (both x and y)
#--- is close to the data range. So we shift the data to near the bottom of the x data range,
#--- and move the y mean to 0.
#

$last = $num_break -1;

if($ltotal > 0){
	@adj_x  = ();
	for($j = 0; $j < $ltotal; $j++){
       		$xtemp = $ltime[$j] - $break_point[$last];
       		push(@adj_x, $xtemp);
	}

	$sumy_min = 0;
	$sumy_max = 0;
	for($j = 0; $j < $ltotal; $j++){
		$sumy_min += $min[$j];
		$sumy_max += $max[$j];
	}
	$avgy_min        = $sumy_min/$ltotal;
	$avgy_max        = $sumy_max/$ltotal;
	${avg_min.$last} = $avgy_max;
	${avg_max.$last} = $avgy_max;

	@adj_y_min = ();
	@adj_y_max = ();
	for($j = 0; $j <$ltotal ; $j++){
		$y_temp = $min[$j] - $avgy_min;
		push(@adj_y_min, $y_temp);
		$y_temp = $max[$j] - $avgy_max;
		push(@adj_y_max, $y_temp);
	}

#
#--- envelope computation; first round
#
		
#
#--- lower envelope
#
		
	@x_in   = @adj_x;
	@y_in   = @adj_y_min;
	$npts   = $ltotal;
	$mode   = 0;

	svdfit($npts, $nterms);

	for($n = 0; $n <= $nterms; $n++){
		${p_min.$n}       = $a[$n];
		${p_min.$n.$last} = $a[$n];
	}

#
#---- upper envelope
#

	@y_in   = @adj_y_max;

	svdfit($npts, $nterms);

	for($n = 0; $n <= $nterms; $n++){
		${p_max.$n}       = $a[$n];
		${p_max.$n.$last} = $a[$n];
	}

#
#---- compute standard deviation from the the fitting line
#

	$sum_min  = 0;
	$sum_min2 = 0;
	$sum_max  = 0;
	$sum_max2 = 0;
	for($j = 0; $j < $ltotal ; $j++){
		
		$y_est = 0;
		for($n = 0; $n <= $nterms; $n++){
			$y_est += ${p_min.$n} * power($adj_x[$j], $n);
		}
		$diff = $adj_y_min[$j]  - $y_est;

		$sum_min  += $diff;
		$sum_min2 += $diff * $diff;
		
		$y_est = 0;
		for($n = 0; $n <= $nterms; $n++){
			$y_est += ${p_max.$n} * power($adj_x[$j], $n);
		}
		$diff = $adj_y_max[$j]  - $y_est;

		$sum_max  += $diff;
		$sum_max2 += $diff * $diff;
	}

	$pmin_avg = $sum_min/$ltotal;
	$pmin_sig = sqrt($sum_min2/$ltotal - $pmin_avg * $pmin_avg);

	$pmax_avg = $sum_max/$ltotal;
	$pmax_sig = sqrt($sum_max2/$ltotal - $pmax_avg * $pmax_avg);

#
#---- envelope computation, second round.
#---- select data point smaller (lower envelope) or larger (upper envelope) than the estimated 
#---- value given the estimated parameters above. this will give better "outer" envelope estimate.
#

#
#---- lower envelope
#
	@x_in = ();
	@y_in = ();
	$npts = 0;
	for($j = 0; $j < $ltotal; $j++){

		$y_est = 0;
		for($n = 0; $n <= $nterms; $n++){
			$y_est += ${p_min.$n} * power($adj_x[$j], $n);
		}
		$plim  = $y_est  - $out_range * $pmin_sig;

		if($adj_y_min[$j] <  $plim){
			push(@x_in, $adj_x[$j]);
			push(@y_in, $adj_y_min[$j]);
			$npts++;
		}
	}

#
#---- if the numbers of selected data points are too small, use the original estimates
#
	if($npts > 10){
		svdfit($npts, $nterms);

		for($n = 0; $n <= $nterms; $n++){
			${p_min.$n}       = $a[$n];
			${p_min.$n.$last} = $a[$n];
		}
	}
#
#---- upper envelope
#
	@x_in = ();
	@y_in = ();
	$npts = 0;
	for($j = 0; $j < $ltotal; $j++){
		$y_est = 0;
		for($n = 0; $n <= $nterms; $n++){
			$y_est += ${p_max.$n} * power($adj_x[$j], $n);
		}
		$plim  = $y_est  + $out_range * $pmax_sig;

		if($adj_y_max[$j] >  $plim){
			push(@x_in, $adj_x[$j]);
			push(@y_in, $adj_y_max[$j]);
			$npts++;
		}
	}

	if($npts > 10){
		svdfit($npts, $nterms);

		for($n = 0; $n <= $nterms; $n++){
			${p_max.$n}    = $a[$n];
			${p_max.$n.$last} = $a[$n];
		}
	}

#
#---- compute standard deviation from the the fitting line (again)
#

	$sum_min  = 0;
	$sum_min2 = 0;
	$sum_max  = 0;
	$sum_max2 = 0;
	for($j = 0; $j < $ltotal; $j++){
		
		$y_est = 0;
		for($n = 0; $n <= $nterms; $n++){
			$y_est += ${p_min.$n} * power($adj_x[$j], $n);
		}
		$diff = $adj_y_min[$j] - $y_est;

		$sum_min  += $diff;
		$sum_min2 += $diff * $diff;

		$y_est = 0;
		for($n = 0; $n <= $nterms; $n++){
			$y_est += ${p_max.$n} * power($adj_x[$j], $n);
		}
		$diff = $adj_y_max[$j] - $y_est;

		$sum_max  += $diff;
		$sum_max2 += $diff * $diff;
	}
	$pmin_avg = $sum_min/$ltotal;
	$pmin_sig = sqrt($sum_min2/$ltotal - $pmin_avg * $pmin_avg);

	$pmax_avg = $sum_max/$ltotal;
	$pmax_sig = sqrt($sum_max2/$ltotal - $pmax_avg * $pmax_avg);

#
#--- plot the lower envelope
#

	pgsci(4);
	$x_range = $break_point[$last+1] - $break_point[$last];
	$step = $x_range/100;

	$m = 0;
	${p_min.$m}       += $avgy_min;
	${p_min.$m.$last} += $avgy_min;
	$y_est             = ${p_min.0}  - $widen * $pmin_sig;
	pgmove($break_point[$last], $y_est);
	for($j = 1; $j < 100; $j++){
		$x_adj = $step * $j;
		$y_est = 0;
		for($n = 0; $n <= $nterms; $n++){
			$y_est += ${p_min.$n} * power($x_adj, $n);
		}
		$y_est = $y_est - $widen * $pmin_sig;
		$x_est = $x_adj + $break_point[$last];

		pgdraw($x_est, $y_est);
	}

#
#--- plot the upper envelope
#

	${p_max.$m}       += $avgy_max;
	${p_max.$m.$last} += $avgy_max;
	$y_est             = ${p_max.0}  + $widen * $pmax_sig;
	pgmove($break_point[$last], $y_est);
	for($j = 1; $j < 100; $j++){
		$x_adj = $step * $j;
		$y_est  = 0;
		for($n = 0; $n <= $nterms; $n++){
			$y_est += ${p_max.$n} * power($x_adj, $n);
		}
		$y_est = $y_est + $widen * $pmax_sig;
		$x_est = $x_adj + $break_point[$last];

		pgdraw($x_est, $y_est);
	}
	pgsci(1);
}

pgsci(1);


#
#--- check whether the lower limt will be violated in near future
#


$bot_excess = '';
$x_adj      = $xmax + 10 - $break_point[$last];

$y_est = 0;
for($n = 0; $n <= $nterms; $n++){
	$y_est += ${p_min.$n.$last} * power($x_adj, $n);
}
$y_est = $y_est - $widen * $pmin_sig;

$chk   = 0;
if($y_est < $bot){
	$limit = $bot;
	$nv = 0;
	${a.$nv}   = ${p_min.$nv.$last}- $widen * $pmin_sig;
	for($n = 1; $n <= $nterms; $n++){
		${a.$n}    = ${p_min.$n.$last};
	}
	$ind       = -1;

	find_cross_point();

	$x_pos += $break_point[$last];

	$bot_excess = sprintf "%5.1f", $x_pos;
	if($bot_excess <= $today){
		if($lim_c =~ /y/){
			pgsci(6);
			pgptxt($xtxt, $ytxt, 0, 0, "Data seem alreday in Lower Yellow  Limit Zone ($bot).");
		}else{
			pgsci(2);
			pgptxt($xtxt, $ytxt, 0, 0, "Data Seem already in Lower Red  Limit Zone ($bot).");
		}

	}else{
		if($lim_c =~ /y/){
			pgsci(6);
			pgptxt($xtxt, $ytxt, 0, 0, "Lower Yellow  Limit ($bot) may be violated around Year: $bot_excess");
		}else{
			pgsci(2);
			pgptxt($xtxt, $ytxt, 0, 0, "Lower Red  Limit ($bot) may be violated around Year: $bot_excess");
		}
	}
	pgsci(1);
	$chk = 1;
}

#
#--- check whether the upper limt will be violated in near future
#

$top_excess = '';
$x_adj      = $xmax + 10 - $break_point[$last];

$y_est = 0;
for($n = 0; $n <= $nterms; $n++){
	$y_est += ${p_max.$n.$last} * power($x_adj, $n);
}
$y_est = $y_est +  $widen * $pmax_sig;

if($y_est > $top){
	$limit = $top;
	$nv = 0;
	${a.$nv}   = ${p_max.$nv.$last}- $widen * $pmax_sig;
	for($n = 1; $n <= $nterms; $n++){
		${a.$n}    = ${p_max.$n.$last};
	}
	$ind   = 1;

	find_cross_point();

	$x_pos += $break_point[$last];

	$top_excess = sprintf "%5.1f", $x_pos;
	$ytxt2 = $ytxt;
	if($chk > 0){
		$ytxt2 = $ytxt - 0.05 * $ydiff;
	}
	pgsci(2);
	if($top_excess < $today){
		if($lim_c =~ /y/){
			pgsci(6);
			pgptxt($xtxt, $ytxt2, 0, 0, "Data seem already in Upper Yellow  Limit Zone ($top).");
		}else{
			pgsci(2);
			pgptxt($xtxt, $ytxt, 0, 0, "Data seem already in Upper Red  Limit Zone ($top).");
		}
	}else{
		if($lim_c =~ /y/){
			pgsci(6);
			pgptxt($xtxt, $ytxt2, 0, 0, "Upper Yellow  Limit ($top) may be violated around Year: $top_excess");
		}else{
			pgsci(2);
			pgptxt($xtxt, $ytxt, 0, 0, "Upper Red  Limit ($top) may be violated around Year: $top_excess");
		}
	}
	pgsci(1);
}

#
#--- add major events
#

pgsci(5);
$head = $ymin + 0.2 * $ydiff;
pgrect(2003.4372,2003.5464,$ymin,$head);
pgsci(1);
pgptxt(2003.50, $ymin, 90, 0, "IRU-1&2 on");


pgsci(5);
pgarro(2003.975, $ymin, 2003.975, $head);
pgsci(1);
pgptxt(2003.975, $ymin, 90, 0, "Stuck-on Heater");

pgsci(5);
pgarro(2006.000, $ymin, 2006.000, $head);
pgsci(1);
pgptxt(2006.10, $ymin, 90, 0, "Relaxed EPHIN Const.");

pgsci(5);
pgarro(2008.3, $ymin, 2008.3, $head);
pgsci(1);
pgptxt(2008.3, $ymin, 90, 0, "ACIS Det House Off");

pglabel("Time (Year)", "$col_name", "");

pgclos();
system("echo ''|gs -sDEVICE=ppmraw  -r64x64 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps|pnmcrop|pnmflip -r270 |ppmtogif > $out_name");

system("rm pgplot.ps");



#
#--- save fitting results etc in a file
#--- OUT for human readable, OUT2 for machine friendly
#

open(OUT, ">$out_data");

open(OUT2, ">>$www_dir/full_range_results_temp");

#
#--- special treatment for HRC I, S, OFF status (for /data/mta4/Deriv/ only);
#

$special_mark = 0;
if($fits =~ /hrc/i){
	if($fits =~/_i/i){
		$hrc_mark = 'hrci';
		$special_mark = 1;
	}elsif($fits =~ /_off/){
		$hrc_mark = 'hrco';
		$special_mark = 1;
	}elsif($fits =~ /_s/){
		$hrc_mark = 'hrcs';
		$special_mark = 1;
	}
}

print OUT "Fitting Reuslts for $msid\n\n";
if($special_mark == 1){
	print OUT2 "$hrc_mark.$col<>";
}else{
	print OUT2 "$col<>";
}

for($k = 0; $k < $num_break; $k++){
	print OUT "\tIntercept @ $start_point\t";
	print OUT "x\t\t";
	for($n = 2; $n < $nterms; $n++){
        	print OUT 'x**'."$n\t\t";
	}
	print OUT "\n";
	print OUT "lower:\t";
	$nv = 0;
	$intercept = ${p_min.$nv.$k};

	print OUT  "$intercept\t";
	$bp_short = sprintf "%5.4f", $break_point[$k];
	print OUT2 "$bp_short".'=l='."$intercept";

	for($n = 1; $n < $nterms; $n++){
        	print OUT  "${p_min.$n.$k}\t";
		print OUT2 ":${p_min.$n.$k}";
	}
	print OUT "\n";
	print OUT2 "=u=";

	print OUT "upper:\t";
	$nv = 0;
	$intercept = ${p_max.$nv.$k};
	print OUT  "$intercept\t";
	print OUT2 "$intercept";
	for($n = 1; $n < $nterms; $n++){
        	print OUT  "${p_max.$n.$k}\t";
		print OUT2 ":${p_max.$n.$k}";
	}
	print OUT "\n";
	if($k < 8){
		print OUT2 "<>";
	}
}

for($k = $num_break; $k < 8; $k++){
	print OUT2 "=l=";
	for($n = 0; $n < $nterms; $n++){
		print OUT2 ":";
	}
	print OUT2 "=u=";
	for($n = 0; $n < $nterms; $n++){
		print OUT2 ":";
	}
	print OUT2 "<>";
}


if($bot_excess !~ /\d/){
	$bot_excess = 'no violation';
	print OUT "Lower limit violation estimated date: $bot_excess (Limit: $bot)\n";
	print OUT2 "<>";
}else{
	if($bot_excess <= $today){
		$temp = sprintf "%5.2f", $today;
		print OUT "Lower limit violation estimated date: currently in  (Limit: $bot)\n";
		print OUT2 "$temp<>";
	}else{
		print OUT "Lower limit violation estimated date: $bot_excess (Limit: $bot)\n";
		print OUT2 "$bot_excess<>";
	}
}
	
if($top_excess !~ /\d/){
	$top_excess = 'no violation';
	print OUT "Upper limit violation estimated date: $top_excess (Limit: $top)\n";
	print OUT2 "<>";
}else{
	if($top_excess <= $today){
		$temp = sprintf "%5.2f", $today;
		print OUT "Upper limit violation estimated date: currently in (Limit: $top)\n";
		print OUT2 "$temp<>";
	}else{
		print OUT "Upper limit violation estimated date: $top_excess (Limit: $top)\n";
		print OUT2 "$top_excess<>";
	}
}

print OUT2 "\n";

#
#--- notify for the case, we dropped "0" from the data set
#

if($neg_ratio <= 0.02 && $zero_ratio <= 0.99){ 
	$zero_ratio *= 100;
	$zero_ratio = sprintf "%2.2f", $zero_ratio;
	print OUT "\n$zero_ratio % of data are '0' and they are dropped from data\n";
}
close(OUT);
close(OUT2);


#
#-------------------p009 plot ---------------------------------------------------
#

if($lim_s =~ /both/i){

	$out_name2 = "$c_name".'_plot2.gif';            #--- plot file name
	$out_data2 = "$c_name".'_fitting_results2';     #--- fitted result output file name

#
#---- find lower and upper limits
#

	open(FH, "$limit_table2");

	$line = '';
	OUTER:
	while(<FH>){
	 	chomp $_;
	 	if($_ =~ /^$c_name\b/i){
		  	@l_temp = split(/\s+/, $_);
		  	if($l_temp[0] =~ /\#/){
			   	next OUTER;
		  	}
		  	$line = $_;
	 	}
	}
	close(FH);
	
	if($line =~ /$c_name/i){
	 	@l_temp = split(/\s+/, $line);
	 	$y_low  = $l_temp[1];
	 	$y_top  = $l_temp[2];
	 	$r_low  = $l_temp[3];
	 	$r_top  = $l_temp[4];
	}else{
	
#
#--- if the limits are not found, set them very wide...
#
	 	$y_low  = -1e14;
	 	$y_top  =  1e14;
	 	$r_low  = -1e14;
	 	$r_top  =  1e14;
	}
	
#
#--- if which limits are used is not specified, use yellow limits
#

	if($lim_c !~ /r/i || $lim_c !~ /y/i){
	 	$lim_c = 'y';
	}
	
	if($lim_c =~ /y/){
	 	$bot = $y_low;
	 	$top = $y_top;
	}else{
	 	$bot = $r_low;
	 	$top = $r_top;
	}


#
#---- plotting starts here
#

	pgbegin(0, '"./pgplot.ps"/cps',1,1);
	pgsubp(1,1);
	pgsch(1);
	pgslw(5);
	
	pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);

#
#--- plot data points
#

 	for($i = 0; $i < $total; $i++){
	  	if($data[$i] >= $y_low && $data[$i] <= $y_top){
		   	pgsci(1);
	  	}elsif($data[$i] <= $r_low || $data[$i] >= $r_top){
		   	pgsci(2);
	  	}else{
		   	pgsci(6);
	  	}
	  	pgpt(1,$time[$i], $data[$i], 1);
	  	pgsci(1);
 	}


#
#---- plot envelopes
#

	pgsci(4);
	for($k = 0; $k < $num_break; $k++){
		$x_range = $break_point[$k+1] - $break_point[$k];
		$step    = $x_range/100;
		$n       = 0;
		$y_est   = ${p_min.$n.$k}  - $widen * $pmin_sig;

		pgmove($break_point[$k], $y_est);

		for($j = 1; $j < 100; $j++){
			$x_adj = $step * $j;
			$y_est = 0;
			for($n = 0; $n <= $nterms; $n++){
				$y_est += ${p_min.$n.$k} * power($x_adj, $n);
			}
			$y_est = $y_est - $widen * $pmin_sig;
			$x_est = $x_adj + $break_point[$k];
			pgdraw($x_est, $y_est);
		}
	}
	
	for($k = 0; $k < $num_break; $k++){
		$x_range = $break_point[$k+1] - $break_point[$k];
		$step    = $x_range/100;
		$n       = 0;
		$y_est   = ${p_max.$n.$k}  + $widen * $pmax_sig;

		pgmove($break_point[$k], $y_est);

		for($j = 1; $j < 100; $j++){
			$x_adj = $step * $j;
			$y_est = 0;
			for($n = 0; $n <= $nterms; $n++){
				$y_est += ${p_max.$n.$k} * power($x_adj, $n);
			}
			$y_est = $y_est + $widen * $pmax_sig;
			$x_est = $x_adj + $break_point[$k];
			pgdraw($x_est, $y_est);
		}
	}
	
	
	pgsci(1);
	

#
#--- check whether the lower limt will be violated in near future
#

	if($range =~ /f/i){
	 	$last	= $num_break -1;
	 	$bot_excess = '';
	 	$x_adj      = $xmax + 10 - $break_point[$last];
	
	 	$y_est = 0;
	 	for($n = 0; $n <= $nterms; $n++){
		  	$y_est += ${p_min.$n.$last} * power($x_adj, $n);
	 	}
	 	$y_est = $y_est - $widen * $pmin_sig + $avgy_min;
	
	 	$chk   = 0;
	 	if($y_est < $bot){
		  	$limit = $bot;
		  	$nv = 0;
		  	${a.$nv}   = ${p_min.$nv.$last}- $widen * $pmin_sig + $avgy_min;
		  	for($n = 1; $n <= $nterms; $n++){
			   	${a.$n}    = ${p_min.$n.$last};
		  	}
		  	$ind	= -1;
	
		  	find_cross_point();
	
		  	$x_pos += $break_point[$last];
	
		  	$bot_excess = sprintf "%5.1f", $x_pos;
		  	if($bot_excess <= $today){
			   	if($lim_c =~ /y/){
				    	pgsci(6);
				    	pgptxt($xtxt, $ytxt, 0, 0, "Data seem alreday in Lower Yellow  Limit Zone ($bot).");
			   	}else{
				    	pgsci(2);
				    	pgptxt($xtxt, $ytxt, 0, 0, "Data Seem already in Lower Red  Limit Zone ($bot).");
			   	}
	
		  	}else{
			   	if($lim_c =~ /y/){
				    	pgsci(6);
				    	pgptxt($xtxt, $ytxt, 0, 0, "Lower Yellow  Limit ($bot) may be violated around Year: $bot_excess");
			   	}else{
				    	pgsci(2);
				    	pgptxt($xtxt, $ytxt, 0, 0, "Lower Red  Limit ($bot) may be violated around Year: $bot_excess");
			   	}
		  	}
		  	pgsci(1);
		  	$chk = 1;
	 	}

#
#--- check whether the upper limt will be violated in near future
#

	 	$top_excess = '';
	 	$x_adj      = $xmax + 10 - $break_point[$last];
	
	 	$y_est = 0;
	 	for($n = 0; $n <= $nterms; $n++){
		  	$y_est += ${p_max.$n.$last} * power($x_adj, $n);
	 	}
	 	$y_est = $y_est +  $widen * $pmax_sig + $avgy_max;
	
	 	if($y_est > $top){
		  	$limit = $top;
		  	$nv = 0;
		  	${a.$nv}   = ${p_max.$nv.$last}- $widen * $pmax_sig + $avgy_max;
		  	for($n = 1; $n <= $nterms; $n++){
			   	${a.$n}    = ${p_max.$n.$last};
		  	}
		  	$ind   = 1;
	
		  	find_cross_point();
	
		  	$x_pos += $break_point[$last];
	
		  	$top_excess = sprintf "%5.1f", $x_pos;
		  	$ytxt2 = $ytxt;
		  	if($chk > 0){
			   	$ytxt2 = $ytxt - 0.05 * $ydiff;
		  	}
		  	pgsci(2);
		  	if($top_excess < $today){
			   	if($lim_c =~ /y/){
				    	pgsci(6);
				    	pgptxt($xtxt, $ytxt2, 0, 0, "Data seem already in Upper Yellow  Limit Zone ($top).");
			   	}else{
				    	pgsci(2);
				    	pgptxt($xtxt, $ytxt, 0, 0, "Data seem already in Upper Red  Limit Zone ($top).");
			   	}
		  	}else{
			   	if($lim_c =~ /y/){
				    	pgsci(6);
				    	pgptxt($xtxt, $ytxt2, 0, 0, "Upper Yellow  Limit ($top) may be violated around Year: $top_excess");
			   	}else{
				    	pgsci(2);
				    	pgptxt($xtxt, $ytxt, 0, 0, "Upper Red  Limit ($top) may be violated around Year: $top_excess");
			   	}
		  	}
		  	pgsci(1);
	 	}
	}

#
#--- add major events
#

	pgsci(5);
	$head = $ymin + 0.2 * $ydiff;
	pgrect(2003.4372,2003.5464,$ymin,$head);
	pgsci(1);
	pgptxt(2003.50, $ymin, 90, 0, "IRU-1&2 on");
	
	
	pgsci(5);
	pgarro(2003.975, $ymin, 2003.975, $head);
	pgsci(1);
	pgptxt(2003.975, $ymin, 90, 0, "Stuck-on Heater");
	
	pgsci(5);
	pgarro(2006.000, $ymin, 2006.000, $head);
	pgsci(1);
	pgptxt(2006.10, $ymin, 90, 0, "Relaxed EPHIN Const.");
	
	if($range =~/\q/i || $range =~ /w/i){
	 	pglabel("Time (DOY/Year:$y_beg)", "$col_name", "");
	}else{
	 	pglabel("Time (Year)", "$col_name", "");
	}
	
	pgclos();
	system("echo ''|gs -sDEVICE=ppmraw  -r64x64 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps|pnmcrop|pnmflip -r270 |ppmtogif > $out_name2");
	
	system("rm pgplot.ps");



#
#--- save fitting results etc in a file
#--- OUT for human readable, OUT2 for machine friendly
#

	open(OUT, ">$out_data2");

	if($range =~ /f/i){
		open(OUT2, ">>$www_dir2/full_range_results_temp");
	}elsif($range =~ /q/i){
		open(OUT2, ">>$www_dir2/quarterly_results_temp");
	}elsif($range =~ /w/i){
		open(OUT2, ">>$www_dir2/weekly_results_temp");
	}
	
	print OUT "Fitting Reuslts for $msid\n\n";
	if($special_mark == 1){
		print OUT2 "$hrc_mark.$col<>";
	}else{
		print OUT2 "$col<>";
	}
	
	for($k = 0; $k < $num_break; $k++){
		print OUT "\tIntercept @ $start_point\t";
		print OUT "x\t\t";
		for($n = 2; $n < $nterms; $n++){
        		print OUT 'x**'."$n\t\t";
		}
		print OUT "\n";
		print OUT "lower:\t";
		$nv = 0;
		$intercept = ${p_min.$nv.$k};
	
		print OUT  "$intercept\t";
		$bp_short = sprintf "%5.4f", $break_point[$k];
		print OUT2 "$bp_short=l=$intercept";
	
		for($n = 1; $n <= $nterms; $n++){
        		print OUT  "${p_min.$n.$k}\t";
			print OUT2 ":${p_min.$n.$k}";
		}
		print OUT "\n";
		print OUT2 "=u=";
	
		print OUT "upper:\t";
		$nv = 0;
		$intercept = ${p_max.$nv.$k};
		print OUT  "$intercept\t";
		print OUT2 "$intercept";
		for($n = 1; $n <= $nterms; $n++){
        		print OUT  "${p_max.$n.$k}\t";
			print OUT2 ":${p_max.$n.$k}";
		}
		print OUT "\n";
		if($k < 8){
			print OUT2 "<>";
		}
	}
	
	for($k = $num_break; $k < 8; $k++){
		print OUT2 "=l=";
		for($n = 0; $n < $nterms; $n++){
			print OUT2 ":";
		}
		print OUT2 "=u=";
		for($n = 0; $n < $nterms; $n++){
			print OUT2 ":";
		}
		print OUT2 "<>";
	}
	
	
	if($bot_excess !~ /\d/){
		$bot_excess = 'no violation';
		print OUT "Lower limit violation estimated date: $bot_excess (Limit: $bot)\n";
		print OUT2 "<>";
	}else{
		if($bot_excess <= $today){
			$temp = sprintf "%5.2f", $today;
			print OUT "Lower limit violation estimated date: currently in  (Limit: $bot)\n";
			print OUT2 "$temp<>";
		}else{
			print OUT "Lower limit violation estimated date: $bot_excess (Limit: $bot)\n";
			print OUT2 "$bot_excess<>";
		}
	}
		
	if($top_excess !~ /\d/){
		$top_excess = 'no violation';
		print OUT "Upper limit violation estimated date: $top_excess (Limit: $top)\n";
		print OUT2 "<>";
	}else{
		if($top_excess <= $today){
			$temp = sprintf "%5.2f", $today;
			print OUT "Upper limit violation estimated date: currently in (Limit: $top)\n";
			print OUT2 "$temp<>";
		}else{
			print OUT "Upper limit violation estimated date: $top_excess (Limit: $top)\n";
			print OUT2 "$top_excess<>";
		}
	}
	
	print OUT2 "\n";
	
#
#--- notify for the case, we dropped "0" from the data set
#

	if($neg_ratio <= 0.02 && $zero_ratio <= 0.99){ 
		$zero_ratio *= 100;
		$zero_ratio = sprintf "%2.2f", $zero_ratio;
		print OUT "\n$zero_ratio % of data are '0' and they are dropped from data\n";
	}
	close(OUT);
	close(OUT2);

}			#-------- end of p009 data plot

###############################################################################
### find_cross_point: estimate limit violation point                        ###
###############################################################################

sub find_cross_point{
	$x_pos = -2000;
	$step = 1/12;
	if($ind > 0){
		$x_est = $xmax - $break_point[$last];
		$yest = 0;
		for($n = 0; $n <= $nterms; $n++){
			$yest += ${a.$n} * power($x_est, $n);
		}
		if($y_est <=  $limit){
			OUTER:
			for($m = 0; $m < 400; $m++){
				$x_est = $xmax + $step * $m - $break_point[$last];

				$y_est = 0;
				for($n = 0; $n <= $nterms; $n++){
					$y_est += ${a.$n} * power($x_est, $n);
				}

				if($y_est >= $limit){
					$diff1  = $y_est  - $limit;
					$x_est -= $step;

					$_yest2 = 0;
					for($n = 0; $n <= $nterms; $n++){
						$y_est2 += ${a.$n} * power($x_est, $n);
					}

					$diff2  = $limit - $y_est2;
					$div    = $diff1 + $diff2;
					$add    = 0;
					if($div > 0){
						$add    = $step * $diff2/($diff1 + $diff2);
					}
					$x_pos  = $x_est + $add;
		
					last OUTER;
				}
			}
		}else{
			OUTER:
			for($m = 0; $m < 400; $m++){
				$x_est = $xmax - $step * $m - $break_point[$last];

				$y_est = 0;
				for($n = 0; $n <= $nterms; $n++){
					$y_est += ${a.$n} * power($x_est, $n);
				}
				
				if($y_est <= $limit){
					$diff1  = $limit - $y_est;
					$x_est += $step;

					$y_est2 = 0;
					for($n = 0; $n <= $nterms; $n++){
						$y_est2 += ${a.$n} * power($x_est, $n);
					}

					$diff2  = $y_est2 - $limit;
					$div    = $diff1 + $diff2;
					$add    = 0;
					if($div > 0){
						$add    = $step * $diff2/($diff1 + $diff2);
					}
					$x_pos  = $x_est - $add;
		
					last OUTER;
				}
			}
		}
	}else{
		$x_est = $xmax - $break_point[$last];

		$y_est = 0;
		for($n = 0; $n <= $nterms; $n++){
			$y_est += ${a.$n} * power($x_est, $n);
		}

		if($y_est >=  $limit){
			OUTER:
			for($m = 0; $m < 400; $m++){
				$x_est = $xmax + $step * $m - $break_point[$last];
				$y_est = 0;
				for($n = 0; $n <= $nterms; $n++){
					$y_est += ${a.$n} * power($x_est, $n);
				}

				if($y_est <= $limit){
					$diff1  = $limit - $y_est;
					$x_est -= $step;
					$y_est2 = 0;
					for($n = 0; $n <= $nterms; $n++){
						$y_est2 += ${a.$n} * power($x_est, $n);
					}

					$diff2  = $y_est2 - $limit;
					$div    = $diff1 + $diff2;
					$add    = 0;
					if($div > 0){
						$add    = $step * $diff2/($diff1 + $diff2);
					}
					$x_pos  = $x_est + $add;
		
					last OUTER;
				}
			}
		}else{
			OUTER:
			for($m = 0; $m < 400; $m++){
				$x_est = $xmax - $step * $m - $break_point[$last];

				$y_est = 0;
				for($n = 0; $n <= $nterms; $n++){
					$y_est += ${a.$n} * power($x_est, $n);
				}

				if($y_est >= $limit){
					$diff1  = $y_est  - $limit;
					$x_est += $step;

					$y_est2 = 0;
					for($n = 0; $n <= $nterms; $n++){
						$y_est2 += ${a.$n} * power($x_est, $n);
					}

					$diff2  = $limit - $y_est2;
					$div    = $diff1 + $diff2;
					$add    = 0;
					if($div > 0){
						$add    = $step * $diff2/($diff1 + $diff2);
					}
					$x_pos  = $x_est - $add;
		
					last OUTER;
				}
			}
		}
	}
}



########################################################################
###svdfit: polinomial line fit routine                               ###
########################################################################

sub svdfit{
#
#----- this code was taken from Numerical Recipes. the original is FORTRAN
#

        $tol = 1.e-5;

        my($ndata, $ma, @x, @y, @sig);
        ($ndata, $ma) = @_;
        for($i = 0; $i < $ndata; $i++){
                $j = $i + 1;
                $x[$j] = $x_in[$i];
                $y[$j] = $y_in[$i];
                $sig[$j] = $sigmay[$i];
        }
#
#---- accumulate coefficients of the fitting matrix
#
        for($i = 1; $i <= $ndata; $i++){
                funcs($x[$i], $ma);
                if($mode == 0){
                        $tmp = 1.0;
                        $sig[$i] = 1.0;
                }else{
                        $tmp = 1.0/$sig[$i];
                }
                for($j = 1; $j <= $ma; $j++){
                        $u[$i][$j] = $afunc[$j] * $tmp;
                }
                $b[$i] = $y[$i] * $tmp;
        }
#
#---- singular value decompostion sub
#
        svdcmp($ndata, $ma);            ###### this also need $u[$i][$j] and $b[$i]
#
#---- edit the singular values, given tol from the parameter statements
#
        $wmax = 0.0;
        for($j = 1; $j <= $ma; $j++){
                if($w[$j] > $wmax) {$wmax = $w[$j]}
        }
        $thresh = $tol * $wmax;
        for($j = 1; $j <= $ma; $j++){
                if($w[$j] < $thresh){$w[$j] = 0.0}
        }

        svbksb($ndata, $ma);            ###### this also needs b, u, v, w. output is a[$j]
#
#---- evaluate chisq
#
        $chisq = 0.0;
        for($i = 1; $i <= $ndata; $i++){
                funcs($x[$i], $ma);
                $sum = 0.0;
                for($j = 1; $j <= $ma; $j++){
                        $sum  += $a[$j] * $afunc[$j];
                }
                $diff = ($y[$i] - $sum)/$sig[$i];
                $chisq +=  $diff * $diff;
        }
}


########################################################################
### svbksb: solves a*x = b for a vector x                            ###
########################################################################

sub svbksb {
#
#----- this code was taken from Numerical Recipes. the original is FORTRAN
#
        my($m, $n, $i, $j, $jj, $s);
        ($m, $n) = @_;
        for($j = 1; $j <= $n; $j++){
                $s = 0.0;
                if($w[$j] != 0.0) {
                        for($i = 1; $i <= $m; $i++){
                                $s += $u[$i][$j] * $b[$i];
                        }
                        $s /= $w[$j];
                }
                $tmp[$j] = $s;
        }

        for($j = 1; $j <= $n; $j++){
                $s = 0.0;
                for($jj = 1; $jj <= $n; $jj++){
                        $s += $v[$j][$jj] * $tmp[$jj];
                }
                $i = $j -1;
                $a[$i] = $s;
        }
}

########################################################################
### svdcmp: compute singular value decomposition                     ###
########################################################################

sub svdcmp {
#
#----- this code wass taken from Numerical Recipes. the original is FORTRAN
#
        my ($m, $n, $i, $j, $k, $l, $mn, $jj, $x, $y, $s, $g);
        ($m, $n) = @_;

        $g     = 0.0;
        $scale = 0.0;
        $anorm = 0.0;

        for($i = 1; $i <= $n; $i++){
                $l = $i + 1;
                $rv1[$i] = $scale * $g;
                $g = 0.0;
                $s = 0.0;
                $scale = 0.0;
                if($i <= $m){
                        for($k = $i; $k <= $m; $k++){
                                $scale += abs($u[$k][$i]);
                        }
                        if($scale != 0.0){
                                for($k = $i; $k <= $m; $k++){
                                        $u[$k][$i] /= $scale;
                                        $s += $u[$k][$i] * $u[$k][$i];
                                }
                                $f = $u[$i][$i];

                                $ss = $f/abs($f);
                                $g = -1.0  * $ss * sqrt($s);
                                $h = $f * $g - $s;
                                $u[$i][$i] = $f - $g;
                                for($j = $l; $j <= $n; $j++){
                                        $s = 0.0;
                                        for($k = $i; $k <= $m; $k++){
                                                $s += $u[$k][$i] * $u[$k][$j];
                                        }
                                        $f = $s/$h;
                                        for($k = $i; $k <= $m; $k++){
                                                $u[$k][$j] += $f * $u[$k][$i];
                                        }
                                }
                                for($k = $i; $k <= $m; $k++){
                                        $u[$k][$i] *= $scale;
                                }
                        }
                }

                $w[$i] = $scale * $g;
                $g = 0.0;
                $s = 0.0;
                $scale = 0.0;
                if(($i <= $m) && ($i != $n)){
                        for($k = $l; $k <= $n; $k++){
                                $scale += abs($u[$i][$k]);
                        }
                        if($scale != 0.0){
                                for($k = $l; $k <= $n; $k++){
                                        $u[$i][$k] /= $scale;
                                        $s += $u[$i][$k] * $u[$i][$k];
                                }
                                $f = $u[$i][$l];

                                $ss = $f /abs($f);
                                $g  = -1.0 * $ss * sqrt($s);
                                $h = $f * $g - $s;
                                $u[$i][$l] = $f - $g;
                                for($k = $l; $k <= $n; $k++){
                                        $rv1[$k] = $u[$i][$k]/$h;
                                }
                                for($j = $l; $j <= $m; $j++){
                                        $s = 0.0;
                                        for($k = $l; $k <= $n; $k++){
                                                $s += $u[$j][$k] * $u[$i][$k];
                                        }
                                        for($k = $l; $k <= $n; $k++){
                                                $u[$j][$k] += $s * $rv1[$k];
                                        }
                                }
                                for($k = $l; $k <= $n; $k++){
                                        $u[$i][$k] *= $scale;
                                }
                        }
                }

                $atemp = abs($w[$i]) + abs($rv1[$i]);
                if($atemp > $anorm){
                        $anorm = $atemp;
                }
        }

        for($i = $n; $i > 0; $i--){
                if($i < $n){
                        if($g != 0.0){
                                for($j = $l; $j <= $n; $j++){
                                        $v[$j][$i] = $u[$i][$j]/$u[$i][$l]/$g;
                                }
                                for($j = $l; $j <= $n; $j++){
                                        $s = 0.0;
                                        for($k = $l; $k <= $n; $k++){
                                                $s += $u[$i][$k] * $v[$k][$j];
                                        }
                                        for($k = $l; $k <= $n; $k++){
                                                $v[$k][$j] += $s * $v[$k][$i];
                                        }
                                }
                        }
                        for($j = $l ; $j <= $n; $j++){
                                $v[$i][$j] = 0.0;
                                $v[$j][$i] = 0.0;
                        }
                }
                $v[$i][$i] = 1.0;
                $g = $rv1[$i];
                $l = $i;
        }

        $istart = $m;
        if($n < $m){
                $istart = $n;
        }
        for($i = $istart; $i > 0; $i--){
                $l = $i + 1;
                $g = $w[$i];
                for($j = $l; $j <= $n; $j++){
                        $u[$i][$j] = 0.0;
                }

                if($g != 0.0){
                        $g = 1.0/$g;
                        for($j = $l; $j <= $n; $j++){
                                $s = 0.0;
                                for($k = $l; $k <= $m; $k++){
                                        $s += $u[$k][$i] * $u[$k][$j];
                                }
                                $f = ($s/$u[$i][$i])* $g;
                                for($k = $i; $k <= $m; $k++){
                                        $u[$k][$j] += $f * $u[$k][$i];
                                }
                        }
                        for($j = $i; $j <= $m; $j++){
                                $u[$j][$i] *= $g;
                        }
                }else{
                        for($j = $i; $j <= $m; $j++){
                                $u[$j][$i] = 0.0;
                        }
                }
                $u[$i][$i]++;
        }

        OUTER2:
        for($k = $n; $k > 0; $k--){
                for($its = 0; $its < 30; $its++){
                        $do_int = 0;
                        OUTER:
                        for($l = $k; $l > 0; $l--){
                                $nm = $l -1;
                                if((abs($rv1[$l]) + $anorm) == $anorm){
                                        last OUTER;
                                }
                                if((abs($w[$nm]) + $anorm) == $anorm){
                                        $do_int = 1;
                                        last OUTER;
                                }
                        }
                        if($do_int == 1){
                                $c = 0.0;
                                $s = 1.0;
                                for($i = $l; $i <= $k; $i++){
                                        $f = $s * $rv1[$i];
                                        $rv1[i] = $c * $rv1[$i];
                                        if((abs($f) + $anorm) != $anorm){
                                                $g = $w[$i];
                                                $h = pythag($f, $g);
                                                $w[$i] = $h;
                                                $h = 1.0/$h;
                                                $c = $g * $h;
                                                $s = -1.0 * $f * $h;
                                                for($j = 1; $j <= $m; $j++){
                                                        $y = $u[$j][$nm];
                                                        $z = $u[$j][$i];
                                                        $u[$j][$nm] = ($y * $c) + ($z * $s);
                                                        $u[$j][$i]  = -1.0 * ($y * $s) + ($z * $c);
                                                }
                                        }
                                }
                        }

                        $z = $w[$k];
                        if($l == $k ){
                                if($z < 0.0) {
                                        $w[$k] = -1.0 * $z;
                                        for($j = 1; $j <= $n; $j++){
                                                $v[$j][$k] *= -1.0;
                                        }
                                }
                                next OUTER2;
                        }else{
                                if($its == 29){
                                        print "No convergence in 30 iterations\n";
                                        exit 1;
                                }
                                $x = $w[$l];
                                $nm = $k -1;
                                $y = $w[$nm];
                                $g = $rv1[$nm];
                                $h = $rv1[$k];
                                $f = (($y - $z)*($y + $z) + ($g - $h)*($g + $h))/(2.0 * $h * $y);
                                $g = pythag($f, 1.0);

                                $ss = $f/abs($f);
                                $gx = $ss * $g;

                                $f = (($x - $z)*($x + $z) + $h * (($y/($f + $gx)) - $h))/$x;

                                $c = 1.0;
                                $s = 1.0;
                                for($j = $l; $j <= $nm; $j++){
                                        $i = $j +1;
                                        $g = $rv1[$i];
                                        $y = $w[$i];
                                        $h = $s * $g;
                                        $g = $c * $g;
                                        $z = pythag($f, $h);
                                        $rv1[$j] = $z;
                                        $c = $f/$z;
                                        $s = $h/$z;
                                        $f = ($x * $c) + ($g * $s);
                                        $g = -1.0 * ($x * $s) + ($g * $c);
                                        $h = $y * $s;
                                        $y = $y * $c;
                                        for($jj = 1; $jj <= $n ; $jj++){
                                                $x = $v[$jj][$j];
                                                $z = $v[$jj][$i];
                                                $v[$jj][$j] = ($x * $c) + ($z * $s);
                                                $v[$jj][$i] = -1.0 * ($x * $s) + ($z * $c);
                                        }
                                        $z = pythag($f, $h);
                                        $w[$j] = $z;
                                        if($z != 0.0){
                                                $z = 1.0/$z;
                                                $c = $f * $z;
                                                $s = $h * $z;
                                        }
                                        $f = ($c * $g) + ($s * $y);
                                        $x = -1.0 * ($s * $g) + ($c * $y);
                                        for($jj = 1; $jj <= $m; $jj++){
                                                $y = $u[$jj][$j];
                                                $z = $u[$jj][$i];
                                                $u[$jj][$j] = ($y * $c) + ($z * $s);
                                                $u[$jj][$i] = -1.0 * ($y * $s) + ($z * $c);
                                        }
                                }
                                $rv1[$l] = 0.0;
                                $rv1[$k] = $f;
                                $w[$k] = $x;
                        }
                }
        }
}

########################################################################
### pythag: compute sqrt(x**2 + y**2) without overflow               ###
########################################################################

sub pythag{
        my($a, $b);
        ($a,$b) = @_;

        $absa = abs($a);
        $absb = abs($b);
        if($absa == 0){
                $result = $absb;
        }elsif($absb == 0){
                $result = $absa;
        }elsif($absa > $absb) {
                $div    = $absb/$absa;
                $result = $absa * sqrt(1.0 + $div * $div);
        }elsif($absb > $absa){
                $div    = $absa/$absb;
                $result = $absb * sqrt(1.0 + $div * $div);
        }
        return $result;
}

########################################################################
### funcs: linear polymonical fuction                                ###
########################################################################

sub funcs {
        my($inp, $pwr, $kf, $temp);
        ($inp, $pwr) = @_;
        $afunc[1] = 1.0;
        for($kf = 2; $kf <= $pwr; $kf++){
                $afunc[$kf] = $afunc[$kf-1] * $inp;
        }
}

######################################################################
### pol_val: compute a value for polinomial fit for  give coeffs   ###
######################################################################

sub pol_val{
        my ($x, $dim, $i, $j);
        ($dim, $x) = @_;
        funcs($x, $dim);
        $out = $a[0];
        for($i = 1; $i <= $dim; $i++){
                $out += $a[$i] * $afunc[$i +1];
        }
        return $out;
}


##############################################################################
### dom_to_ydate: change dom (starting 1999.1.1) to date in uint of year   ###
##############################################################################

sub dom_to_ydate{

	my ($year, $frac, $i, $chk);
	$year = 0;
	OUTER:
	while($dom > 0){
		OUTER2:
		while($dom > 0){
			$div = 365;
			$y_v = $year + 3;
			$chk = 4.0 * int(0.25 * $y_v);
			if($y_v == $chk){
				$div = 366;
			}
			$diff = $dom - $div;
			if($diff < 0){
				$frac = $dom/$div;
				$year += $frac;
				last OUTER2;
			}
			$dom -= $div;
			$year++;
		}
		last OUTER;
	}

	$ydate = 1999 + $year;
}


######################################################################
### power: power to the base value                                 ###
######################################################################

sub power {
        my($i,  $base, $power);
        ($base, $power) = @_;

        $presult = 1;
        for($i = 0; $i < $power; $i++){
                $presult *= $base;
        }
        return $presult;
}

####################################################################
### robust_fit: linear fit for data with medfit robust fit metho  ##
####################################################################

sub robust_fit{
	my($n);

        $sumx = 0;
        $symy = 0;
        for($n = 0; $n < $data_cnt; $n++){
                $sumx += $xdata[$n];
                $symy += $ydata[$n];
        }
        $xavg = $sumx/$data_cnt;
        $yavg = $sumy/$data_cnt;
#
#--- robust fit works better if the intercept is close to the
#--- middle of the data cluster.
#
        @xldat = ();
        @yldat = ();
        for($n = 0; $n < $data_cnt; $n++){
#                $xldat[$n] = $xdata[$n] - $xavg;
#                $yldat[$n] = $ydata[$n] - $yavg;
                $xldat[$n] = $xdata[$n];
                $yldat[$n] = $ydata[$n];
        }

        $rtotal = $data_cnt;
        medfit();

        $alpha += $beta * (-1.0 * $xavg) + $yavg;

        $int   = $alpha;
        $slope = $beta;
}


####################################################################
### medfit: robust filt routine                                  ###
####################################################################

sub medfit{

#########################################################################
#                                                                       #
#       fit a straight line according to robust fit                     #
#       Numerical Recipes (FORTRAN version) p.544                       #
#                                                                       #
#       Input:          @xldat  independent variable                    #
#                       @yldat  dependent variable                      #
#                       total   # of data points                        #
#                                                                       #
#       Output:         alpha:  intercept                               #
#                       beta:   slope                                   #
#                                                                       #
#       sub:            rofunc evaluate SUM( x * sgn(y- a - b * x)      #
#                       sign   FORTRAN/C sign function                  #
#                                                                       #
#########################################################################

        my $sx  = 0;
        my $sy  = 0;
        my $sxy = 0;
        my $sxx = 0;

        my (@xt, @yt, $del,$bb, $chisq, $b1, $b2, $f1, $f2, $sigb);
#
#---- first compute least sq solution
#
        for($j = 0; $j < $rtotal; $j++){
                $xt[$j] = $xldat[$j];
                $yt[$j] = $yldat[$j];
                $sx  += $xldat[$j];
                $sy  += $yldat[$j];
                $sxy += $xldat[$j] * $yldat[$j];
                $sxx += $xldat[$j] * $xldat[$j];
        }

        $del = $rtotal * $sxx - $sx * $sx;
#
#----- least sq. solutions
#
        $aa = ($sxx * $sy - $sx * $sxy)/$del;
        $bb = ($rtotal * $sxy - $sx * $sy)/$del;
        $asave = $aa;
        $bsave = $bb;

        $chisq = 0.0;
        for($j = 0; $j < $rtotal; $j++){
                $diff   = $yldat[$j] - ($aa + $bb * $xldat[$j]);
                $chisq += $diff * $diff;
        }
        $sigb = sqrt($chisq/$del);
        $b1   = $bb;
        $f1   = rofunc($b1);
        $b2   = $bb + sign(3.0 * $sigb, $f1);
        $f2   = rofunc($b2);

        $iter = 0;
        OUTER:
        while($f1 * $f2 > 0.0){
                $bb = 2.0 * $b2 - $b1;
                $b1 = $b2;
                $f1 = $f2;
                $b2 = $bb;
                $f2 = rofunc($b2);
                $iter++;
                if($iter > 100){
                        last OUTER;
                }
        }

        $sigb *= 0.01;
        $iter = 0;
        OUTER1:
        while(abs($b2 - $b1) > $sigb){
                $bb = 0.5 * ($b1 + $b2);
                if($bb == $b1 || $bb == $b2){
                        last OUTER1;
                }
                $f = rofunc($bb);
                if($f * $f1 >= 0.0){
                        $f1 = $f;
                        $b1 = $bb;
                }else{
                        $f2 = $f;
                        $b2 = $bb;
                }
                $iter++;
                if($iter > 100){
                        last OTUER1;
                }
        }
        $alpha = $aa;
        $beta  = $bb;
        if($iter >= 100){
                $alpha = $asave;
                $beta  = $bsave;
        }
        $abdev = $abdev/$rtotal;
}

##########################################################
### rofunc: evaluatate 0 = SUM[ x *sign(y - a bx)]     ###
##########################################################

sub rofunc{
        my ($b_in, @arr, $n1, $nml, $nmh, $sum);

        ($b_in) = @_;
        $n1  = $rtotal + 1;
        $nml = 0.5 * $n1;
        $nmh = $n1 - $nml;
        @arr = ();
        for($j = 0; $j < $rtotal; $j++){
                $arr[$j] = $yldat[$j] - $b_in * $xldat[$j];
        }
        @arr = sort{$a<=>$b} @arr;
        $aa = 0.5 * ($arr[$nml] + $arr[$nmh]);
        $sum = 0.0;
        $abdev = 0.0;
        for($j = 0; $j < $rtotal; $j++){
                $d = $yldat[$j] - ($b_in * $xldat[$j] + $aa);
                $abdev += abs($d);
                $sum += $xldat[$j] * sign(1.0, $d);
        }
        return($sum);
}


##########################################################
### sign: sign function                                ###
##########################################################

sub sign{
        my ($e1, $e2, $sign);
        ($e1, $e2) = @_;
        if($e2 >= 0){
                $sign = 1;
        }else{
                $sign = -1;
        }
        return $sign * $e1;
}



############################################################################
### find_ebar: find error bar for slope using bootstrapp method          ###
############################################################################

sub find_ebar {

        my($sum, $sum2, $avg);
        $data_cnt = $org_tot;
        @sum      = 0;
        @sum2     = 0;

        for($m = 0; $m < 100; $m++){
                @xdata    = ();
                @ydata    = ();
                for($k = 0; $k < $org_tot; $k++){
                        $no = int($org_tot * sqrt(rand() * rand()));
                        push(@xdata, $org_xdata[$no]);
                        push(@ydata, $org_ydata[$no]);
                }
                robust_fit();
                $sum  += $slope;
                $sum2 += $slope * $slope;
        }

        $avg = $sum / 100;
        $std = sqrt($sum2/100 - $avg * $avg);
}

