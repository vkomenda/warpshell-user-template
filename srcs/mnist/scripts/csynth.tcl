set name [lindex $argv 2]
set freq [lindex $argv 3]

open_project ${name} -reset

add_files ../hls/DataPack.h
add_files ../hls/MLP.h
add_files ../hls/mnist.h
add_files ../hls/MLP.cpp -cflags "-I."
add_files -tb ../hls/MLP_tb.cpp -cflags "-I."

set_top "${name}"
open_solution "${name}_f${freq}" -flow_target vivado -reset
set_part {xcu55n-fsvh2892-2l-e}
create_clock -period ${freq}MHz -name default

config_compile -pragma_strict_mode
config_rtl -reset control

#csim_design
csynth_design
# Cosimulation is very slow for large designs.
#cosim_design

close_solution
close_project
exit
