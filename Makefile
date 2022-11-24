PROJECT_DIR=$(PWD)
WARPSHELL=xilinx_u55n_xdma_gen3x8_v0
PERSONA=base

edit_bd:
	rm -rf ./build/edit/$(WARPSHELL)/$(PERSONA)/
	mkdir -p ./build/edit/$(WARPSHELL)/$(PERSONA)/
	cd ./build/edit/$(WARPSHELL)/$(PERSONA)/; \
	vivado -mode batch -source $(PROJECT_DIR)/personas/$(WARPSHELL)/$(PERSONA)/edit.tcl -tclargs user

synth:
	mkdir -p ./build/$(WARPSHELL)/$(PERSONA)/
	cd ./build/$(WARPSHELL)/$(PERSONA)/; \
	vivado -mode batch -source $(PROJECT_DIR)/personas/$(WARPSHELL)/$(PERSONA)/synth.tcl

build/$(WARPSHELL)/abstract_shell.dcp:
	mkdir -p ./build/$(WARPSHELL)/
	cd ./build/$(WARPSHELL)/; \
	wget --output-document=abstract_shell.dcp https://github.com/Quarky93/warpshell/releases/download/warpshell_v0/abstract_warpshell_xilinx_u55n_xdma_gen3x8.dcp

impl: build/$(WARPSHELL)/abstract_shell.dcp
	cp ./build/$(WARPSHELL)/abstract_shell.dcp ./build/$(WARPSHELL)/$(PERSONA)/
	cd ./build/$(WARPSHELL)/$(PERSONA)/; \
	vivado -mode batch -source $(PROJECT_DIR)/personas/$(WARPSHELL)/$(PERSONA)/impl.tcl; \
	mv user.bin user.bin.tmp; \
	xxd -e -g4 user.bin.tmp | xxd -r > user.bin; \
	rm user.bin.tmp

clean:
	rm -rf ./build
