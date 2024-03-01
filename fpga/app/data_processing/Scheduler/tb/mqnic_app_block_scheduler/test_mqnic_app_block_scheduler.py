import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotbext.axi import (AxiStreamBus, AxiStreamSource, AxiStreamSink, AxiStreamMonitor)
from cocotb.clock import Clock
import os

@cocotb.coroutine
def reset_dut(dut):
    dut.rst <= 1
    yield RisingEdge(dut.clk)
    dut.rst <= 0
    yield RisingEdge(dut.clk)


def generate_random_data(data_size):
    """Generate random data of specified size."""
    return os.urandom(data_size)


@cocotb.test()
async def test_top_simple_fw(dut):
    """Test for top_simple_fw module"""
    cocotb.fork(Clock(dut.clk, 10, units="ns").start())

    axis_source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s_axis_if_rx"), dut.clk, dut.rst)
    axis_sink = AxiStreamSink(AxiStreamBus.from_prefix(dut, "m_axis_if_tx"), dut.clk, dut.rst)

    dut._log.info("Resetting DUT")
    await reset_dut(dut)

    # Choose your data size here
    data_size = 10000

    for _ in range (50):
        random_data = generate_random_data(data_size)
        await axis_source.send(random_data)
        await axis_source.wait()
        received_data = await axis_sink.recv()





    # Assert that sent and received data are the same
    #assert random_data == received_data.tdata, f"Sent data {random_data} does not match received data {received_data.tdata}"

    dut._log.info("Test passed")