#!/usr/bin/env python3
# """

# Copyright (c) 2021 Alex Forencich

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# """

import itertools
import logging
import os
import random
import cocotb
import difflib
import subprocess
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Combine, Event
from cocotbext.axi import AxiStreamBus, AxiStreamSource, AxiStreamSink, AxiStreamMonitor
from scapy.all import *
from collections import Counter

import matplotlib.pyplot as plt

class TB(object):
    def __init__(self, dut):
        self.dut = dut
        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        # Start the clock
        cocotb.start_soon(Clock(dut.clk, 5, units="ns").start()) #200MHz

        # Setup AXI Stream sources and sinks
        down_s_count = 3
        down_m_count = 1
        up_s_count = 1
        up_m_count = 3
        
        self.source_down = [AxiStreamSource(AxiStreamBus.from_prefix(dut, f"s_axis_port{k+1+up_s_count}"), dut.clk, dut.rst) for k in range(down_s_count)]
        self.sink_down = [AxiStreamSink(AxiStreamBus.from_prefix(dut, f"m_axis_port{k+1}"), dut.clk, dut.rst) for k in range(down_m_count)]

        self.source_up = [AxiStreamSource(AxiStreamBus.from_prefix(dut, f"s_axis_port{k+1}"), dut.clk, dut.rst) for k in range(up_s_count)]
        self.sink_up = [AxiStreamSink(AxiStreamBus.from_prefix(dut, f"m_axis_port{k+1+down_m_count}"), dut.clk, dut.rst) for k in range(up_m_count)]

    def set_idle_generator(self, generator=None):
        if generator:
            for source in self.source_down:
                source.set_pause_generator(generator())

    def set_backpressure_generator(self, generator=None):
        if generator:
            for sink in self.sink_down:
                sink.set_pause_generator(generator())

    async def reset(self):
        """Asynchronously reset the DUT."""
        self.dut.rst.setimmediatevalue(0)
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst.value = 1
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst.value = 0
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)

# Utility functions

global is_first_call
is_first_call = True

def log_signal_change(signal_name, value, time):
    """Log signal changes into a VCD file."""
    global is_first_call
    mode = 'w' if is_first_call else 'a'
    with open("signals.vcd", mode) as f:
        f.write(f"#{time}\n")
        f.write(f"{value} {signal_name}\n")
    is_first_call = False

def generate_graphs():
    """Generate and save a graph of FIFO depths."""
    signal_names = ["status_depth_fifo0", "status_depth_fifo1", "status_depth_fifo2"]
    
    plt.figure(figsize=(10, 6))

    for signal_name in signal_names:
        times, values = [], []
        current_time = None
        with open("signals.vcd", "r") as f:
            for line in f:
                if line.startswith("#"):
                    current_time = float(line[1:])
                elif line.strip().endswith(signal_name) and current_time is not None:
                    values.append(int(line.split()[0]))
                    times.append(current_time)
                    current_time = None
        
        plt.plot(times, values, marker='o', linestyle='-', label=signal_name)

    plt.title("FIFO Fill Level Over Time")
    plt.xlabel("Time (ns)")
    plt.ylabel("FIFO Fill Level (bytes)")
    plt.legend()
    plt.grid(True)
    plt.savefig("status_depth_evolution.png", dpi=300)

async def monitor_signal(signal, signal_name, clk):
    """Coroutine to monitor a signal and log its changes."""
    while True:
        await RisingEdge(clk)
        value = signal.value.integer
        time = cocotb.utils.get_sim_time(units='ns')
        log_signal_change(signal_name, value, time)

# Data generation functions

def generate_random_data(data_size):
    """Generate random data of specified size."""
    return os.urandom(data_size)

def create_eth_ipv4_packet(src_mac, dst_mac, src_ip="192.168.1.1", dst_ip="192.168.1.2", payload=""):
    """Create a raw Ethernet and IPv4 packet using Scapy."""
    packet = Ether(src=src_mac, dst=dst_mac)/IP(src=src_ip, dst=dst_ip)/payload
    return raw(packet)

async def send_packets(tb, port, num_sequences, priority_sequence, mac_counters):
    """Send packets on a specified port with defined priorities."""
    for sequence in range(num_sequences):
        payload_size = random.randint(64, 1500)
        payload_data = generate_random_data(payload_size)

        src_mac = f"33:33:33:33:33:33"[-17:]
        mac_counters[port] += 1

        dst_mac, priority_label = priority_sequence[sequence % len(priority_sequence)]
        eth_ipv_packet = create_eth_ipv4_packet(src_mac, dst_mac, payload=payload_data)
        await tb.source[port].send(eth_ipv_packet)
        print(f"Port {port+1}: Sent {priority_label} priority packet with src_mac={src_mac} and payload size {payload_size} bytes")

def create_packet_set(num_high_priority_packet, num_medium_priority_packet, num_low_priority_packet, num_drop_packet):
    packet_set = []

    for _ in range(num_high_priority_packet):
        packet = Ether(src="33:33:33:33:33:33", dst="55:55:55:55:55:03") / os.urandom(random.randint(64, 1500))
        packet_set.append(raw(packet))

    for _ in range(num_medium_priority_packet):
        packet = Ether(src="33:33:33:33:33:33", dst="55:55:55:55:55:02") / os.urandom(random.randint(64, 1500))
        packet_set.append(raw(packet))

    for _ in range(num_low_priority_packet):
        packet = Ether(src="33:33:33:33:33:33", dst="55:55:55:55:55:01") / os.urandom(random.randint(64, 1500))
        packet_set.append(raw(packet))

    for _ in range(num_drop_packet):
        packet = Ether(src="33:33:33:33:33:33", dst="55:55:55:55:55:55") / os.urandom(random.randint(64, 1500))
        packet_set.append(raw(packet))

    random.shuffle(packet_set)

    return packet_set

def filter_valid_packets(*packet_sets):
    valid_destinations = {"55:55:55:55:55:03", "55:55:55:55:55:02", "55:55:55:55:55:01"}
    valid_packets = []

    # Parcourir chaque ensemble de paquets
    for packet_set in packet_sets:
        for raw_packet in packet_set:
            # Décoder chaque paquet pour accéder aux champs
            packet = Ether(raw_packet)
            # Vérifier si l'adresse de destination est dans les destinations valides
            if packet.dst in valid_destinations:
                valid_packets.append(packet)

    return valid_packets

def extract_pcap_data(file_path, fields):
    """Utilise tshark pour extraire des données d'un fichier pcap."""
    tshark_command = [
        "tshark", "-r", file_path, "-T", "fields"
    ] + [f"-e {field}" for field in fields]
    result = subprocess.run(tshark_command, capture_output=True, text=True)
    return result.stdout

def compare_pcaps(file1, file2, fields):
    """Compare deux fichiers pcap en extrayant certaines données."""
    data1 = extract_pcap_data(file1, fields)
    data2 = extract_pcap_data(file2, fields)

    # Utiliser difflib pour comparer les lignes extraites
    diff = difflib.unified_diff(
        data1.splitlines(), data2.splitlines(),
        fromfile=file1, tofile=file2, lineterm=''
    )
    for line in diff:
        print(line)

def load_and_convert_pcap(filepath):
    """Charge les paquets depuis un fichier .pcap et les convertit en format brut."""
    packets = rdpcap(filepath)  # Lire les paquets depuis le fichier .pcap
    return [raw(packet) for packet in packets]  # Convertir chaque paquet en format brut

# Main cocotb test function

def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])


@cocotb.test()
async def run_test(dut):
    
    tb = TB(dut)
    await tb.reset()
    for _ in range(10):
        await RisingEdge(dut.clk)

    # tb.set_idle_generator(cycle_pause)
    # tb.set_backpressure_generator(cycle_pause)

    # Initialize signal monitoring
    signals_to_monitor = [
        ("status_depth_fifo0", dut.mqnic_app_block_scheduler_inst.top_scheduler_down_inst.SCHED_EN.top_priority_FIFO_inst.fifo0_inst.status_depth),
        ("status_depth_fifo1", dut.mqnic_app_block_scheduler_inst.top_scheduler_down_inst.SCHED_EN.top_priority_FIFO_inst.fifo1_inst.status_depth),
        ("status_depth_fifo2", dut.mqnic_app_block_scheduler_inst.top_scheduler_down_inst.SCHED_EN.top_priority_FIFO_inst.fifo2_inst.status_depth),

    ]
    # Start coroutines for each signal to monitor
    for name, signal in signals_to_monitor:
        cocotb.start_soon(monitor_signal(signal, name, dut.clk))

    RX_down_0_set=create_packet_set(0, 00, 0, 0)
    RX_down_1_set=create_packet_set(0, 00, 00, 0)
    RX_down_2_set=create_packet_set(00, 1, 00, 0)

    down_valid_packets = filter_valid_packets(RX_down_0_set, RX_down_1_set, RX_down_2_set)

    for i in range(len(RX_down_0_set)):
        await tb.source_down[0].send(RX_down_0_set[i])
    for i in range(len(RX_down_1_set)):
        await tb.source_down[1].send(RX_down_1_set[i])
    for i in range(len(RX_down_2_set)):
        await tb.source_down[2].send(RX_down_2_set[i])

    TX_down = [None] * len(down_valid_packets)
    for i in range(len(down_valid_packets)):
        TX_down[i] = await tb.sink_down[0].recv()
        
    # Wait for all packets to be processed
    for _ in range(3 * 40 * 50):
        await RisingEdge(dut.clk)

    scapy_packets = []  # Initialisation de la liste pour les paquets Scapy convertis
    for frame in TX_down:
        if frame.tdata is not None:
            # Assurez-vous que frame.tdata est de type bytes
            frame_bytes = bytes(frame.tdata)  # Conversion de bytearray en bytes si nécessaire
            packet = Ether(frame_bytes)
            scapy_packets.append(packet)
        else:
            # Gérer le cas où tdata est None, si nécessaire
            scapy_packets.append(None)  # Ajouter un None ou gérer autrement

    print(scapy_packets)
    for packet in scapy_packets:
        if packet is not None:
            print(packet.summary())  # Afficher un résumé de chaque paquet Scapy
        else:
            print("No packet received.")

    wrpcap("test.pcap",down_valid_packets)
    wrpcap("test2.pcap",scapy_packets)

    scapy_packets_hashes = [bytes(packet) for packet in scapy_packets]
    down_valid_packets_hashes = [bytes(packet) for packet in down_valid_packets]

    print("#####down_valid_packets######")
    print(len(down_valid_packets))
    print(down_valid_packets[0].show())
    print("#####down_valid_packets######")


    print("#####scapy packet######")
    print(len(scapy_packets))
    print(scapy_packets[0].show())
    print("#####scapy packet######")

    # Utilisation de Counter pour compter les occurrences dans chaque tableau
    assert Counter(scapy_packets_hashes) == Counter(down_valid_packets_hashes), "Les paquets ne correspondent pas"

    # Comparer les fichiers .pcap
    compare_pcaps("test.pcap", "test2.pcap", ["frame.number", "ip.src", "ip.dst", "frame.len"])
    generate_graphs()
