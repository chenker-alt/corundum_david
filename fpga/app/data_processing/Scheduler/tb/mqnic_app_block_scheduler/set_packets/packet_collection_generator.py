from scapy.all import Ether, wrpcap
import random

def generate_mac_sequence(total_packets, port_rx):
    """Génère une séquence d'adresses MAC source en incorporant le numéro de port RX."""
    port_hex = f"{port_rx:02x}"
    return [f"{port_hex}:00:00:00:{i//256:02x}:{i%256:02x}" for i in range(total_packets)]

def create_packet(dest_mac, src_mac):
    """Crée un paquet Ethernet avec une charge utile aléatoire."""
    payload_size = random.randint(60, 1500) 
    payload = bytes(random.getrandbits(8) for _ in range(payload_size))
    return Ether(dst=dest_mac, src=src_mac) / payload

def generate_pcap_file(filename, total_packets=100, distribution=None, port_rx=1):
    """Génère un fichier PCAP contenant des paquets avec des destinations et tailles aléatoires."""
    if distribution is None:
        distribution = {
            "55:55:55:55:55:03": 25,  # High fifo priority
            "55:55:55:55:55:02": 25,  # Medium fifo priority
            "55:55:55:55:55:01": 25,  # Low fifo priority
            "random": 25  # Drop packets
        }

    dest_macs = []
    for dest_mac, count in distribution.items():
        for _ in range(count):
            if dest_mac == "random":
                dest_mac = ':'.join(f"{random.randint(0, 255):02x}" for _ in range(6))
            dest_macs.append(dest_mac)

    random.shuffle(dest_macs)

    src_macs = generate_mac_sequence(total_packets, port_rx)
    packets = [create_packet(dest_macs[i], src_macs[i]) for i in range(total_packets)]

    wrpcap(filename, packets)
    print(f"{total_packets} packets have been written to {filename}")

ports_rx = [1, 2, 3]
for port_rx in ports_rx:
    generate_pcap_file(f"input_packets_port{port_rx}.pcap", port_rx=port_rx)
