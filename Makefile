############################
# Change the task name!
############################
TASK = FIND_LIMIT_ENVELOPE 

include /data/mta/MTA/include/Makefile.MTA

BIN  = find_limit_envelope.perl find_limit_envelope_control_deriv.perl find_limit_envelope_control_ds.perl find_limit_envelope_control_sun.perl find_limit_envelope_mk_html.perl find_limit_envelope_sun_angle.perl find_limit_violation_table.perl find_limit_envelope_control_plot_only.perl add_data_to_full_range.perl create_lim_data.perl find_limit_envelope_long_term_plot_control_ds.perl find_limit_plot_long_term.perl create_break_point_table.perl create_break_point_master_html.perl feed_for_limit_comp.perl recompute_limit_data_control.perl recompute_limit_data.perl find_limit_plot_long_term_recomp_fit.perl find_limit_envelope_control_plot_only_new.perl full_range_recomp_master.perl repair_full_range.perl update_break_point_table.perl repair_full_range_gap.perl

DOC  = README

install:
ifdef BIN
	rsync --times --cvs-exclude $(BIN) $(INSTALL_BIN)/
endif
ifdef DATA
	mkdir -p $(INSTALL_DATA)
	rsync --times --cvs-exclude $(DATA) $(INSTALL_DATA)/
endif
ifdef DOC
	mkdir -p $(INSTALL_DOC)
	rsync --times --cvs-exclude $(DOC) $(INSTALL_DOC)/
endif
ifdef IDL_LIB
	mkdir -p $(INSTALL_IDL_LIB)
	rsync --times --cvs-exclude $(IDL_LIB) $(INSTALL_IDL_LIB)/
endif
ifdef CGI_BIN
	mkdir -p $(INSTALL_CGI_BIN)
	rsync --times --cvs-exclude $(CGI_BIN) $(INSTALL_CGI_BIN)/
endif
ifdef PERLLIB
	mkdir -p $(INSTALL_PERLLIB)
	rsync --times --cvs-exclude $(PERLLIB) $(INSTALL_PERLLIB)/
endif
ifdef WWW
	mkdir -p $(INSTALL_WWW)
	rsync --times --cvs-exclude $(WWW) $(INSTALL_WWW)/
endif
