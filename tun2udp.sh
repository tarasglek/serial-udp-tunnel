import socket
import threading
import serial
import argparse
import time

PREFIX = "PACKET".encode("utf-8")

def main(args):

    sock = socket.socket(socket.AF_INET, # Internet
                        socket.SOCK_DGRAM) # UDP
            
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(("0.0.0.0", args.src_port))

    serial_port = serial.Serial(args.SERIALPORT, args.baud, timeout=0)
    addr = None
    if args.connect_to:
        addr = (args.connect_to, args.dst_port)

    shared_info = {'addr': addr,
    'serial_port': serial_port
    }


    def udp_recv_loop(info):
        print("udp", flush=True)
        
        while True:
            packet, connection_addr = sock.recvfrom(args.mtu)
            if info['addr'] == None:
                print("Setting addr to " + str(connection_addr))
                info['addr'] = connection_addr
                info['sock'] = sock
            print("received & wrote message:", len(packet))
            info['serial_port'].write(PREFIX + len(packet).to_bytes(4, "little") + packet)
            info['serial_port'].flush()
            # sock.sendto("debug".encode("utf-8"), info['addr'])#

    def serial_recv_loop(info):
        # buffer into data until we have sufficient stuff
        data = bytes()
        phase = 0 # 0 = header, 1 = data
        data_left = len(PREFIX) + 4
        # this needs a timeout to reset state machine
        while True:
            buf = serial_port.read(data_left)
            data_left = data_left - len(buf)
            data = data + buf
            if data_left > 0:
                continue
            print("data", len(data))
            if phase == 0:
                packet_len = int.from_bytes(data[-4:], byteorder='little')
                prefix = data[0:len(PREFIX)]
                print('packet_len:', packet_len, prefix)
                if (prefix != PREFIX):
                    raise Exception("Invalid prefix:" + prefix)
                phase = 1
                data_left = packet_len
                data = bytes()
                continue
            elif phase == 1:
                print('fwd udp', len(data), info['addr'])
                if (not info['addr']):
                    print("Addr is null, can't fwd serial data")
                    continue
                sock.sendto(data, info['addr'])
                phase = 0
                data = bytes()
                data_left = len(PREFIX) + 4

    serial_thread = threading.Thread(target=serial_recv_loop, args=(shared_info,))
    serial_thread.start()
    udp_thread = threading.Thread(target=udp_recv_loop, args=(shared_info,))
    udp_thread.start()
    while True:
        time.sleep(1)

if __name__ =="__main__":
    parser = argparse.ArgumentParser(
        description='Simple Serial to UDP redirector.',
        epilog="""\
    NOTE: no security measures are implemented. Anyone can remotely connect
    to this service over the network.

    Only one connection at once is supported. When the connection is terminated
    it waits for the next connect.
    """)

    parser.add_argument(
        'SERIALPORT',
        help="serial port name")
    parser.add_argument(
        "--baud",
        help="baud rate, default: 115200",
        default=115200)

    parser.add_argument(
        "--dst-port",
        type=int,
        help="port, default: 5555",
        default=5555)

    parser.add_argument(
        "--src-port",
        type=int,
        help="port, default: 5555",
        default=5555)
    parser.add_argument(
        "--mtu",
        type=int,
        help="port, default: 1500",
        default=1500)

    parser.add_argument(
        "--connect-to",
        type=str,
        help="Connect to udp host",
        default=None)
    
    args = parser.parse_args()
    main(args)