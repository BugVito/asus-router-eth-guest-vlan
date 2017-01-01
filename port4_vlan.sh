#!/bin/sh
# This script is made for  Asus RT-AC68U (Stock kernel 3.0.0.4.380_4164).  It may be work and/or adapted for other models.
# The intent is to have the ethernet port 4 serve as a guest ethernet port, by using a different vlan with strict rules.
# Any requests to the internal network will be denied, except for DNS requests.
# This allows the usage of the same DHCP server for this new vlan, without having to muck around for the case where the DNS entry points to the router itself.

# Due to the inability to specify when this script runs, it will wait for the internet to be visible, then add the firewall/routing rules.

# Run at your own risk.  Making modifications could result in an endless loop letting the router wait indefinitely.
# As a precaution this scripts will loop a maximum of 12 times, as ping's timeout is ~10 seconds in my quick tests, meaning a script timeout of ~2 minutes.

# To install:
# Log into your router using SSH (or telnet for unsafe plain text communication)
# Save the script in /jffs/scripts
# Ensure to make the script executable:
#   chmod +x /jffs/scripts/port4_vlan.sh
# Run:
#   nvram set script_usbmount="/jffs/scripts/port4_vlan.sh &"
#   nvram commit
# Verify that the nvram value is set properly using:
#   nvram show | grep script_usbmount
# This script requires to be sent to background, as it is a blocking process.

# IMPORTANT
# If you do not have a mountable drive connected via USB, the script will not be launched. Ensure there is a mounted drive on the main page of the GUI.

n=0;

while [ $n -le 12 ];
do
  ping -c1 google.com > /dev/null
  if [ $? -eq 0 ]
  then 
    robocfg vlan 1 ports "1 2 3 5t"
    robocfg vlan 10 ports "4 5t"
    vconfig add eth0 10
    ifconfig vlan10 up
    brctl addif br0 vlan10
    ebtables -t broute -I BROUTING -p IPv4 -i vlan10 --ip-dst 192.168.0.0/24 --ip-proto tcp -j DROP
    ebtables -t broute -I BROUTING -p IPv4 -i vlan10 --ip-dst 192.168.0.0/24 --ip-proto udp -j DROP
    ebtables -t broute -I BROUTING -p IPv4 -i vlan10 --ip-dst 192.168.0.0/24 --ip-proto icmp -j DROP
    ebtables -t filter -I FORWARD -i vlan10 -o ! eth0 -j DROP
    ebtables -t filter -I FORWARD -i ! eth0 -o vlan10 -j DROP
    ebtables -t broute -I BROUTING -p IPv4 -i vlan10 --ip-dst 192.168.0.0/24 --ip-proto tcp --ip-destination-port 53 -j ACCEPT
    ebtables -t broute -I BROUTING -p IPv4 -i vlan10 --ip-dst 192.168.0.0/24 --ip-proto udp --ip-destination-port 53 -j ACCEPT

    exit 0
  fi
  n=$(( n+1 ));
done