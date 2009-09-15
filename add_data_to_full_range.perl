#!/usr/bin/perl 

#################################################################################################
#												#
#	add_data_to_full_range.perl: add one month amount of new data to full range data set	#
#												#
#		author: t. isobe (tisobe@cfa.harvard.edu)					#
#												#
#		last update Sep 14, 2009							#
#												#
#################################################################################################


#----------------------------------------------------------------------------------
#    set a few things before moving to others...
#

$www_dir    = '/data/mta/www/mta_envelope_trend/';
$save_dir   = '/data/mta/Script/Fitting/Trend_script/Save_data/';

$box_length = 0.019178082;    #--- box size: a wee in year.

#----------------------------------------------------------------------------------

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

$y_date     = $today + $uyday/$y_length;	#----- in format of 2009.0136
$y_time     = "$today:$uyday:00:00:00";		#----- in format of 2009:050:00:00:00
$today_time = ydate_to_y1998sec($y_time);	#----- in sec from 1998

#
#--- find a time of a month ago; this will be cut and joint time for two data sets.
#

$month_ago      = $today_time - 2592000;
$month_ago_in_y = sec1998_to_fracyear($month_ago);

#
#--- find the past data location
#

#
#--- main full range data sets
#

$f_line = `ls $www_dir/Full_range/*/Fits_data/*_data.fits*`;
@f_list =  split(/\s+/, $f_line);
#---------TEST TEST
#$f_line = `ls /data/mta/Script/Fitting/Ztemp/Temp2/*/Fits_data/*_data.fits*`;
#@f_list =  split(/\s+/, $f_line);
#---------TEST TEST END

#
#--- min/max full range data sets
#

$f_lim   =  $f_line;
$f_lim   =~ s/_data\.fits/_min_max\.fits/g;
#---- you may want to activate the next line in future
#$f_lim   =~ s/\.gz//g;

@f_limit =  split(/\s+/, $f_lim);

#
#---- quaterly data sets
#

$q_line  =  $f_line;
$q_line  =~ s/Full_range/Quarterly/g;
$q_line  =~ s/_data\.fits/\.fits/g;
$q_line  =~ s/fits/fits\.gz/g;
@q_list  =  split(/\s+/, $q_line);
#---------TEST TEST
#$q_line  =  $f_line;
#$q_line  =~ s/Script\/Fitting\/Ztemp\/Temp2/www\/mta_envelope_trend\/Quarterly/g;
#$q_line  =~ s/_data\.fits/\.fits/g;
#$q_line  =~ s/fits/fits\.gz/g;
#@q_list  =  split(/\s+/, $q_line);
#---------TEST TEST END

$tot = 0;
foreach $ent (@f_list){
#
#--- find msid name
#
	@atemp = split(/Fits_data\//, $ent);
	@btemp = split(/\_data/, $atemp[1]);
	$msid  = lc($btemp[0]);

print "MSID: $msid\n";

#
#--- find break point information; check msid in a lower case. if we cannot find, use upper case
#
	$in_line = `cat $save_dir/Break_points/*_list |grep $msid`;
	if($in_line !~ /$msid/){
		$umsid = uc($msid);
		$in_line = `cat $save_dir/Break_points/*_list |grep $umsid`;
	}
	chomp $in_line;
	@atemp = split(/\s+/, $in_line);
	$bcnt  = 0;
	foreach (@atemp){
		$bcnt++;
	}
	$bcnt -= 2;		#--- break point(s) entry starts at 3rd on the line

#
#--- trim data at the cutting point ($month_ago) of the main data.
#
	$line = "$ent".'[col1=:'."$month_ago_in_y".']';
	system("dmcopy \"$line\" outfile = out1.fits clobber=yes");
	
	$line = "$f_limit[$tot]".'[col1=:'."$month_ago_in_y".']';
	system("dmcopy \"$line\" outfile = limit1.fits clobber=yes");
	
#
#--- change binning of quarterly data into an hour from a 5 min inteval
#

	$chdata = $q_list[$tot];
	change_to_hr_bin();


#
#--- add a new data into the full range data
#

	if($w_cnt > 0){		#---w_cnt is from change_to_hr_bin(). only when quaterly has data, add it

		system("dmlist out1.fits opt=data > temp");
		open(FH, "temp");
		open(OUT, ">temp_out");
		OUTER:
		while(<FH>){
			chomp $_;
			@atemp = split(/\s+/, $_);
			if($atemp[0] =~ /\w/){
				next OUTER;
			}
			if($atemp[0] =~ /\d/){
				print OUT  "$atemp[1]\t$atemp[2]\t$atemp[3]\t$atemp[4]\n";
			}elsif($atemp[1] =~ /\d/){
				print OUT  "$atemp[2]\t$atemp[3]\t$atemp[4]\t$atemp[5]\n";
			}
		}
		close(OUT);
		close(FH);
		system("dmcopy temp_out out1_mod.fits");
		system("rm temp_out");

		system("dmlist limit1.fits opt=data > temp");
		open(FH, "temp");
		open(OUT, ">temp_out");
		OUTER:
		while(<FH>){
			chomp $_;
			@atemp = split(/\s+/, $_);
			if($atemp[0] =~ /\w/){
				next OUTER;
			}
			if($atemp[0] =~ /\d/){
				print OUT  "$atemp[1]\t$atemp[2]\t$atemp[3]\t$atemp[4]\n";
			}elsif($atemp[1] =~ /\d/){
				print OUT  "$atemp[2]\t$atemp[3]\t$atemp[4]\t$atemp[5]\n";
			}
		}
		close(OUT);
		close(FH);
		system("dmcopy temp_out limit1_mod.fits");
		system("rm temp_out");

		system("dmmerge \"out1_mod.fits,   out2.fits\"    merged.fits  outBlock='' columnList='' clobber=yes ");
		system("dmmerge \"limit1_mod.fits, limit2.fits\" lmerged.fits  outBlock='' columnList='' clobber=yes ");
	
		system("gzip merged.fits");
		system("mv merged.fits.gz $ent");
	
		system("gzip lmerged.fits");
		system("mv lmerged.fits.gz $f_limit[$tot]");
	
		system("rm out1.fits out2.fits out1_mod.fits");
		system("rm limit1.fits limit2.fits limit1_mod.fits");
	}
	$tot++;
}

######################################################################################
### change_to_hr_bin: changing data into one hour binned averages                  ###
######################################################################################

sub change_to_hr_bin{

	$line = "$chdata".'[time='."$month_ago".':]';
	$in_line = `dmlist \"$line\" opt=data`;
	@in_data = split(/\n/, $in_line);

	@time_tmp  = ();
	@data_tmp  = ();
	$plus      = 0;
	$minus     = 0;
	$zero      = 0;
	$total_tmp = 0;
	OUTER:
	foreach $ent (@in_data){
		@atemp = split(/\s+/, $ent);
		if($atemp[1] =~/\d/){
			if($atemp[0] =~ /\d/){
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
			}else{
				if($atemp[2] == 0){
					next OUTER;
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
#--- for the case, we use one hour time interval
#
	@time  = ();
	@data  = ();
	$total = 0;
	if($total_tmp > 0){
		$pos_ratio  = $plus/$total_tmp;
		$neg_ratio  = $minus/$total_tmp;
		$zero_ratio = $zero/$total_tmp;
#		$t_int      = 86400;			#--- one day binning
#		$t_int_mid  = 43200;
		$t_int      = 3600;			#--- one hour binning
		$t_int_mid  = 1800;

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
	
	
					while($end <=  $time_tmp[$i]){
						$begin = $end;
						$end   = $begin + $t_int;
					}
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
			$end   = $begin + $t_int;
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
						$sec       = $begin + $t_int_mid;
						$year_date = sec1998_to_fracyear($sec);
						if($year_date >= $datastart){
							push(@time, $year_date);
							push(@data, $avg);
							$total++;
						}
					}
	
					while($end <=  $time_tmp[$i]){
						$begin = $end;
						$end   = $begin + $t_int;
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
	
		open(OUT, "> out_file");
		for($i = 0; $i < $total; $i++){
			print OUT "$time[$i]\t$data[$i]\n";
		}
		close(OUT);
		system("dmcopy  out_file out2.fits clobber=yes");
		system("rm out_file");
#
#---- now find min and max
#

#
#---- neet to use a trick to use a sub used in a different script
#
		$num_break = 1;
		$break_point[0] = 2000;
		$break_point[1] = $y_date;
	
		boxed_interval_min_max();
	
		open(OUT, "> out_file");
		for($i = 0; $i < $w_cnt; $i++){
			print OUT "$box_time[$i]\t";
			print OUT "$box_min[$i]\t";
			print OUT "$box_max[$i]\t";
			print OUT "$bcnt\n";
		}
		close(OUT);
		system("dmcopy  out_file limit2.fits clobber=yes");
		system("rm out_file");
	}
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
#			       if($rchk > 0.5){
#				       if($t_min > 0){
#					       $t_min = 0;
#				       }
#			       }

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
		if($t_tot > 0){
			$test_avg = $sum/$t_tot;
			$var      = $sum2/$t_tot - $test_avg * $test_avg;
		}
		if($var < 0){
			$var = 2 * abs($var);
		}elsif($var == 0){
			$var = 0.1;
		}
		$test_sig     = sqrt($var);
		$t_min = $test_avg -  3.0 * $test_sig;
		$t_max = $test_avg +  3.0 * $test_sig;
#	       if($rchk > 0.5){
#		       if($t_min > 0){
#			       $t_min = 0;
#		       }
#	       }

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
### boxed_interval_binning: binning the data for a given box size	      ###
##################################################################################

sub boxed_interval_binning{
	my ($i);
	@box_min    = ();
	@box_max    = ();
	@box_time   = ();
	$w_cnt       = 0;

	$start       = $t_begin;
	$end	 = $start + $box_length;
	$wmin	= 1e14;
	$wmax	= -1e14;

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


######################################################################################
### ydate_to_y1998sec: 20009:033:00:00:00 format to 349920000 fromat               ###
######################################################################################

sub ydate_to_y1998sec{
#
#---- this script computes total seconds from 1998:001:00:00:00
#---- to whatever you input in the same format. it is equivalent of
#---- axTime3 2008:001:00:00:00 t d m s
#---- there is no leap sec corrections.
#

        my($date, $atemp, $year, $ydate, $hour, $min, $sec, $yi);
        my($leap, $ysum, $total_day);

        ($date)= @_;

        @atemp = split(/:/, $date);
        $year  = $atemp[0];
        $ydate = $atemp[1];
        $hour  = $atemp[2];
        $min   = $atemp[3];
        $sec   = $atemp[4];

        $leap  = 0;
        $ysum  = 0;
        for($yi = 1998; $yi < $year; $yi++){
                $chk = 4.0 * int(0.25 * $yi);
                if($yi == $chk){
                        $leap++;
                }
                $ysum++;
        }

        $total_day = 365 * $ysum + $leap + $ydate -1;

        $total_sec = 86400 * $total_day + 3600 * $hour + 60 * $min + $sec;

        return($total_sec);
}


######################################################################################
### y1999sec_to_ydate: format from 349920000 to 2009:33:00:00:00 format            ###
######################################################################################

sub y1999sec_to_ydate{
#
#----- this chage the seconds from 1998:001:00:00:00 to (e.g. 349920000)
#----- to 2009:033:00:00:00.
#----- it is equivalent of axTime3 349920000 m s t d
#

        my($date, $in_date, $day_part, $rest, $in_hr, $hour, $min_part);
        my($in_min, $min, $sec_part, $sec, $year, $tot_yday, $chk, $hour);
        my($min, $sec);

        ($date) = @_;

        $in_day   = $date/86400;
        $day_part = int ($in_day);

        $rest     = $in_day - $day_part;
        $in_hr    = 24 * $rest;
        $hour     = int ($in_hr);

        $min_part = $in_hr - $hour;
        $in_min   = 60 * $min_part;
        $min      = int ($in_min);

        $sec_part = $in_min - $min;
        $sec      = int(60 * $sec_part);

        OUTER:
        for($year = 1998; $year < 2100; $year++){
                $tot_yday = 365;
                $chk = 4.0 * int(0.25 * $year);
                if($chk == $year){
                        $tot_yday = 366;
                }
                if($day_part < $tot_yday){
                        last OUTER;
                }
                $day_part -= $tot_yday;
        }

        $day_part++;
        if($day_part < 10){
                $day_part = '00'."$day_part";
        }elsif($day_part < 100){
                $day_part = '0'."$day_part";
        }

        if($hour < 10){
                $hour = '0'."$hour";
        }

        if($min  < 10){
                $min  = '0'."$min";
        }

        if($sec  < 10){
                $sec  = '0'."$sec";
        }

        $time = "$year:$day_part:$hour:$min:$sec";

        return($time);
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


