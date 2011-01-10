#!/usr/bin/perl 

#########################################################################################################################
#															#
#	repair_full_range.perl: repair damaged full range data file, and fill up the lost data				#
#															#
#		author: tisobe (tisobe@cfa.harvard.edu)									#
#															#
#		last update: Jan 10, 2011										#
#															#
#########################################################################################################################


#
#--- before run this, set the environment as it uses dataseeker to extract data and run this on rhodes
#
#	rm -rf param
#	mkdir param
#	source /home/mta/bin/reset_param
#	setenv PFILES "${PDIRS}"
#	set path = (/home/ascds/DS.release/bin/  $path)
#	set path = (/home/ascds/DS.release/otsbin/  $path)
#

#
#--- these files do not have data (zero), and skip them
#

@null_ent_list = ('1den0avo_data', '1dep1avo_data', '1dp28avo_data', '1dahhbvo_data', 'deahk31_data');


#
#---- find today's year date
#

($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

$this_year    = $uyear + 1900;
$ydate        = $uyday + 1;

#
#---- check whether data were accidentally deleted or not by setting the checking date 200 days ago
#

$lyear 	      = $this_year;
$ldate        = $ydate - 200;

if($ldate < 1){
	$lyear--;
	$chk = 4.0 * int(0.25 * $lyear);
	if($lyear == $chk){
		$base = 366;
	}else{
		$base = 365;
	}
	$ldate = $base + $ldate;

	$fdate = $ldate/$base;
}else{
	$chk = 4.0 * int(0.25 * $lyear);
	if($lyear == $chk){
		$base = 366;
	}else{
		$base = 365;
	}
	$fdate = $ldate/$base;
}

$date_chk = $lyear + $fdate;

#
#--- setting the end date (today) in ydate
#

$end_yd   = "$this_year:$ydate:00:00:00";
$end      = ydate_to_y1998sec($end_yd);

#
#--- create the list of all full range data
#

$input =` ls  /data/mta_www/mta_envelope_trend/Full_range/*/Fits_data/*_data.fits`;
@list  = split(/\s+/, $input);

#
#--- setting for recording problem files
#

$problem_file = 'problem_files_'."$this_year".'_'."$ydate";
$cnt_problem  = 0;

open(ZOUT, "> $problem_file");

OUTER:
foreach $ent (@list){
	foreach $comp (@null_ent_list){
		if($ent =~ /$comp/){
			next OUTER;
		}
	}
#
#--- find starting date of the file
#
	$line = "$ent".'[cols col1]';
	system("dmstat \"$line\" > zout");
	open(FH, "./zout");
	OUTER:
	while(<FH>){
		chomp $_;
#
#--- look for starting time (min of the col)
#

		if($_ =~ /min/){
			@atemp = split(/\s+/, $_);
#
#--- if the time found is larger than the checking date, it means the past data is lost
#

			if($atemp[2] > $date_chk){
#
#--- keep the record of the deleted data
#

				print ZOUT "$ent\n";
print "$ent\n";

#
#--- find a saved file name
#
				@btemp = split(/Full_range\//, $ent);
				$saved = '/data/mta_www/mta_envelope_trend/Full_range_save/'."$btemp[1]";
				$line  = "$saved".'[cols col1]';
#
#--- find the last entry time of the save file
#
				system("dmstat \"$line\" > zout2");
				open(IN, "./zout2");
				OUTER2:
				while(<IN>){
					chomp $_;
					if($_ =~ /max/){
						@ctemp = split(/\s+/, $_);
						@dtemp = split(/\./,  $ctemp[2]);
				
						$chk   = 4.0 * int(0.25 * $dtemp[0]);
						if($chk == $dtemp[0]){
							$base = 366;
						}else{
							$base = 366;
						}
						$frac = $ctemp[2] - $dtemp[0];
						$ydate = int($base * $frac);

						$start_yd = "$dtemp[0]:$ydate".':00:00:00';
						$start    = ydate_to_y1998sec($start_yd);
					}
				}
				close(IN);
				system("rm zout2");
#
#--- extract msid, and set in a correct format for dataseker
#
				@btemp = split(/Fits_data\//, $ent);
				@ctemp = split(/_/, $btemp[1]);
				$msid  = lc($ctemp[0]);
				if($msid =~ /3FAMTRAT/i || $msid =~ /3FAPSAT/i || $msid =~ /3FASEAAT/i
						|| $msid =~ /3SMOTOC/i || $msid =~ /3SMOTSTL/i || $msid =~ /3TRMTRAT/i){
						$col = "$msid_list[$i]".'_AVG';
				 }elsif($msid =~ /^DEA/i){
						$col    = "$msid_list[$i]".'_avg';
				}else{
						$col    = '_'."$msid".'_avg';
				}

#
#--- here comes dataseekr
#
				$line = "columns=$col timestart=$start_yd timestop=$end_yd";


				system("cp /data/mta/Script/Fitting/Trend_script//Save_data/test .");
				system("dataseeker.pl infile=test outfile=extracted.fits search_crit=\"$line\" ");


#
#--- change the time format to hr/day from 5 min interval
#

				change_to_hr_bin();

				system("rm extracted.fits");
#
#--- merge the past data and the date just extracted
#

				system("dmcopy $saved \"output.txt[opt kernel=text/simple]\" clobber=yes ");
				system("dmcopy output.txt output.fits clobber=yes");
				system("dmmerge \"output.fits,  out2.fits\" merged.fits outBlock='' columnList='' clobber=yes ");
				system("rm output.txt output.fits");
#
#--- copy the merged data to the database
#
				system("mv merged.fits $ent");

			}
			next OUTER;
		}
	}
	system("rm zout");
	close(FH);
}
close(ZOUT);

#
#--- update save files
#

system("rm -rf /data/mta_www/mta_envelope_trend/Full_range_save");
system("cp -r  /data/mta_www/mta_envelope_trend/Full_range  /data/mta_www/mta_envelope_trend/Full_range_save");


$problem_file = 'problem_files_'."$this_year".'_'."$ydate";
$cnt_problem  = 0;

#
#-- if there are problems, send out email to notify.
#

if($cnt_prblem == 0){
	system("rm $problem_file");
}else{
	open(ZOUT, ">temp_mail");
	print ZOUT  "The following files had problems, and modified\n\n";
	system("cat $problem_file  |mailx -s\"Subject: Problem found in Envelope Trending\n\" -risobe\@head.cfa.harvard.edu isobe\@head.cfa.harvard.edu");
	system("mv $problem_file /data/mta/Script/Fitting/Exc/Full_range/Problem_lists/.");
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


######################################################################################
### change_to_hr_bin: changing data into one hour binned averages                  ###
######################################################################################

sub change_to_hr_bin{

        $line = "extracted.fits".'[time='."$start".':]';
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
#               $t_int      = 86400;                    #--- one day binning
#               $t_int_mid  = 43200;
                $t_int      = 3600;                     #--- one hour binning
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


