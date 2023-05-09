cmake_minimum_required(VERSION 3.14)
project (mnist)

set(CMAKE_CXX_STANDARD 14)

if (WIN32)
  set(VITIS_INCLUDE_PATH C:/Xilinx/Vitis_HLS/2022.2/include)
endif (WIN32)

if (UNIX)
  set(VITIS_INCLUDE_PATH ~/Xilinx/Vitis_HLS/2022.2/include)
endif (UNIX)

if (APPLE)
  set(VITIS_INCLUDE_PATH ~/Workspace/vitis_hls/include)
endif (APPLE)

include_directories(include ${VITIS_INCLUDE_PATH})

function(add_vitis_hls_target name freq)
  add_custom_command(OUTPUT ${name}/${name}_f${freq}/syn/report/csynth.rpt COMMAND vitis_hls -f ../scripts/csynth.tcl ${name} ${freq})
  add_custom_command(OUTPUT ${name}/${name}_f${freq}/impl/export.zip COMMAND vitis_hls -f ../scripts/export.tcl ${name} ${freq} DEPENDS ${name}/${name}_f${freq}/syn/report/csynth.rpt)
  add_custom_target(csynth_${name}_f${freq} DEPENDS ${name}/${name}_f${freq}/syn/report/csynth.rpt)
  add_custom_target(export_${name}_f${freq} DEPENDS ${name}/${name}_f${freq}/impl/export.zip)
endfunction()

add_vitis_hls_target(mnist 500)
add_vitis_hls_target(mnist 250)
