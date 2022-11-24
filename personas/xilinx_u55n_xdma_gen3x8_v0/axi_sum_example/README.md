# Default Persona
COMPATIBILITY:
```
xilinx_u55n_xdma_gen3x8_v0
```

User Partition Address Space
```toml
[ctrl]

[ctrl.hbm_apb_0]
baseaddr = 0x0000_0000
range = "4MiB"

[ctrl.hbm_apb_1]
baseaddr = 0x0040_0000
range = "4MiB"

[dma]

[dma.hbm]
baseaddr = 0x0000_0000_0000_0000
range = "8GiB"
```
