#!/bin/sh

opkg update
opkg install libubox
echo -e "\ndest opt /opt" >> /opt/etc/opkg.conf
opkg install -d opt libubus_2018-10-06-221ce7e7-1_armv7-2.6.ipk
opkg install -d opt hostapd-common_2018-12-02-c2c6c01b-6_armv7-2.6.ipk
opkg install -d opt wpa-supplicant_2018-12-02-c2c6c01b-6_armv7-2.6.ipk
opkg install fake-hwclock 
echo -e "\n/opt/usr/sbin/wpa_supplicant -s -B -Dwired -ieth0 -c /jffs/EAP/wpa_supplicant.conf" >>  /opt/etc/init.d/rc.unslung
