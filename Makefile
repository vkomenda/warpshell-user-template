PROJECT_DIR=$(PWD)
WARPSHELL=xilinx_u55n_xdma_gen3x8_v2
PERSONA=mnist

edit_bd:
	rm -rf ./build/edit/$(WARPSHELL)/$(PERSONA)/
	mkdir -p ./build/edit/$(WARPSHELL)/$(PERSONA)/
	cd ./build/edit/$(WARPSHELL)/$(PERSONA)/; \
	vivado -mode batch -source $(PROJECT_DIR)/personas/$(WARPSHELL)/$(PERSONA)/edit.tcl -tclargs user

synth:
	rm -rf ./build/$(WARPSHELL)/$(PERSONA)/
	mkdir -p ./build/$(WARPSHELL)/$(PERSONA)/
	cd ./build/$(WARPSHELL)/$(PERSONA)/; \
	vivado -mode batch -source $(PROJECT_DIR)/personas/$(WARPSHELL)/$(PERSONA)/synth.tcl

build/xilinx_u55n_xdma_gen3x8_v2/abstract_shell.dcp:
	mkdir -p ./build/xilinx_u55n_xdma_gen3x8_v2/
	cd ./build/xilinx_u55n_xdma_gen3x8_v2/; \
	wget --output-document=abstract_shell.dcp https://github.com/Quarky93/warpshell/releases/download/warpshell-beta-v2/abstract_warpshell_xilinx_u55n_xdma_gen3x8.dcp

impl: build/$(WARPSHELL)/abstract_shell.dcp
	mkdir -p ./build/$(WARPSHELL)/$(PERSONA)
	cp ./build/$(WARPSHELL)/abstract_shell.dcp ./build/$(WARPSHELL)/$(PERSONA)/
	cd ./build/$(WARPSHELL)/$(PERSONA)/; \
	vivado -mode batch -source $(PROJECT_DIR)/personas/$(WARPSHELL)/$(PERSONA)/impl.tcl; \
	mv user.bin user.bin.tmp; \
	xxd -e -g4 user.bin.tmp | xxd -r > user.bin; \
	rm user.bin.tmp

clean:
	rm -rf ./build
