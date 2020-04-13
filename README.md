This forwards udp ports over serial port while preserving packets
This is useful to send wireguard or socat tun tunnel over serial port


server:
```
sudo ./udp2tun.sh
python3 udp2serial.py  /dev/ttyAMA0 --connect-to 127.0.0.1 --src-port=6666 --mtu 9000
```

client:
```
python3 udp2serial.py  /dev/ttyAMA0  --mtu 9000
sudo ./tun2udp.sh
sudo ping 192.168.255.`
```

