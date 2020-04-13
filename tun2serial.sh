set -x -e
# https://unix.stackexchange.com/questions/453974/create-a-udp-to-serial-bridge-with-socat
# https://superuser.com/questions/53103/udp-traffic-through-ssh-tunnel
socat -v \
	TUN:192.168.255.2/24,up \
        udp:127.0.0.1:5555 
#        udp:192.168.1.75:5555
