WARPSHELL_BASE=xilinx_u55n_xdma_gen3x8

edit_bd:
	mkdir -p ./build/edit_$(WARPSHELL_BASE)/
	cd ./build/edit_$(WARPSHELL_BASE)/; \
	vivado -mode batch -source ../../srcs/bd/$(WARPSHELL_BASE)/edit.tcl -tclargs user

synth:
	mkdir -p ./build/$(WARPSHELL_BASE)/
	cd ./build/$(WARPSHELL_BASE)/; \
	vivado -mode batch -source ../../srcs/bd/$(WARPSHELL_BASE)/synth.tcl

impl:
	cd ./build/$(WARPSHELL_BASE)/; \
	vivado -mode batch -source ../../srcs/bd/$(WARPSHELL_BASE)/impl.tcl; \
	mv user.bin user.bin.tmp; \
	xxd -e -g4 user.bin.tmp | xxd -r > user.bin; \
	rm user.bin.tmp

clean:
	rm -rf ./build
