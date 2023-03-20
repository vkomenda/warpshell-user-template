set script_path [file dirname [file normalize [info script]]]
set project_path [file normalize ${script_path}/../../../]

create_project -in_memory -part xcu55n-fsvh2892-2L-e
set_property source_mgmt_mode All [current_project]

set_property IP_REPO_PATHS ${project_path}/ [current_fileset]
update_ip_catalog -rebuild

# -- [READ FILES] -------------------------------------------------------------
file mkdir ./user/
file copy -force ${script_path}/user.bd ./user/user.bd
read_bd ./user/user.bd
# -----------------------------------------------------------------------------

# -- [INCLUDE VERILOG] --------------------------------------------------------
# read_verilog [glob ${project_path}/srcs/my_module/hdl/*.v]
# -----------------------------------------------------------------------------

# -- [GENERATE BDS] -----------------------------------------------------------
generate_target all [get_files user.bd]
# -----------------------------------------------------------------------------

# -- [COMPILE] ----------------------------------------------------------------
synth_design -top user -mode out_of_context
write_checkpoint -force ./post_synth.dcp
# -----------------------------------------------------------------------------
