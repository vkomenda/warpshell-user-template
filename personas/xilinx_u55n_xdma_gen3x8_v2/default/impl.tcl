set script_path [file dirname [file normalize [info script]]]
set project_path [file normalize ${script_path}/../../../]

create_project -in_memory -part xcu55n-fsvh2892-2L-e
set_property source_mgmt_mode All [current_project]

open_checkpoint ./abstract_shell.dcp
read_checkpoint -cell user_partition ./post_synth.dcp

opt_design
place_design
phys_opt_design
write_checkpoint -force post_place.dcp
route_design
phys_opt_design
write_checkpoint -force post_route.dcp
report_utilization -file post_route_util.txt
report_timing_summary -file post_route_timing.txt
write_debug_probes -force debug.ltx
write_bitstream -cell user_partition -bin_file -force user.bit
