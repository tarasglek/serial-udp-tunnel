set -x -e
# https://unix.stackexchange.com/questions/453974/create-a-udp-to-serial-bridge-with-socat
socat -v \
        udp4-listen:5555,reuseaddr,fork \
	TUN:192.168.255.1/24,up
#	UDP:summit.glek.net:5555
