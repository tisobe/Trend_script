#!/opt/local/bin/perl
use PGPLOT;

#################################################################################################
#												#
#	recompute_limit_data.perl: create full range min/max data file from a data file		#
#												#
#												#
#		author: t. isobe (tisobe@cfa.harvard.edu)					#
#												#
#		last update Aug 21, 2012							#
#												#
#################################################################################################

#
#--- directory setting
#

open(FH, "/data/mta/Script/Fitting_linux/hosue_keeping/dir_list");

while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
 close(FH);


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

$limit_table1 = "$hosue_keeping/current_op_limits.db";
$limit_table2 = "$save_dir/limit_table";



#------------------------------------------------------------------------------------------------

#
#--- read data file name  etc
#

$fits   = $ARGV[0];		#--- input fits file, dataseeker format
$col    = $ARGV[1];		#--- data column name e.g. oobthr44_avg 
$lbox   = $ARGV[2];		#--- sampling length: s: 2 days, w: 7 days, m: 30 days;

if($lbox =~ /d/){
	$m = 2;
}elsif($lbox =~ /\w/ && $lbox !~ /\d/){
	$m = 3;
}else{
	$m = 2;
}

$range  = 'f';			#--- only for full range data

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
	if($lbox =~ /s/i){
		$box_length = 5.479452054e-3;		#---- 2 days box size
	}elsif($lbox =~ /w/i){
		$box_length   = 0.019178082;    	#--- binning size: one week in year
	}elsif($lbox =~ /m/i){
		$box_length   = 0.083333333;    	#--- binning size: one month in year
	}else{
		$box_length = 5.479452054e-3;		#---- 2 days box size
	}

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
#$m           = 2;
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
#--- extract data needed
#

#$line = "$fits".'[cols time,'."$col".']';
$line = "$fits".'[cols col1,col2]';
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
	if($atemp[0] =~ /\d/){
		push(@time, $atemp[1]);
		push(@data, $atemp[2]);
		$total++;
	}elsif($atemp[0] eq "" && $atemp[1] =~ /\d/){
		push(@time, $atemp[2]);
		push(@data, $atemp[3]);
		$total++;
	}
}

	
#
#--- find box interval  min and max values for the data
#--- if $fstart1 > $datastart, there will be two data sets (and possibly more)
#

boxed_interval_min_max();


#
#--- print out min and max data
#

$min_max_file = "$msid".'_min_max.fits';

open(OUT, "> data_temp");

for($k = 0; $k < $num_break; $k++){
	for($j= 0; $j < ${box_cnt.$k}; $j++){
		print OUT "${box_time_s.$k}[$j]\t${box_min.$k}[$j]\t${box_max.$k}[$j]\t$k\n";
	}
}
close(OUT);

system("dmcopy  infile=data_temp outfile=$min_max_file clobber=yes");
system("rm data_temp");



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
#--- go though each period separately so that you can use different criteria to choose the limits
#

	OUTER1:
	for($k = 0; $k < $num_break; $k++){
		@pdata = ();
		@ptime = ();
		$ptotal= 0;	
		OUTER:
		for($j = 0; $j < $total; $j++){
#
#--- IRU 1&2 were on at the same time between 2003.43 and 2003.55.
#--- this causes a fitting a misbehavior; the data between them 
#--- are excluded from a fitting data_s.
#
			if($time[$i] > 2003.40 && $time[$i] < 2003.60){
				next OUTER;
			}

			if($time[$j] >= $break_point[$k] && $time[$j] < $break_point[$k+1]){
				push(@pdata, $data[$j]);
				push(@ptime, $time[$j]);
				$ptotal++;
			}
		}
#
#--- first remove extreme outlyers
#
		@gtemp  = sort{$a<=>$b} @pdata;
		$gstart = int (0.0005 * $ptotal);		#<-- modified from 0.001 1/27
		$gstop  = $ptotal - $gstart;
		$gdiff  = $gstop  - $gstart;
		if($gdiff <= 0){
			next OUTER1;
		}
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
		if($gtot <= 0){
			next OUTER1;
		}
		$rchk  = $gtot2/$gdiff;		#--- potion of "0" values
		$rchkn = $gtot4/$gdiff;		#--- potion of negative values
#
#--- if most of the data is "0", set the range between -1 and 1.
#

		if($rchk >= 0.95){
			$gtot     = $gtot2;
			$test_avg = 0;
			$test_sig = 1.0;
			$t_min = -1;
			$t_max =  1;
#
#--- check whether there is the negative data; if that is the case, 
#--- we include "0" as a part of the data, since "0" is middle of the data.
#--- if not, exlculde "0", since "0" means most likely "no data".
#
		}elsif($rchk < 0.95){
			if($rchkn < 0.01){
				if($gtot3 > 0){
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
					$t_min = -1;
					$t_max =  1;
				}
				
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
		for($i = 0; $i < $ptotal; $i++){
			if($pdata[$i] >= $t_min && $pdata[$i] <= $t_max){
				$sum  += $pdata[$i];
				$sum2 += $pdata[$i] * $pdata[$i];
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
		$t_min = $test_avg -  4.0 * $test_sig;
		$t_max = $test_avg +  4.0 * $test_sig;


		@test_data = ();
		@test_time = ();
		$test_cnt  = 0;
		$t_begin   = $break_point[$k];

		for($j = 0; $j < $ptotal; $j++){
			if($pdata[$j] >= $t_min && $pdata[$j] <= $t_max){
				push(@test_data, $pdata[$j]);
				push(@test_time, $ptime[$j]);
				$test_cnt++;
			}
		}

		@{box_time_s.$k} = ();
		@{box_min.$k}    = ();
		@{box_max.$k}    = ();
		${box_cnt.$k}    = 0;

		boxed_interval_binning();
	
		@{box_time_s.$k} = @box_time;
		@{box_min.$k}    = @box_min;
		@{box_max.$k}    = @box_max;
		${box_cnt.$k}    = $w_cnt;
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

