import cocotb_test.simulator
import cocotb
from cocotb.clock import Clock
import logging
import os
import pytest

class TB(object):
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.clk, 8, units="ns").start())

        # AXI interfaces
        self.axi_master = AxiMaster(AxiBus.from_prefix(dut, "s_axi"), dut.clk, dut.rst)

@pytest.mark.parametrize()
def test_mm2s(request, mm_data_width):
    dut = "mm2s"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(rtl_dir, f'{dut}.v'),
    ]

    parameters = {}

    parameters['MM_DATA_WIDTH'] = data_width
    extra_env = {f'PARAM_{k}': str(v) for k, v in parameters.items()}

    sim_build = os.path.join(tests_dir, 'sim_build', request.node.name.replace('[', '-').replace(']', ''))

    cocotb_test.simulator.run(
        python_search = [tests_dir],
        verilog_sources = verilog_sources,
        toplevel = toplevel,
        module = module,
        parameters = parameters,
        sim_build = sim_build,
        extra_env = extra_env,
    )
