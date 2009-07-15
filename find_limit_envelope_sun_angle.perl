#!/usr/bin/perl
use PGPLOT;

#################################################################################################
#												#
#	find_limit_envelope_sun_angle.perl: estimate limit envelope around given data		#
#												#
#		data are in dataseeker format	(col names are in  <col>_avg)			#
#												#
#		author: t. isobe (tisobe@cfa.harvard.edu)					#
#												#
#		last update Jul 15, 2009							#
#												#
#################################################################################################

#
#--- setting:
#

#------------------------------------------------------------------------------------------------

$start_point  = 40;

$hour_binning = 1;              #--- if you want, hour binning, set this to 1.
                                #--- otherwise, it will use the given binning
                                #--- for the data.

$widen        = 0.0;            #--- widen factor for the envelope

$out_range    = 1.0;		#--- when calcurate the envelopes, how much sigma out from
                                #--- from the average position you want to incude in the computation.
                                #--- the larger the vale, far from the average, and wider envelopes.

#------------------------------------------------------------------------------------------------



#
#--- read data file name  etc
#

$fits   = $ARGV[0];		#--- input fits file, dataseeker format
$col    = $ARGV[1];		#--- data column name e.g. oobthr44_avg
$nterms = $ARGV[2];		#--- degree of polynomial fit, 2 or 3 (linear and quad)

#
#---  a short help will display if no ARGVs are added
#

if($fits eq ''  || $fits =~ /-h/i){
	print "\n\n";
	print 'USAGE: perl  find_limit_envelope.perl <ARGV....>',"\n\n";
	print '$fits   = $ARGV[0];     #--- input fits file, dataseeker format',"\n";
	print '$col    = $ARGV[1];     #--- data column name e.g. oobthr44_avg',"\n";
	print '$nterms = $ARGV[2];     #--- degree of polynomial fit, 2 or 3 (linear and quad)',"\n";

	print "\n\n";

	exit 1;
}

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

$out_name  = "$c_name".'_plot.gif';		#--- plot file name
$out_data  = "$c_name".'_fitting_results';	#--- fitted result output file name

#
#--- extract data needed
#

$line = "$fits".'[cols pt_suncent_ang,'."$col".']';
system("dmlist \"$line\" opt=data > zout");

#
#--- read data
#

open(FH, "zout");

@sun_angle = ();
@data      = ();
$total     = 0;	

OUTER:
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	if($atemp[1] =~/\d/){
		if($atemp[0] =~ /\d/){
			if($atemp[1] == 0){
				next OUTER;
			}
			if($atemp[2] != -99.0 && $atemp[2] !~ /NaN/i){
				push(@sun_angle, $atemp[1]);
				push(@data,      $atemp[2]);
				$total++;
			}
		}else{
			if($atemp[2] == 0){
				next OUTER;
			}
			if($atemp[3] != -99.0 && $atemp[3] !~ /NaN/i){
				push(@sun_angle, $atemp[2]);
				push(@data,      $atemp[3]);
				$total++;
			}
		}
	}
}
close(FH);
system("rm zout");

@temp = sort{$a<=>$b} @sun_angle;
$range_min = $temp[0];
$range_max = $temp[$total -1];

#
#--- if there is no data, say so and quite
#

if($total == 0){
	open(OUT, ">$out_data");
	print OUT "Fitting Reuslts for $msid\n\n";
	print OUT "Fitting Failed\n";
	close(OUT);

	system("cp /data/mta/Script/Fitting/Prep//null_data_s.gif $out_name");
	exit 1;
}

#
#--- find min and max values for the data for a given interval
#

boxed_min_max();

if($chk > 0){
	open(OUT, ">$out_data");
	print OUT "Fitting Reuslts for $msid\n\n";
	print OUT "Fitting Failed\n";
	close(OUT);

	system("cp /data/mta/Script/Fitting/Prep//null_data_s.gif $out_name");
	exit 1;
}

#
#---- plotting starts here
#

pgbegin(0, '"./pgplot.ps"/cps',1,1);
pgsubp(1,1);
pgsch(1);
pgslw(5);

#
#--- establish  x axis range
#

$xmin     = 40;
$xmax     = 190;

$xdiff    = $xmax - $xmin;
$xmin    -= 0.05 * $ xdiff;
$xmax    += 0.05 * $ xdiff;
$xdiff    = $xmax - $xmin;
$xmid     = $xmin + 0.5 * $xdiff;
$xtxt     = $xmin + 0.1 * $xdiff;

#
#--- setting y plotting range: $test_sig is from sub: boxed_min_max()
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
$ytxt  = $ymax - 0.1 * $ydiff;

pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);

#
#--- plot data points
#

for($i = 0; $i < $total; $i++){
	pgpt(1,$sun_angle[$i], $data[$i], 1);
}


#
#--- plotting max and min points for visual testing
#
##pgsch(1);
##pgslw(10);
##pgsci(2);
##for($i = 0; $i < $box_cnt; $i++){
##	pgpt(1,$box_angle[$i], $box_min[$i], 2);
##}
##for($i = 0; $i < $box_cnt; $i++){
##	pgpt(1,$box_angle[$i], $box_max[$i], 2);
##}
##pgsci(1);
##pgsch(1);
##pgslw(5);


#
#--- estimate envelopes
#

#
#--- svdfit is a polynomial fit routine; it works well if the intercept
#--- is close to the data range. So we shift the data to near the
#--- bottom of the x data range.

if($box_cnt > 0){
	@adj_x    = ();
	$sumy_min = 0;
	$sumy_max = 0;
	for($j = 0; $j < $box_cnt; $j++){
        	$xtemp = $box_angle[$j] - $start_point;
        	push(@adj_x, $xtemp);
		$sumy_min += $box_min[$j];
		$sumy_max += $box_max[$j];
	}

	$avgy_min = $sumy_min/$box_cnt;
	$avgy_max = $sumy_max/$box_cnt;

	@adj_y_min = ();
	@adj_y_max = ();
	for($j = 0; $j < $box_cnt; $j++){
		$y_temp = $box_min[$j] - $avgy_min;
		push(@adj_y_min, $y_temp);
		$y_temp = $box_max[$j] - $avgy_max;
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
	$npts   = $box_cnt;
	$mode   = 0;

	svdfit($npts, $nterms);

	for($n = 0; $n <= $nterms; $n++){
		${p_min.$n} = $a[$n];
	}
	
#
#---- upper envelope
#

	@y_in   = @adj_y_max;

	svdfit($npts, $nterms);

	for($n = 0; $n <= $nterms; $n++){
		${p_max.$n} = $a[$n];
	}

#
#---- compute standard deviation from the the fitting line
#

	$sum_min  = 0;
	$sum_min2 = 0;
	$sum_max  = 0;
	$sum_max2 = 0;

	for($j = 0; $j < $box_cnt; $j++){
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
		$diff = $adj_y_min[$j]  - $y_est;
				
		$sum_max  += $diff;
		$sum_max2 += $diff * $diff;
	}

	$pmin_avg = $sum_min/$box_cnt;
	$pmin_sig = sqrt($sum_min2/$box_cnt - $amin_avg * $amin_avg);

	$pmax_avg = $sum_max/$box_cnt;
	$pmax_sig = sqrt($sum_max2/$box_cnt - $amax_avg * $amax_avg);

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
	for($j = 0; $j < $box_cnt; $j++){

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
			${p_min.$n}    = $a[$n];
		}
	}
#
#---- upper envelope
#
	@x_in = ();
	@y_in = ();
	$npts = 0;
	for($j = 0; $j < $box_cnt; $j++){
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
		}
	}

#
#---- compute standard deviation from the the fitting line (again)
#

	$sum_min  = 0;
	$sum_min2 = 0;
	$sum_max  = 0;
	$sum_max2 = 0;
	for($j = 0; $j < $box_cnt; $j++){

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
	$pmin_avg = $sum_min/$box_cnt;
	$pmin_sig = sqrt($sum_min2/$box_cnt - $amin_avg * $amin_avg);

	$pmax_avg = $sum_max/$box_cnt;
	$pmax_sig = sqrt($sum_max2/$box_cnt - $amax_avg * $amax_avg);


#
#--- plot the lower envelope
#

	pgsci(2);
	$x_range = $range_max - $start_point;
	$step = $x_range/100;
	$y_est = ${p_min.0} - $widen * $pmin_sig + $avgy_min;
	pgmove($start_point, $y_est);
	OUTER:
	for($j = 1; $j < 100; $j++){
		$x_adj = $step * $j;
		$y_est  = 0;
		for($n = 0; $n <= $nterms; $n++){
			$y_est += ${p_min.$n} * power($x_adj, $n);
		}
		$y_est = $y_est - $widen * $pmin_sig + $avgy_min;
		$x_est = $start_point + $step * $j;
		if($x_est > $range_max){
			last OUTER;
		}

		pgdraw($x_est, $y_est);
	}

#
#--- plot the upper envelope
#
	$y_est = ${p_max.0} - $widen * $pmin_sig + $avgy_max;
	pgmove($start_point, $y_est);
	OUTER:
	for($j = 1; $j < 100; $j++){
		$x_adj = $step * $j;
		$y_est  = 0;
		for($n = 0; $n <= $nterms; $n++){
			$y_est += ${p_max.$n} * power($x_adj, $n);
		}
		$y_est = $y_est - $widen * $pmax_sig + $avgy_max;
		$x_est = $start_point + $step * $j;
		if($x_est > $range_max){
			last OUTER;
		}

		pgdraw($x_est, $y_est);
	}

	pgsci(1);
}

pgsci(1);

pglabel("Sun Angle", "$col_name", "");

pgclos();
system("echo ''|/opt/local/bin/gs -sDEVICE=ppmraw  -r64x64 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps|pnmcrop|pnmflip -r270 |ppmtogif > $out_name");

system("rm pgplot.ps");

#
#--- save fitting results etc in a file
#

open(OUT, ">$out_data");

print OUT "Fitting Reuslts for $msid\n\n";

print OUT "\tIntercept @ $start_point\t";
print OUT "x\t\t";
for($n = 2; $n < $nterms; $n++){
	print OUT 'x**'."$n\t\t";
}
print OUT "\n";
print OUT "lower:\t";
$intercept = ${p_min.0} + $avgy_min;
print OUT "$intercept\t";
for($n = 1; $n <= $nterms; $n++){
	print OUT "${p_min.$n}\t";
}
print OUT "\n";
print OUT "upper:\t";
$intercept = ${p_max.0} + $avgy_max;
print OUT "$intercept\t";
for($n = 1; $n <= $nterms; $n++){
	print OUT "${p_max.$n}\t";
}
print OUT "\n";


################################################################################
### boxed_min_max: find box min and max points and create a new data set ###
################################################################################

sub boxed_min_max{

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
	
		if($test_sig < 0){
			$chk = 1;
		}
	}

	if($chk ==  0){

		OUTER:
		for($i = 0; $i < $total; $i++){
			if($data[$i] >= $t_min && $data[$i] <= $t_max){
				push(@data_s,      $data[$i]);
				push(@sun_angle_s, $sun_angle[$i]);
				$cnt++;
			}
		}

		$sum  = 0;
		$sum2 = 0;
		$add  = 0;
		for($j = 0; $j < $cnt; $j++){
			$sum  += $data_s[$j];
			$sum2 += $data_s[$j] * $data_s[$j];
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
			@test_angle = ();
			$test_cnt  = 0;
			$t_begin   = 40;
	
			for($j = 0; $j < $cnt; $j++){
				if($data_s[$j]>= $l_lim && $data_s[$j] <= $u_lim){
					push(@test_data, $data_s[$j]);
					push(@test_angle, $sun_angle_s[$j]);
					$test_cnt++;
				}
			}

			boxed_binning();
			
		}else{
			
			@box_angle  = ();
			@box_min    = ();
			@box_max    = ();
			$box_cnt    = 0;
		}
	}
}

##################################################################################
##################################################################################
##################################################################################

sub boxed_binning{
	my ($i, $n,  $m);
	$box_length = 1;
	@box_min    = ();
	@box_max    = ();
	@box_angle   = ();
	$w_cnt       = 0;

	for($m = 0; $m < 300; $m++){
		${bin_min.$m} =  1e14;
		${bin_max.$m} = -1e14;
	}

	OUTER:
	for($i = 0; $i < $test_cnt; $i++){
		for($m = 0; $m < 300; $m++){
			$ang1 = $t_begin + 0.5 * $m;
			$ang2 = $ang1 + 0.5;
			if($test_angle[$i] >= $ang1 && $test_angle[$i] < $ang2){
				if($test_data[$i] < ${bin_min.$m}){
					${bin_min.$m} = $test_data[$i];
				}
				if($test_data[$i] > ${bin_max.$m}){
					${bin_max.$m} = $test_data[$i];
				}
				next OUTER;
			}
		}
	}

	OUTER:
	for($m = 0; $m < 300; $m++){
		if(${bin_min.$m} < 1000000 && ${bin_max.$m} > -1000000){
			$angle = $t_begin + 0.5 * $m;
			if($angle > $range_max){
				last OUTER;
			}
			push(@box_angle, $angle);
			push(@box_min,   ${bin_min.$m});
			push(@box_max,   ${bin_max.$m});
			$box_cnt++;
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

