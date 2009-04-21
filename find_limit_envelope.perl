#!/usr/bin/perl
use PGPLOT;

#################################################################################################
#												#
#	find_limit_envelope.perl: estimate limit envelope around given data			#
#												#
#		data are in dataseeker format	(col names are in  <col>_avg)			#
#												#
#		author: t. isobe (tisobe@cfa.harvard.edu)					#
#												#
#		last update Apr 09, 2009							#
#												#
#################################################################################################

#
#--- directory setting
#

$www_dir1 = '/data/mta/www/mta_envelope_trend/';
$www_dir2 = '/data/mta/www/mta_envelope_trend/SnapShot/';
$save_dir = '/data/mta/Script/Fitting/Trend_script/Save_data/';

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

$fits   = $ARGV[0];		#--- input fits file, dataseeker format
$col    = $ARGV[1];		#--- data column name e.g. oobthr44_avg
$nterms = $ARGV[2];		#--- degree of polynomial fit, 2 or 3 (linear and quad)
$lim_c  = $ARGV[3];		#--- operational limit: yellow (y) or red (r) 
$range  = $ARGV[4];		#--- whether this is full, quarterly, or weekly
$lim_s  = $ARGV[5];		#--- limit selection: mta, op, or both


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

if($range =~ /f/i){
	$end_time = $uyear + 1900 + 1;
	$box_length   = 0.019178082;    	#--- binning size: one week in year
}elsif($range =~ /q/i){
	$end_time   = $today;
	$datastart  = $today - 0.25;
	$box_length = 5.479452054e-3;		#---- 2 days box size
}elsif($range =~ /w/i){
	$end_time   = $today    - 0.019178082;	#---- the data range is between two weeks ago and one week ago
	$datastart  = $end_time - 0.019178082;
#	$box_length = 2.283105022e-4;		#---- 2 hrs box size
	$box_length = 5.707762557e-5;		#---- 30 min box size
}

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
$num_break++;

push(@break_point, $end_time);

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

$line = "$fits".'[cols time,'."$col".']';

$in_line = `dmlist \"$line\" opt=data`;
@in_data = split(/\n/, $in_line);


#
#--- read data; convert the time to fraction of year
#

@time_tmp  = ();
@data_tmp  = ();
$total_tmp = 0;

@time      = ();
@data      = ();
$total     = 0;			#---- total # of data
$plus      = 0;			#---- # of data above zero
$zero      = 0;			#---- # of data equal to zero
$minus     = 0;			#---- # of data below zero
$hchk      = 0;			#---- indicator to tell whether data is from dataseeker

OUTER:
foreach $ent (@in_data){
	@atemp = split(/\s+/, $ent);
	if($atemp[1] =~/\d/){
		if($atemp[0] =~ /\d/){
#
#--- for the case, the data are already binned into one hour
#
			if($atemp[1] == 0){
				next OUTER;
			}elsif($atemp[1] < 31536000){
				$hchk = 1;
				if($atemp[2] != -99.0 && $atemp[2] !~ /NaN/i){
					$dom = $atemp[1];
					dom_to_ydate();
					if($ydate >= $datastart){
						push(@time, $ydate);
						push(@data, $atemp[2]);
						$total++;
					}
				}
			}else{
#
#--- for the case the data are from dataseeker and 5 min interval
#
				$hchk = 0;
				if($atemp[2] != -99.0 && $atemp[2] !~ /NaN/i){
					push(@time_tmp, $atemp[1]);
					push(@data_tmp, $atemp[2]);
					$total_tmp++;
					if($atemp[2] > 0){
						$plus++;
					}elsif($atemp[2] < 0){
						$minus++;
					}else{
						$zero++;
					}
				}
			}
		}else{
			if($atemp[2] == 0){
				next OUTER;
			}elsif($atemp[2] < 31536000){
				$hchk = 1;
				if($atemp[3] != -99.0 && $atemp[3] !~ /NaN/i){
					$dom = $atemp[2];
					dom_to_ydate();
					if($ydate >= $datastart){
						push(@time, $ydate);
						push(@data, $atemp[3]);
						$total++;
					}
				}
			}else{
				$hchk = 0;
				if($atemp[3] != -99.0 && $atemp[3] !~ /NaN/i){
					push(@time_tmp, $atemp[2]);
					push(@data_tmp, $atemp[3]);
					$total_tmp++;
					if($atemp[3] > 0){
						$plus++;
					}elsif($atemp[3] < 0){
						$minus++;
					}else{
						$zero++;
					}
				}
			}
		}
	}
}

#
#--- if the data is from dataseeker (5 min interval), we need further data manupulation
#

if($hchk ==  0){
	if($hour_binning  == 0){
#
#--- for the case,  we decided to keep the original time interval
#
		@time  = ();
		@data  = ();
		$total = 0;
		for($m = 0; $m < $total_tmp; $m++){
			$year_date = sec1998_to_fracyear($time_tmp[$m]);
			if($year_date >= $data_start){
				push(@time, $year_date);
				push(@data, $data_tmp[$m]);
				$total++;
			}
		}
	}else{
#
#--- for the case, we use one hour time interval
#
		$pos_ratio  = $plus/$total_tmp;
		$neg_ratio  = $minus/$total_tmp;
		$zero_ratio = $zero/$total_tmp;
		$t_int      = 3600;
		$t_int_mid  = 1800;

		if($range =~ /f/i){
#
#--- if it is full range, take one day interval
#
			$t_int      = 86400;
			$t_int_mid  = 43200;
		}
		
#
#--- if the data have both positive and negative values, or more than 98% of
#--- the data is zero, keep all the data point, when binning.
#
		if($neg_ratio > 0.02 || $zero_ratio > 0.99){
			$begin = $time_tmp[0];
			$end   = $begin + $t_int;
			$sum   = $data_tmp[0];
			$sum_c = 1;
			for($i = 1; $i < $total_tmp; $i++){
				if($time_tmp[$i] < $end){
					$sum += $data_tmp[$i];
					$sum_c++;
				}elsif($time_tmp[$i] >= $end){
					if($sum_c > 0){
						$avg = $sum/$sum_c;
						$sec       = $begin + $t_int_mid;
						$year_date = sec1998_to_fracyear($sec);
						if($year_date >= $datastart){
							push(@time, $year_date);
							push(@data, $avg);
							$total++;
						}
					}

					$begin = $end;
					$end   = $begin + 3600;
					$sum   = $data_tmp[$i];
					$sum_c = 1;
				}
			}
		}else{
#
#--- for the case, there are enough positive values (at least more than 3% of data are positive),
#--- drop "0", values before making hourly average.
#
			$begin = $time_tmp[0];
			$end   = $begin + 3600;
			$sum   = $data_tmp[0];
			if($sum > 0){
				$sum_c = 1;
			}else{
				$sum_c = 0;
			}
			for($i = 1; $i < $total_tmp; $i++){
				if($time_tmp[$i] < $end){
					if($data_tmp[$i] > 0){
						$sum += $data_tmp[$i];
						$sum_c++;
					}
				}elsif($time_tmp[$i] >= $end){
					if($sum_c > 0){
						$avg = $sum/$sum_c;
						$sec       = $begin + 1800;
						$year_date = sec1998_to_fracyear($sec);
						if($year_date >= $datastart){
							push(@time, $year_date);
							push(@data, $avg);
							$total++;
						}
					}

					while($end < $time_tmp[$i]){
						$begin = $end;
						$end   = $begin + 3600;
					}
					$sum   = $data_tmp[$i];
					if($sum > 0){
						$sum_c = 1;
					}else{
						$sum_c = 0;
					}
				}
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
#--- find box interval  min and max values for the data
#--- if $fstart1 > $datastart, there will be two data sets (and possibly more)
#

boxed_interval_min_max();

if($chk > 0){
	open(OUT, ">$out_data");
	print OUT "Fitting Reuslts for $msid\n\n";
	print OUT "Fitting Failed\n";
	close(OUT);

	system("cp $save_dir/null_data_s.gif $out_name");
	exit 1;
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

if($range =~ /f/i){
	$xmin     = 1999;
	$xmax     = $end_time;
	$xdiff    = $xmax - $xmin;
	$xmin    -= 0.05 * $ xdiff;
	$xmax    += 0.05 * $ xdiff;
	$xdiff    = $xmax - $xmin;
	$xmid     = $xmin + 0.5 * $xdiff;
	$xtxt     = $xmin + 0.1 * $xdiff;
}elsif($range =~ /q/i || $range =~ /\w/){
	$y_beg    = int($datastart);
	$ychk     = 4.0 * int (0.25 * $y_beg);
	if($ychk == $y_beg){
		$multi = 366;
	}else{
		$multi = 365;
	}
	$f_beg    = $datastart - $y_beg;
	$f_beg   *= $multi;
	$y_end    = int($end_time);
	$f_end    = $end_time - $y_end;
	if($y_end > $y_beg){
		$ychk     = 4.0 * int (0.25 * $y_end);
		if($ychk == $y_end){
			$multi2 = 366;
		}else{
			$multi2 = 365;
		}
		$f_end  *= $multi2;
		$f_end  += $multi;
	}else{
		$f_end  *= $multi;
	}
	$diff     = $f_end - $f_beg;
	$xmin     = $f_beg - 0.1 * $diff;
	$xmax     = $f_end + 0.1 * $diff;
	
	$xdiff    = $xmax - $xmin;
	$xmin    -= 0.05 * $ xdiff;
	$xmax    += 0.05 * $ xdiff;
	$xdiff    = $xmax - $xmin;
	$xmid     = $xmin + 0.5 * $xdiff;
	$xtxt     = $xmin + 0.1 * $xdiff;
}

#
#--- setting y plotting range: $test_sig is from sub: boxed_interval_min_max()
#

$ymin  = $test_avg - 4.0 * $test_sig;
$ymax  = $test_avg + 4.0 * $test_sig;

if($neg_ratio == 0.0 && $ymin < 0){
	if($zero_ratio > 0.2){
		$aval = abs($ymin);
		if($aval > 0.1 * $ymax){
			$ymin = -0.1 * $aval;
		}
	}
}elsif($ymin == 0){
	$ymin = -0.1 * $ymax;
}

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

if($range =~ /f/i){
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
}else{
	pgsch(2);
	pgslw(10);
	OUTER:
	for($i = 0; $i < $total; $i++){
		if($time[$i] < $datastart){
			next OUTER;
		}elsif($time[$i] > $end_time){
			last OUTER;
		}

		$y_part = int($time[$i]);
		$d_part = $time[$i] - $y_part;
		if($y_part > $y_beg){
			$d_part *= $multi2;
			$d_part += $multi;
		}else{
			$d_part *= $multi;
		}
		if($data[$i] >= $y_low && $data[$i] <= $y_top){
			pgsci(1);
		}elsif($data[$i] <= $r_low || $data[$i] >= $r_top){
			pgsci(2);
		}else{
			pgsci(6);
		}
		pgpt(1,$d_part, $data[$i], 1);
		pgsci(1);
	}
	pgsch(1);
	pgslw(5);
}


#
#--- estimate envelopes
#

for($k = 0; $k < $num_break; $k++){

#
#--- svdfit is a polynomial fit routine; it works well if the data means (both x and y)
#--- is close to the data range. So we shift the data to near the bottom of the x data range,
#--- and move the y mean to 0.
#

	if(${box_cnt.$k} > 0){
		@adj_x  = ();
		if($range =~ /\q/i || $range =~ /w/i){		#--- this is for "q" and "w" case
			$b_year = int ($break_point[$k]);
			$f_year = $break_point[$k] - $b_year;
			$lchk   = 4.0 * int(0.25 * $b_year);
			if($b_year == $lchk){
				$y_add = 366;
			}else{
				$y_add = 365;
			}
			$f_year *= $y_add;
			$break_point[$k] = $f_year;
#
#--- if the data range is for a quoterly or weekly, the date of the data should, at most, span
#--- 2 year or less. So here we can rewirite break_point[$k+1] into doy without any futher problems.
# 
			$b_year2 = int ($break_point[$k+1]);
			$f_year2 = $break_point[$k+1] - $b_year;
			if($b_year2 > $b_year){
				$lchk    = 4.0 * int(0.25 * $b_year);
				if($b_year == $lchk){
					$y_add2 = 366;
				}else{
					$y_add2 = 365;
				}
				$f_year2 *= $y_add2;
				$f_year2 += $y_add;
			}else{
				$f_year2 *= $y_add;
			}
			$break_point[$k+1] = $f_year2;
		}
		for($j = 0; $j < ${box_cnt.$k}; $j++){
			if($range =~ /\q/i || $range =~ /w/i){
				$y_part = int (${box_time_s.$k}[$j]);
				$f_part = ${box_time_s.$k}[$j] - $y_part;
				$lchk     = 4.0 * int(0.25 * $y_part);
				if($y_part == $lchk){
					$y_length = 366;
				}else{
					$y_length = 365;
				}
				$f_part *= $y_length;
				if($y_part > $b_year){
					$f_part += $y_add;
				}
				$xtemp = $f_part - $f_year;
		
			}else{
        			$xtemp = ${box_time_s.$k}[$j] - $break_point[$k];
			}
        		push(@adj_x, $xtemp);
		}

		$sumy_min = 0;
		$sumy_max = 0;
		for($j = 0; $j < ${box_cnt.$k}; $j++){
			$sumy_min += ${box_min.$k}[$j];
			$sumy_max += ${box_max.$k}[$j];
		}
		$avgy_min     = $sumy_min/${box_cnt.$k};
		$avgy_max     = $sumy_max/${box_cnt.$k};
		${avg_min.$k} = $avgy_min;
		${avg_max.$k} = $avgy_max;

		@adj_y_min = ();
		@adj_y_max = ();
		for($j = 0; $j < ${box_cnt.$k}; $j++){
			$y_temp = ${box_min.$k}[$j] - $avgy_min;
			push(@adj_y_min, $y_temp);
			$y_temp = ${box_max.$k}[$j] - $avgy_max;
			push(@adj_y_max, $y_temp);
		}

#
#--- envelope computation; first round
#
		
#
#--- lower envelope
#
		
#		if($nterms > 2){
			@x_in   = @adj_x;
			@y_in   = @adj_y_min;
			$npts   = ${box_cnt.$k};
			$mode   = 0;
		
			svdfit($npts, $nterms);
		
			for($n = 0; $n <= $nterms; $n++){
				${p_min.$n}    = $a[$n];
				${p_min.$n.$k} = $a[$n];
			}
#		}else{
#			@xdata    = @adj_x;
#			@ydata    = @adj_y_min;
#			$data_cnt = ${box_cnt.$k};
#
#			robust_fit();
#
#			$n = 0;
#			${p_min.$n}    = $int;
#			${p_min.$n.$k} = $int;
#			$n = 1;
#			${p_min.$n}    = $slope;
#			${p_min.$n.$k} = $slope;
#		}
			

#
#---- upper envelope
#

#		if($nterms > 2){
			@y_in   = @adj_y_max;
	
			svdfit($npts, $nterms);
		
			for($n = 0; $n <= $nterms; $n++){
				${p_max.$n}    = $a[$n];
				${p_max.$n.$k} = $a[$n];
			}
#		}else{
#			@ydata    = @adj_y_max;
#			$data_cnt = ${box_cnt.$k};
#
#			robust_fit();
#
#			$n = 0;
#			${p_max.$n}    = $int;
#			${p_max.$n.$k} = $int;
#			$n = 1;
#			${p_max.$n}    = $slope;
#			${p_max.$n.$k} = $slope;
#		}

#
#---- compute standard deviation from the the fitting line
#

		$sum_min  = 0;
		$sum_min2 = 0;
		$sum_max  = 0;
		$sum_max2 = 0;
		for($j = 0; $j < ${box_cnt.$k}; $j++){
			
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

		$pmin_avg = $sum_min/${box_cnt.$k};
		$pmin_sig = sqrt($sum_min2/${box_cnt.$k} - $pmin_avg * $pmin_avg);
	
		$pmax_avg = $sum_max/${box_cnt.$k};
		$pmax_sig = sqrt($sum_max2/${box_cnt.$k} - $pmax_avg * $pmax_avg);

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
		for($j = 0; $j < ${box_cnt.$k}; $j++){

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
#			if($nterms > 2){
				svdfit($npts, $nterms);

				for($n = 0; $n <= $nterms; $n++){
					${p_min.$n}    = $a[$n];
					${p_min.$n.$k} = $a[$n];
				}
#			}else{
#				@xdata = @x_in;
#				@ydata = @y_in;
#				$data_cnt = $npts;
#
#				robust_fit();
#
#				$n = 0;
#				${p_min.$n}    = $int;
#				${p_min.$n.$k} = $int;
#				$n = 1;
#				${p_min.$n}    = $slope;
#				${p_min.$n.$k} = $slope;
#			}
		}
#
#---- upper envelope
#
		@x_in = ();
		@y_in = ();
		$npts = 0;
		for($j = 0; $j < ${box_cnt.$k}; $j++){
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
#			if($nterms > 2){
				svdfit($npts, $nterms);
	
				for($n = 0; $n <= $nterms; $n++){
					${p_max.$n}    = $a[$n];
					${p_max.$n.$k} = $a[$n];
				}
#			}else{
#				@xdata = @x_in;
#				@ydata = @y_in;
#				$data_cnt = $npts;
#
#				robust_fit();
#
#				$n = 0;
#				${p_min.$n}    = $int;
#				${p_min.$n.$k} = $int;
#				$n = 1;
#				${p_min.$n}    = $slope;
#				${p_min.$n.$k} = $slope;
#			}
		}

#
#---- compute standard deviation from the the fitting line (again)
#

		$sum_min  = 0;
		$sum_min2 = 0;
		$sum_max  = 0;
		$sum_max2 = 0;
		for($j = 0; $j < ${box_cnt.$k}; $j++){
			
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
		$pmin_avg = $sum_min/${box_cnt.$k};
		$pmin_sig = sqrt($sum_min2/${box_cnt.$k} - $pmin_avg * $pmin_avg);
	
		$pmax_avg = $sum_max/${box_cnt.$k};
		$pmax_sig = sqrt($sum_max2/${box_cnt.$k} - $pmax_avg * $pmax_avg);

#
#--- plot the lower envelope
#

		pgsci(4);
		$x_range = $break_point[$k+1] - $break_point[$k];
		$step = $x_range/100;

		$y_est = ${p_min.0}  - $widen * $pmin_sig + $avgy_min;
		pgmove($break_point[$k], $y_est);
		for($j = 1; $j < 100; $j++){
			$x_adj = $step * $j;
			$y_est = 0;
			for($n = 0; $n <= $nterms; $n++){
				$y_est += ${p_min.$n} * power($x_adj, $n);
			}
			$y_est = $y_est - $widen * $pmin_sig + $avgy_min;
			$x_est = $x_adj + $break_point[$k];

			pgdraw($x_est, $y_est);
		}

#
#--- plot the upper envelope
#

		$y_est = ${p_max.0}  + $widen * $pmax_sig + $avgy_max;
		pgmove($break_point[$k], $y_est);
		for($j = 1; $j < 100; $j++){
			$x_adj = $step * $j;
			$y_est  = 0;
			for($n = 0; $n <= $nterms; $n++){
				$y_est += ${p_max.$n} * power($x_adj, $n);
			}
			$y_est = $y_est + $widen * $pmax_sig + $avgy_max;
			$x_est = $x_adj + $break_point[$k];

			pgdraw($x_est, $y_est);
		}
		pgsci(1);
	}
}

pgsci(1);

#
#--- check whether the lower limt will be violated in near future
#

if($range =~ /f/i){
	$last       = $num_break -1;
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

pgsci(5);
pgarro(2008.3, $ymin, 2008.3, $head);
pgsci(1);
pgptxt(2008.3 $ymin, 90, 0, "ACIS Det House Off");


if($range =~/\q/i || $range =~ /w/i){
	pglabel("Time (DOY/Year:$y_beg)", "$col_name", "");
}else{
	pglabel("Time (Year)", "$col_name", "");
}

pgclos();
system("echo ''|gs -sDEVICE=ppmraw  -r64x64 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps|pnmcrop|pnmflip -r270 |ppmtogif > $out_name");

system("rm pgplot.ps");



#
#--- save fitting results etc in a file
#--- OUT for human readable, OUT2 for machine friendly
#

open(OUT, ">$out_data");

if($range =~ /f/i){
	open(OUT2, ">>$www_dir/full_range_results_temp");
}elsif($range =~ /q/i){
	open(OUT2, ">>$www_dir/quarterly_results_temp");
}elsif($range =~ /w/i){
	open(OUT2, ">>$www_dir/weekly_results_temp");
}

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
	$intercept = ${p_min.$nv.$k} + ${avg_min.$k};

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
	$intercept = ${p_max.$nv.$k} + ${avg_max.$k};
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


if($range =~ /f/i){
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
}else{
	print OUT2 '<><>';
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

	if($range =~ /f/i){
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
	}else{
	 	pgsch(2);
	 	pgslw(10);
	 	OUTER:
	 	for($i = 0; $i < $total; $i++){
		  	if($time[$i] < $datastart){
			   	next OUTER;
		  	}elsif($time[$i] > $end_time){
			   	last OUTER;
		  	}
	
		  	$y_part = int($time[$i]);
		  	$d_part = $time[$i] - $y_part;
		  	if($y_part > $y_beg){
			   	$d_part *= $multi2;
			   	$d_part += $multi;
		  	}else{
			   	$d_part *= $multi;
		  	}
		  	if($data[$i] >= $y_low && $data[$i] <= $y_top){
			   	pgsci(1);
		  	}elsif($data[$i] <= $r_low || $data[$i] >= $r_top){
			   	pgsci(2);
		  	}else{
			   	pgsci(6);
		  	}
		  	pgpt(1,$d_part, $data[$i], 1);
		  	pgsci(1);
	 	}
	 	pgsch(1);
	 	pgslw(5);
	}


#
#---- plot envelopes
#

	pgsci(4);
	for($k = 0; $k < $num_break; $k++){
		$x_range = $break_point[$k+1] - $break_point[$k];
		$step    = $x_range/100;
		$n       = 0;
		$y_est   = ${p_min.$n.$k}  - $widen * $pmin_sig + ${avg_min.$k};

		pgmove($break_point[$k], $y_est);

		for($j = 1; $j < 100; $j++){
			$x_adj = $step * $j;
			$y_est = 0;
			for($n = 0; $n <= $nterms; $n++){
				$y_est += ${p_min.$n.$k} * power($x_adj, $n);
			}
			$y_est = $y_est - $widen * $pmin_sig + ${avg_min.$k};
			$x_est = $x_adj + $break_point[$k];
			pgdraw($x_est, $y_est);
		}
	}
	
	for($k = 0; $k < $num_break; $k++){
		$x_range = $break_point[$k+1] - $break_point[$k];
		$step    = $x_range/100;
		$n       = 0;
		$y_est   = ${p_max.$n.$k}  + $widen * $pmax_sig + ${avg_max.$k};

		pgmove($break_point[$k], $y_est);

		for($j = 1; $j < 100; $j++){
			$x_adj = $step * $j;
			$y_est = 0;
			for($n = 0; $n <= $nterms; $n++){
				$y_est += ${p_max.$n.$k} * power($x_adj, $n);
			}
			$y_est = $y_est + $widen * $pmax_sig + ${avg_max.$k};
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
		$intercept = ${p_min.$nv.$k} + ${avg_min.$k};
	
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
		$intercept = ${p_max.$nv.$k} + ${avg_max.$k};
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
	
	
	if($range =~ /f/i){
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
	}else{
		print OUT2 '<><>';
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
		$y_est = 0;
		for($n = 0; $n <= $nterms; $n++){
			$y_est += ${a.$n} * power($x_est, $n);
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


###############################################################################
###sec1998_to_fracyear: change sec from 1998 to time in year               ####
###############################################################################

sub sec1998_to_fracyear{

        my($t_temp, $normal_year, $leap_year, $year, $j, $k, $chk, $jl, $base, $yfrac, $year_date);

        ($t_temp) = @_;

        $t_temp +=  86400;

        $normal_year = 31536000;
        $leap_year   = 31622400;
        $year        = 1998;

        $j = 0;
        OUTER:
        while($t_temp > 1){
                $jl = $j + 2;
                $chk = 4.0 * int(0.25 * $jl);
                if($chk == $jl){
                        $base = $leap_year;
                }else{
                        $base = $normal_year;
                }

                if($t_temp > $base){
                        $year++;
                        $t_temp -= $base;
                        $j++;
                }else{
                        $yfrac = $t_temp/$base;
                        $year_date = $year + $yfrac;
                        last OUTER;
                }
        }

        return $year_date;
}




#######################################################################################################
### boxed_interval_min_max: find  min and max points in a given interval  and create a new data set ###
#######################################################################################################

sub boxed_interval_min_max{

#
#--- first remove extreme outlyers
#

	@gtemp  = sort{$a<=>$b} @data;
	$gstart = int (0.01 * $total);
	$gstop  = $total - $gstart;
	$gdiff  = $gstop - $gstart;
	$gtot   = 0;
	$gtot2  = 0;
	$gtot3  = 0;
	$gtot4  = 0;
	$sum    = 0;
	$sum2   = 0;
	$sump   = 0;
	$sump2  = 0;
	$chk    = 0;
	for($i = $gstart; $i < $gstop; $i++){
		$sum  += $gtemp[$i];
		$sum2 += $gtemp[$i] * $gtemp[$i];
		$gtot++;
		if($gtemp[$i] == 0){
			$gtot2++;
		}elsif($gtemp[$i] > 0){
			$sump  += $gtemp[$i];
			$sump2 += $gtemp[$i] * $gtemp[$i];
			$gtot3++;
		}elsif($gtemp[$i] < 0){
			$gtot4++;
		}
	}
	$rchk  = $gtot2/$gdiff;
	$rchkn = $gtot4/$gdiff;
#
#--- if most of the data is "0", set the range between -1 and 1.
#

	if($rchk > 0.98){
		$gtot     = $gtot2;
		$test_avg = 0;
		$test_sig = 1.0;
	}
	if($gtot == 0){
		$chk = 1;
	}else{ 
#
#--- check whether there is the negative data; if that is the case, 
#--- we include "0" as a part of the data, since "0" is middle of the data.
#--- if not, exlculde "0", since "0" means most likely "no data".
#
		if($rchk < 0.98){
			if($rchkn < 0.01){
				$test_avg = $sump/$gtot3;
				$var      = $sump2/$gtot3 - $test_avg * $test_avg;
				if($var < 0){
					$var = 2 * abs($var);
				}elsif($var == 0){
					$var = 0.01;
				}
				$test_sig     = sqrt($var);
				$t_min = $test_avg -  4.0 * $test_sig;
				$t_max = $test_avg +  4.0 * $test_sig;
#				if($rchk > 0.5){
#					if($t_min > 0){
#						$t_min = 0;
#					}
#				}
					
			}else{
				$test_avg = $sum/$gtot;
				$var      = $sum2/$gtot - $test_avg * $test_avg;
				if($var < 0){
					$var = 2 * abs($var);
				}elsif($var == 0){
					$var = 0.01;
				}
				$test_sig     = sqrt($var);
				$t_min = $test_avg -  4.0 * $test_sig;
				$t_max = $test_avg +  4.0 * $test_sig;
			}
		}
#
#---- try again to limit data range
#
		$sum   = 0;
		$sum2  = 0;
		$t_tot = 0;
		for($i = 0; $i < $total; $i++){
			if($data[$i] >= $t_min && $data[$i] <= $t_max){
				$sum  += $data[$i];
				$sum2 += $data[$i] * $data[$i];
				$t_tot++;
			}
		}
		$test_avg = $sum/$t_tot;
		$var      = $sum2/$t_tot - $test_avg * $test_avg;
		if($var < 0){
			$var = 2 * abs($var);
		}elsif($var == 0){
			$var = 0.1;
		}
		$test_sig     = sqrt($var);
		$t_min = $test_avg -  3.0 * $test_sig;
		$t_max = $test_avg +  3.0 * $test_sig;
#		if($rchk > 0.5){
#			if($t_min > 0){
#				$t_min = 0;
#			}
#		}
	
		if($test_sig < 0){
			$chk = 1;
		}
	}

	if($chk ==  0){

#
#---- initialize data arrays according to # of breaking points
#

		for($k = 0; $k < $num_break; $k++){
			@{data_s.$k} = ();
			@{time_s.$k} = ();
			${cnt.$k}    = 0;
		}
			
		OUTER:
		for($i = 0; $i < $total; $i++){
			if($data[$i] >= $t_min && $data[$i] <= $t_max){
#
#--- IRU 1&2 were on at the same time between 2003.43 and 2003.55.
#--- this causes a fitting a misbehavior; the data between them 
#--- are excluded from a fitting data_s.
#
				if($time[$i] > 2003.40 && $time[$i] < 2003.60){
					next OUTER;
				}

				for($k = 0; $k < $num_break; $k++){
					if($time[$i] >= $break_point[$k] && $time[$i] < $break_point[$k+1]){
						push(@{data_s.$k}, $data[$i]);
						push(@{time_s.$k}, $time[$i]);
						${cnt.$k}++;
					}
				}
			}
		}

		for($k = 0; $k < $num_break; $k++){
			$sum  = 0;
			$sum2 = 0;
			$add  = 0;
			for($j = 0; $j < ${cnt.$k}; $j++){
				$sum  += ${data_s.$k}[$j];
				$sum2 += ${data_s.$k}[$j] * ${data_s.$k}[$j];
				$add++;
			}
			if($add > 0){
				$n_avg = $sum/$add;
				$var   = $sum2/$add - $n_avg * $n_avg;
				if($var < 0){
					$var = 2.0 * abs($var);
				}elsif($var == 0){
					$var = 0.1;
				}
				$std   = sqrt($var);
				$l_lim = $n_avg - 3.0 * $std;
				$u_lim = $n_avg + 3.0 * $std;
	
				@test_data = ();
				@test_time = ();
				$test_cnt  = 0;
				$t_begin   = $break_point[$k];
	
				for($j = 0; $j < ${cnt.$k}; $j++){
					if(${data_s.$k}[$j]>= $l_lim && ${data_s.$k}[$j] <= $u_lim){
						push(@test_data, ${data_s.$k}[$j]);
						push(@test_time, ${time_s.$k}[$j]);
						$test_cnt++;
					}
				}

				boxed_interval_binning();
			
				@{box_time_s.$k} = @box_time;
				@{box_min.$k}    = @box_min;
				@{box_max.$k}    = @box_max;
				${box_cnt.$k}    = $w_cnt;
			}else{
			
				@{box_time_s.$k} = ();
				@{box_min.$k}    = ();
				@{box_max.$k}    = ();
				${box_cnt.$k}    = 0;
			}
		}
	}
}

##################################################################################
### boxed_interval_binning: binning the data for a given box size              ###
##################################################################################

sub boxed_interval_binning{
	my ($i);
	@box_min    = ();
	@box_max    = ();
	@box_time   = ();
	$w_cnt       = 0;

	$start       = $t_begin;
	$end         = $start + $box_length;
	$wmin        = 1e14;
	$wmax        = -1e14;

	if($start > $test_time[0]){
		while($start > $test_time[0]){
			$start -=  $box_length;
		}
		$end    = $start + $box_length;
	}

	for($i = 1; $i < $test_cnt; $i++){
		if($test_time[$i] >= $start && $test_time[$i] < $end){
			if($test_data[$i] < $wmin){
				$wmin = $test_data[$i];
			}
			if($test_data[$i] > $wmax){
				$wmax = $test_data[$i];
			}
		}elsif($test_time[$i] >= $end){
				
			$mid   = $start + 0.5 * $box_length;
			if($wmin < 100000 && $wmax > -100000){
				push(@box_time, $mid);
				push(@box_min, $wmin);
				push(@box_max, $wmax);
				$w_cnt++;
			}

			OUTER:
			while($test_time[$i] >= $end){
				$start = $end;
				$end   = $start + $box_length;
				if($test_time[$i] >= $start && $test_time[$i] < $end){
					last OUTER;
				}
			}
			$wmin =  1e14;
			$wmax = -1e14;
			
			if($data[$i] < $wmin){
				$wmin = $test_data[$i];
			}
			if($test_data[$i] > $wmax){
				$wmax = $test_data[$i];
			}
		}
	}

	$mid   = $start + 0.5 * $box_length;
	if($wmin < 100000 && $wmax > -100000){
		push(@box_time, $mid);
		push(@box_min, $wmin);
		push(@box_max, $wmax);
		$w_cnt++;
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

