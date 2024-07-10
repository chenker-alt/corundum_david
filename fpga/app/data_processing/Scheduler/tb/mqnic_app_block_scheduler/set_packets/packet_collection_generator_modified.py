from scapy.all import *
import random

def generate_mac_sequence(total_packets, port_rx):
    """Génère une séquence d'adresses MAC source en incorporant le numéro de port RX."""
    port_hex = f"{port_rx:02x}"
    return [f"{port_hex}:00:00:00:{i//256:02x}:{i%256:02x}" for i in range(total_packets)]

def create_packet(dest_mac, src_mac):
    """Crée un paquet Ethernet avec une charge utile aléatoire."""
    payload_size = random.randint(200, 500) 
    payload = bytes(random.getrandbits(8) for _ in range(payload_size))
    return Ether(dst=dest_mac, src=src_mac) / IP(dst='192.10.12.56') / TCP() / payload

def generate_pcap_file(filename, total_packets, distribution, port_rx):
    """Génère un fichier PCAP contenant des paquets avec des destinations et tailles aléatoires."""
    dest_macs = []
    low_priority_macs = []
    mid_priority_macs = []
    high_priority_macs = []
    for dest_mac, count in distribution.items():
        for _ in range(count):
            if dest_mac == "random":
                dest_mac = ':'.join(f"{random.randint(0, 255):02x}" for _ in range(6))
            if dest_mac == "55:55:55:55:55:01":
                low_priority_macs.append(dest_mac)
            elif dest_mac == "55:55:55:55:55:02":
            	mid_priority_macs.append(dest_mac)
            else:
                high_priority_macs.append(dest_mac)
    if port_rx == 1:
    	dest_macs = mid_priority_macs + low_priority_macs + high_priority_macs
    elif port_rx == 2:
    	dest_macs = mid_priority_macs + low_priority_macs + high_priority_macs
    else:
    	dest_macs = low_priority_macs + high_priority_macs + mid_priority_macs
    
    random.shuffle(dest_macs)
    src_macs = generate_mac_sequence(total_packets, port_rx)
    packets = [create_packet(dest_macs[i], src_macs[i]) for i in range(total_packets)]
    wrpcap(filename, packets)
    print(f"{total_packets} packets have been written to {filename}")
    
    
ports_rx = [1, 2, 3]
distributions = [
    {	"55:55:55:55:55:02": 20,  # Medium fifo priority
        "55:55:55:55:55:01": 50,  # Low fifo priority
        "55:55:55:55:55:03": 15,  # High fifo priority
	"random": 0  # Drop packets
    },
    {   
    	"55:55:55:55:55:02": 30,  # Medium fifo priority
        "55:55:55:55:55:01": 10  # Low fifo priority
       
        
    },
    {
    	"55:55:55:55:55:01": 20  # Low fifo priority
     
    }
]
for port_rx, distribution in zip(ports_rx, distributions):
    total_packets = sum(distribution.values())
    generate_pcap_file(f"input_packets_port{port_rx}.pcap", total_packets, distribution, port_rx)
