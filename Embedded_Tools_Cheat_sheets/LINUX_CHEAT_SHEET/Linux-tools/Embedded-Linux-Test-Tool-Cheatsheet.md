# Linux Test Tool Cheatsheet

## Compile Main test Tool (Using Yocto)

Append these lines into:

conf/local.conf

<pre>
BB_NUMBER_THREADS = "5"
CORE_IMAGE_EXTRA_INSTALL += " net-tools fbida i2c-tools alsa-utils tslib can-utils iproute2 iperf3 wpa-supplicant-passphrase wpa-supplicant-cli packagegroup-base-wifi mtd-utils pciutils iw bluez5 packagegroup-tools-bluetooth pv imx-test coreutils"
</pre>

## ADC

```
cat /sys/devices/platform/5a880000.adc/iio:device0/in_voltage4_raw
```


## fbi

<pre>
$ fbi -T 2 -d /dev/fb0 -noverbose gradient.bmp
</pre>

## i2c-tools

Dump the whole contents of I2C device at 7-bit address 0x50 on bus 9 (i2c-9), using the default read method (byte mode), after user confirmation:  
<pre>
$ i2cdump 9 0x50 
</pre>
Immediately dump the whole contents of I2C device at 7-bit address 0x50 on bus 9 (i2c-9), using I2C block read transactions (no user confirmation):  
<pre>
$ i2cdump -y 9 0x50 i 
</pre>
If the device is an EEPROM, the output would typically be the same as output of the previous example. Dump registers 0x00 to 0x3f of the I2C device at 7-bit address 0x2d on bus 1 (i2c-1), using the default read method (byte mode), after user confirmation:  
<pre>
$ i2cdump -r 0x00-0x3f 1 0x2d 
</pre>
Dump the registers of the SMBus device at address 0x69 on bus 0 (i2c-0), using one SMBus block read transaction with error checking enabled, after user confirmation:  
<pre>
$ i2cdump 0 0x69 sp
</pre>

## mmc csd

<pre>
$ mmc  extcsd read /dev/mmcblk0 
</pre>

## can-utils

<pre>
$ sudo ip link set can0 type can bitrate 125000 
$ sudo ip link set up can0 
$ cansend can0 01a#01020304 
$ cangen -i can0 
$ sudo ip link set can0 down 
$ sudo ip link set can0 up 
$ candump can0
</pre>

## alsa

<pre>
$ aplay -r 44100 sample.wav
$ aplay -r 48000 sample.wav
$ arecord record.wav 
</pre>

## wi-fi

### External Routing using Host PC as Gateway [@alienmind](https://github.com/alienmind85)

In order to ping google server 8.8.8.8 from board routed to Host PC you have to setup first board side using route command:

<pre>
$ route add default gw 10.0.0.1 netmask 255.255.255.0 eth0
</pre>

Then from Host PC side you have to setup the right routing using:

<pre>
#Internet (can ping google)
SRC=wlan0 
#Local routing (Board<-->Host)
DEST=eth0


#Refresh ip-table
sudo iptables --flush 
sudo iptables --table nat --flush
sudo iptables --delete-chain
sudo iptables --table nat --delete-chain

#Setup routing ip-table
sudo iptables --table nat --append POSTROUTING --out-interface ${SRC} -j MASQUERADE
sudo iptables --append FORWARD --in-interface ${DEST} -j ACCEPT
sudo iptables -A FORWARD -i ${SRC} -o ${DEST} -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i ${SRC} -o ${DEST} -j ACCEPT

sudo su -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
</pre>



### WI-FI Setup
<pre>
$ wlan0 up
$ wlan0 scan
$ iwlist scan
</pre>

### WI-FI simple connection

Required packages --> [wpa_supplicant | ip | iw | ping]

<pre>
$ iw dev
$ ip link show wlan0
$ ip link set wlan0 up
$ ip link show wlan0
$ iw wlan0 link
$ iw wlan0 scan | grep -i ssid
$ wpa_passphrase WIFI-GUEST WIFI-GUEST-PW > /etc/wpa_guest.conf
$ wpa_supplicant -i wlan0 -c /etc/wpa_guest.conf -Dwext &
$ udhcpc -i wlan0 
</pre>

### WI-FI simple Access Point

To do the test is necessary hostapd installed on your fs, first change /etc/hostapd.conf and put the preferred configuration:

```
interface=uap0
ssid=pi-5G
macaddr_acl=0
ignore_broadcast_ssid=0

## 2.4G
#hw_mode=a
#channel=7


## 5G
hw_mode=a
channel=0
country_code=US
ieee80211d=1
ieee80211n=1
ieee80211ac=1
wmm_enabled=1


## wpa auth
auth_algs=1
wpa=2
wpa_passphrase=11111111
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
```

Now turn on uap0 interface:

```
$ ifconfig uap0 up
```

Then enable and start hostapd.service:
```
$ systemctl enable hostapd.service
$ systemctl start hostapd
```
## Display image using gst-launch-1

```
$ gst-launch-1.0 filesrc location=/home/root/qr-code.jpg ! jpegdec ! imagefreeze ! imagefreeze ! waylandsink
```

### WI-FI test script
<pre>
#!/bin/bash

mount -t tmpfs -o size=2G tmpfs /tmp
echo "Connecting to WIFI-GUEST..."
#wpa_passphrase WIFI-GUEST WIFI-GUEST-PW > /etc/wpa_guest.conf
#echo "freq_list=5220" >> /etc/wpa_guest.conf
wpa_supplicant -i wlan0 -c /etc/wpa_guest.conf -Dwext &
WPA_PID=$!
sleep 8
udhcpc -i wlan0 
echo "done!"
echo "Updating system clock"
ntpdate pool.ntp.org 2> /dev/null
hwclock -w
echo "Starting download loop!"
echo "Downloading from ftp://192.168.1.7/File.gz"
echo "md5sum File.gz ==>  md5sum" 
echo 0 > /tmp/cycle

while true; do 
        LD_LIBRARY_PATH=/opt/WGET/ /opt/WGET/wget  -c ftp://192.168.1.7/File.gz -O /tmp/image.bin
        sync
        if [ `md5sum /tmp/image.bin | awk '{print $1}' | grep "md5sum" | wc -l`  == 1  ]; then 
                CICLE=`cat /tmp/cycle`
                echo "Image check - cycle = $CICLE => OK"
                CICLE_NEXT=$(($CICLE+1))
                echo $CICLE_NEXT > /tmp/cycle
                rm -rf /tmp/image.bin ; sync
        else
                CICLE=`cat /tmp/cycle`                                                                                  
                echo "Image check - cycle = $CICLE => #KO#"
                kill $WPA_PID
                exit 1
        fi
done
</pre>

## hci-tool (bluetooth)

Make hci0 visible using:

```
sudo hciconfig hci0 piscan
```

<pre>
$ bluetoothctl
$ agent on
$ default-agent
$ scan on
$ hcitool scan
$ hcidump --raw

References:
https://askubuntu.com/questions/450698/how-to-turn-on-and-off-bluetooth-visibility-mode
</pre>

## Test Bluetooth audio [@zacrob](https://gist.github.com/zacrob)

<pre>
pulseaudio --start --log-target=syslog
bluetoothctl
scan on
pair <id>
connect <id>
quit

aplay -r 44100 sample.wav
</pre>

## Test audio sink/source using pulseaudio

```
 $ hciattach -s 115200 ttymxc1 bcm43xx 115200 flow -t 20
 $ pulseaudio -D --system
 $ pulseaudio -k
 $ pulseaudio --start
 $ bluetoothctl 
 $ pacmd list-cards
 $ paplay -d bluez_sink.00_1E_7C_28_BE_F9.a2dp_sink /home/root/sample-44100.wav
 ```
 Or
 ```
 Audio output settings
$ pactl list sinks
$ pacmd set-default-sink $sink-number
$ gst-launch audiotestsrc ! pulsesink

Audio input settings
$ pactl list sources
$ pacmd set-default-source $sink-number

The PulseAudio I/O path setting status can be checked with:
$ pactl stat

Use the pacmd command to set the profile for particular features.
$ pacmd set-card-profile $CARD $PROFILE
$CARD is the card name listed by pacmd list-cards (for example, alsa_card.platform-sound-cs42888.34 in the
example above), and $PROFILE is the profile name. These are also listed by pamcd list-cards . (for example,
output:analog-surround-51 in the example above).

After setting the card profile, use $ pactl list sinks and $pacmd set-default-sink $sink-number to set
the default sink.
```

## Sniffing USB traffic

#### Setup Wire-shark
<pre>
sudo apt-get install wireshark
groups $USER
sudo adduser $USER wireshark
sudo dpkg-reconfigure wireshark-common
grep CONFIG_USB_MON /boot/config-`uname -r`
sudo modprobe usbmon
sudo setfacl -m u:$USER:r /dev/usbmon*
mount -t debugfs none /sys/kernel/debug
</pre>

### Open wireshark

Opne wireshark 
<pre>
wireshark

Choose the right /dev/usbmon* device
</pre>

## Test RTC (Real Time Clock)

### Display Time
date command take time from Linux Kernel instead of hwclock that take the time from rtc
```
date
hwclock
```

### Set new system date
```
date 112308121999 # MMDDhhmmYY
```

### Copy System Time to Hardware Time

```
date
Sat Aug 10 08:16:17 PDT 2013

hwclock
Sat 10 Aug 2013 08:26:53 AM PDT  -0.687841 seconds
```
Then set
```
hwclock -w --rtc=/dev/rtc1

hwclock
Sat 10 Aug 2013 08:16:27 AM PDT  -0.625382 seconds

date
Sat Aug 10 08:16:28 PDT 2013
```
### Copy Hardware Time to System Time

```
hwclock
Sat 10 Aug 2013 08:20:28 AM PDT  -0.687872 seconds

date
Sat Aug 10 08:34:48 PDT 2013

hwclock -s

date
Sat Aug 10 08:20:55 PDT 2013
```
References: https://www.thegeekstuff.com/2013/08/hwclock-examples/

## Camera Test using Gstreamer (Wayland distro)

<pre>
gst-launch-1.0 v4l2src device=/dev/video0 ! waylandsink
</pre>

## Test PCIe [@zacrob](https://gist.github.com/zacrob)

Read vendor_id 
```
$ lspci -nn
00:00.0 PCI bridge [0604]: Freescale Semiconductor Inc Device [1957:0000] (rev 01)
01:00.0 Ethernet controller [0200]: Intel Corporation I210 Gigabit Network Connection [8086:1533] (rev 03)
```

Show hex-dump of the whole config space - ethernet controller

```
$ lspci -d 8086:1533 -xxx

01:00.0 Ethernet controller: Intel Corporation I210 Gigabit Network Connection (rev 03)
00: 86 80 33 15 06 04 10 00 03 00 00 02 20 00 00 00
10: 00 00 00 72 00 00 00 00 01 10 00 00 00 00 20 72
20: 00 00 00 00 00 00 00 00 00 00 00 00 ff ff 00 00
30: 00 00 00 00 40 00 00 00 00 00 00 00 ac 01 00 00
40: 01 50 23 c8 08 20 00 00 00 00 00 00 00 00 00 00
50: 05 70 80 01 00 00 00 00 00 00 00 00 00 00 00 00
60: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
70: 11 a0 04 80 03 00 00 00 03 20 00 00 00 00 00 00
80: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
90: 00 00 00 00 00 00 00 00 00 00 00 00 ff ff ff ff
a0: 10 00 02 00 c2 8c 00 10 10 28 10 00 11 7c 42 04
b0: 00 00 11 10 00 00 00 00 00 00 00 00 00 00 00 00
c0: 00 00 00 00 1f 00 00 00 00 00 00 00 00 00 00 00
d0: 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
e0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
f0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
```

read pci register using setpci
```
$ setpci -s 01:00.0 00.L
```

Show hex-dump of the whole config space - SOC controller
```
$ lspci -d 1957:0000 -xxx

00:00.0 PCI bridge: Freescale Semiconductor Inc Device 0000 (rev 01)
00: 57 19 00 00 07 01 10 00 01 00 04 06 00 00 01 00
10: 04 00 00 70 00 00 00 00 00 01 ff 00 11 11 00 00
20: 00 72 20 72 f1 ff 01 00 00 00 00 00 00 00 00 00
30: 00 00 00 00 40 00 00 00 00 00 00 00 ff 01 00 00
40: 01 50 23 7e 00 00 00 00 00 00 00 00 00 00 00 00
50: 05 70 89 00 00 00 00 00 00 00 00 00 00 00 00 00
60: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
70: 10 00 42 00 01 80 00 00 10 28 10 00 13 f4 73 00
80: 08 00 11 30 00 00 00 00 c0 03 40 00 00 00 00 00
90: 00 00 00 00 1f 04 00 00 00 00 00 00 0e 00 00 00
a0: 03 00 01 00 00 00 00 00 00 00 00 00 00 00 00 00
b0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
c0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
d0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
e0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
f0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
```

read pci register using setpci
```
$ setpci -s 00:00.0 00.L
```

Rescan
```
$ echo 1 > /sys/bus/pci/rescan
```

verbose
```
$ lspci -vvv
```

## Test DISPLAY modes (resolutions)
```
$ systemctl stop weston
$ modetest

#connector_id 146
#crtc_id 36

$ modetest -M imx-drm -s 146@36:1920x1080
$ modetest -M imx-drm -s 146@36:720x480
```

## Testing Audio Codec Recording and Play

### Configuration
<pre>
Hardware have this configuration:
	MIC3_R Mic in
	MIC3_R, MIC3_R out

To setup right IN/OUT routing use:

$ alsamixer

#########################################################################################
Use the following settings:

PCM [dB gain: -20.00, -20.00]
Mic PGA
Mixer Amp. Driver Gain [dB gain: 20.00, 20.00]
ADC Level [dB gain: 20.00, 20.00]
ADCFGA Left Mute
ADCFGA Right Mute [Off] <--------------(OCCHIO A QUESTA)
AGC Attack Time
AGC Decay Time
AGC Gain Hysteresis
AGC Hysteresis
AGC Max PGA
AGC Left [Off]
AGC Max PGA
AGC Noise Debounce
AGC Noise Threshold
AGC Right [Off]
AGC Signal Debounce
AGC Target Level
CM1_L to Left Mixer Negative Resistor [10 kOhm]
CM1_R to Right Mixer Negative Resistor [10 kOhm]
CM2_L to Left Mixer Negative Resistor [Off]
CM2_R to Right Mixer Negative Resistor [Off]
HP DAC
HP Driver Gain [dB gain: 24.00, 24.00] 
HPL Output Mixer IN1_L 
HPL Output Mixer L_DAC
HPL Output Mixer MAL [Off]
HPR Output Mixer IN1_R
HPR Output Mixer MAR [Off]
HPR Output Mixer R_DAC
IN1_L to Left Mixer Positive Resistor [Off]
IN1_L to Right Mixer Negative Resistor [Off]
IN1_R to Left Mixer Positive Resistor [Off]
IN1_R to Right Mixer Positive Resistor [Off]
IN2_L to Left Mixer Positive Resistor [Off]
IN2_L to Right Mixer Positive Resistor [Off]
IN2_R to Left Mixer Negative Resistor [Off]
IN2_R to Right Mixer Positive Resistor [Off]
IN3_L to Left Mixer Positive Resistor [10 kOhm]
IN3_L to Right Mixer Negative Resistor [10 kOhm]
IN3_R to Left Mixer Negative Resistor [10 kOhm]
IN3_R to Right Mixer Positive Resistor [10 kOhm]
LO DAC [Off, Off]
LO Driver Gain [dB gain: 0.00, 0.00]
LOL Output Mixer L_DAC [Off]
LOR Output Mixer R_DAC [Off]
PGA Level [dB gain: 3.00, 3.00]

#####################################################################
Now we can record and play using:

export ALSADEV="plughw:0,0"

$ arecord -D plughw:0,0 -f dat helloworld.wav
$ aplay -D plughw:0,0 helloworld.wav

########################################################################

# DEBUG
$ export ALSADEV="plughw:0,0"
$ while true; do arecord -d 2 -D plughw:0,0 -f dat helloworld.wav; aplay -D plughw:0,0 helloworld.wav; done &

########################################################################

SAVE SOUND CONFIGURATION
$ alsactl --file ~/.config/asound.state store
$ alsactl --file ~/.config/asound.state restore
</pre>

### Debugging while true (tips)
<pre>
$ while true; do arecord -f S16_LE -d 10 -r 44100 --device=hw:0,0 ./test-mic.wav; aplay ./test-mic.wav; done &
</pre>

### Call ping command in more terminal

<pre>
DISPLAY=:0 xterm --hold	-e 'ifconfig eth0 10.10.10.10 netmask 255.255.255.0;ping 10.10.10.11; sleep 4' &
DISPLAY=:0 xterm --hold -e 'ifconfig eth1 10.10.20.10 netmask 255.255.255.0;ping 10.10.20.11; sleep 4' &
DISPLAY=:0 xterm --hold -e 'ifconfig eth2 10.10.30.10 netmask 255.255.255.0;ping 10.10.30.11; sleep 4' &
</pre>

### Autologin

<pre>
$ cat /proc/cmdline
$ vi /lib/systemd/system/serial-getty@.service
ExecStart=-/sbin/agetty -8 -L %I 115200 "-a" root $TERM
$ mv /lib/systemd/system/serial-getty@.service /lib/systemd/system/serial-getty@ttyLP0.service
</pre>

## Play Video Using G-Streamer

<pre>
`
$ gst-launch-1.0 filesrc location=video.mp4 ! decodebin3 ! imxvideoconvert_g2d ! queue ! waylandsink window-width=1280 window-height=480
</pre>

<pre>
$ gplay-1.0 <video.mp4> --audio-sink='alsasink device="hw:0,0"'
</pre>

## Play Video using browser html5

Chromium Mozilla can be used as browser both need h264/h265 support.

```
$ chromium --no-sandbox /home/root/test.html
```

```
/home/root/test.html
/home/root/video.mp4
```

```
<html lang="en">
<head>
    <meta charset="utf-8">
    <title></title>
    <style>
        body {
            min-width: 1920px;
            margin: 0px !important;
            background-color: black;
            color: white;
        }

        @font-face {
            font-family: Raleway;
            src: url(rpt-Regular.ttf);
        }

        @font-face {
            font-family: Raleway;
            src: url(rpt-Bold.otf);
            font-weight: bold;
        }

        div, span {
            font-family: Raleway;
        }

        .container-fixed {
            height: 100px;
            width: 1920px;
            color: white;
            font-size: 140px;
        }


        /*********************** Make it a marquee **********************/
        .marquee {
            /*width: 450px;*/
            margin: 0 auto;
            overflow: hidden;
            white-space: nowrap;
            box-sizing: border-box;
            animation: marquee 25s linear infinite;
            -webkit-animation: marquee 25s linear infinite; /* Chrome, Safari, Opera */
        }

        /* Make it move */
        @-webkit-keyframes marquee {
            0% {
                text-indent: 10em;
            }

            to {
                text-indent: -14em;
            }
        }

        .scroll-en {
            z-index: 2000;
            overflow: hidden;
            animation: scroll-en 21s linear infinite;
            -webkit-animation: scroll-en 21s linear infinite; /* Chrome, Safari, Opera */
            font-size: 185px;
            width: 5000px;
        }

        /* Make it move */
        @-webkit-keyframes scroll-en {
            0% {
                text-indent: 10em;
            }

            to {
                text-indent: -15em;
            }
        }
    </style>

</head>
<body style="overflow:hidden;">

    <video autoplay controls="controls">
    <source src="/home/root/video.mp4">
    Your browser does not support the HTML5 Video element.
    </video>

    <div class="container-fixed" style="position:absolute; left:0px; top: 550px;">
        THIS IS A FIXED TEXT
    </div>

    <div class="scroll-en" style="position:absolute; left:0px; top: 650px;">
        THIS IS A SCROLLING TEXT
    </div>

</body>

</html>
```