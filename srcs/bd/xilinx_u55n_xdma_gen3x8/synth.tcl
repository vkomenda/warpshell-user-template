set script_path [file dirname [file normalize [info script]]]

create_project -in_memory -part xcu55n-fsvh2892-2L-e
set_property source_mgmt_mode All [current_project]

# -- [READ FILES] -------------------------------------------------------------
source "${script_path}/user.tcl"
# -----------------------------------------------------------------------------

# -- [INCLUDE VERILOG] --------------------------------------------------------
# read_verilog [glob /verilog/directory/*.v]
# -----------------------------------------------------------------------------

# -- [CONFIGURE USER BD] ------------------------------------------------------
cr_bd_user {}
generate_target all [get_files user.bd]
# -----------------------------------------------------------------------------

# -- [COMPILE] ----------------------------------------------------------------
synth_design -top user -mode out_of_context
write_checkpoint -force ./post_synth.dcp
# -----------------------------------------------------------------------------
