set freq [lindex $argv 2]
set export_ip [lindex $argv 3]

open_project axi_sum_example -reset

add_files ../vhls/axi_sum_example.cpp

set_top axi_sum_example
open_solution "axi_sum_example_f${freq}" -flow_target vivado -reset
set_part xcu55n-fsvh2892-2l-e
create_clock -period ${freq}MHz -name default

config_compile -pragma_strict_mode
config_rtl -reset control

csynth_design

if {${export_ip} == "true"} {
    export_design -rtl verilog -format ip_catalog -output ../ip/
}

close_solution
close_project
exit
