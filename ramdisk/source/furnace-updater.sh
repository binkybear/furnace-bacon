#!/system/bin/sh

logtag="[FURNACE]"

function update-stop {
	echo "$logtag Update complete" | tee -a /data/local/tmp/furnace-ota/update.log
	echo "$logtag End update.log" >> /data/local/tmp/furnace-ota/update.log
	exit
}

# Setup updater workspace
if [ -d /data/local/tmp/furnace-ota ]; then
	if [ -f /data/local/tmp/furnace-ota/otainfo.conf ]; then
		rm /data/local/tmp/furnace-ota/otainfo.conf
	fi
	if [ -f /data/local/tmp/furnace-ota/status.txt ]; then
		rm /data/local/tmp/furnace-ota/status.txt
	fi
else
	mkdir /data/local/tmp/furnace-ota
fi

echo "$logtag Start update.log" > /data/local/tmp/furnace-ota/update.log

# Check for root access
if [ "$USER" != "root" ]; then
	echo "$logtag This script must be run as root" | tee -a /data/local/tmp/furnace-ota/update.log
	update-stop
fi

# Check for BusyBox
busybox_ver=$(busybox | head -1 | cut -f 2 -d " ")
if [ -z $busybox_ver ]; then
	echo "$logtag BusyBox not found" | tee -a /data/local/tmp/furnace-ota/update.log
	update-stop
fi

# Grab token and version
token=$(cat /furnace-updater.conf | grep Token | cut -f 2 -d " ")
version=$(cat /furnace-updater.conf | grep Version | cut -f 2 -d " ")
version_raw=$(cat /furnace-updater.conf | grep Version | cut -f 2 -d " " | tr -d ".")

# Print basic info
echo "$logtag Update started" | tee -a /data/local/tmp/furnace-ota/update.log
echo "$logtag Identifier token: $token" | tee -a /data/local/tmp/furnace-ota/update.log
echo "$logtag Kernel version: $version" | tee -a /data/local/tmp/furnace-ota/update.log
echo "$logtag BusyBox version: $busybox_ver" | tee -a /data/local/tmp/furnace-ota/update.log

# Check for internet connection
curl -s http://savoca.codefi.re/pub/furnace/ota/status.txt > /data/local/tmp/furnace-ota/status.txt
net_status=$(cat /data/local/tmp/furnace-ota/status.txt)
if [ "$net_status" = "OK" ]; then
	echo "$logtag Connected to savoca.codefi.re" | tee -a /data/local/tmp/furnace-ota/update.log
else
	echo "$logtag Unable to connect to savoca.codefi.re" | tee -a /data/local/tmp/furnace-ota/update.log
	update-stop
fi

# Download the config
curl -s http://savoca.codefi.re/pub/furnace/ota/$token/otainfo.conf > /data/local/tmp/furnace-ota/otainfo.conf
if [ -f /data/local/tmp/furnace-ota/otainfo.conf ]; then
	echo "$logtag OTA configuration downloaded" | tee -a /data/local/tmp/furnace-ota/update.log
else
	echo "$logtag OTA configuration failed to download" | tee -a /data/local/tmp/furnace-ota/update.log
	update-stop
fi

# Parse config elements
webid=$(cat /data/local/tmp/furnace-ota/otainfo.conf | grep Identifier | cut -f 2 -d " ")
webtoken=$(cat /data/local/tmp/furnace-ota/otainfo.conf | grep Token | cut -f 2 -d " ")
webversion=$(cat /data/local/tmp/furnace-ota/otainfo.conf | grep LatestVersion | cut -f 2 -d " " | tr -d ".")

# Clean old dirty runs again now that we have $webversion
if [ -f /data/local/tmp/furnace-ota/boot-$webversion.img ]; then
	rm /data/local/tmp/furnace-ota/boot-$webversion.img
fi
if [ -f /data/local/tmp/furnace-ota/boot-$webversion.img.md5 ]; then
	rm /data/local/tmp/furnace-ota/boot-$webversion.img.md5
fi

# Verify token
echo "$logtag Web identifier: $webid" | tee -a /data/local/tmp/furnace-ota/update.log
if [ "$token" = "$webtoken" ]; then
	echo "$logtag Identifier token accepted" | tee -a /data/local/tmp/furnace-ota/update.log
else
	echo "$logtag Identifier token mismatch" | tee -a /data/local/tmp/furnace-ota/update.log
	update-stop
fi

# Check if we are up-to-date
if [ $version_raw -ge $webversion ]; then
	echo "$logtag Already at latest version" | tee -a /data/local/tmp/furnace-ota/update.log
	update-stop
else
	echo "$logtag New version available" | tee -a /data/local/tmp/furnace-ota/update.log
fi

# Download new version
echo "$logtag Starting boot-$webversion.img download" | tee -a /data/local/tmp/furnace-ota/update.log
curl -s http://savoca.codefi.re/pub/furnace/ota/$token/boot-$webversion.img > /data/local/tmp/furnace-ota/boot-$webversion.img
if [ -f /data/local/tmp/furnace-ota/boot-$webversion.img ]; then
	echo "$logtag boot-$webversion.img downloaded" | tee -a /data/local/tmp/furnace-ota/update.log
else
	echo "$logtag boot-$webversion.img failed to download" | tee -a /data/local/tmp/furnace-ota/update.log
	update-stop
fi

# Download .md5 file
curl -s http://savoca.codefi.re/pub/furnace/ota/$token/boot-$webversion.img.md5 > /data/local/tmp/furnace-ota/boot-$webversion.img.md5
if [ -f /data/local/tmp/furnace-ota/boot-$webversion.img.md5 ]; then
	echo "$logtag boot-$webversion.img.md5 downloaded" | tee -a /data/local/tmp/furnace-ota/update.log
else
	echo "$logtag boot-$webversion.img.md5 failed to download" | tee -a /data/local/tmp/furnace-ota/update.log
	update-stop
fi

# Verify md5 hashes
local_md5=$(md5sum /data/local/tmp/furnace-ota/boot-$webversion.img | cut -f 1 -d " ")
remote_md5=$(cat /data/local/tmp/furnace-ota/boot-$webversion.img.md5)
if [ "$local_md5" = "$remote_md5" ]; then
	echo "$logtag boot-$webversion md5sum verified" | tee -a /data/local/tmp/furnace-ota/update.log
else
	echo "$logtag md5sum verification failed" | tee -a /data/local/tmp/furnace-ota/update.log
	update-stop
fi

# Install new boot.img
echo "$logtag Installing boot-$webversion.img" | tee -a /data/local/tmp/furnace-ota/update.log
dd if=/data/local/tmp/furnace-ota/boot-$webversion.img of=/dev/block/platform/msm_sdcc.1/by-name/boot bs=4096
echo "$logtag boot-$webversion.img installed" | tee -a /data/local/tmp/furnace-ota/update.log
echo "$logtag Reboot the device to finish installation" | tee -a /data/local/tmp/furnace-ota/update.log

# Cleanup
rm /data/local/tmp/furnace-ota/boot-$webversion.img
rm /data/local/tmp/furnace-ota/boot-$webversion.img.md5
rm /data/local/tmp/furnace-ota/status.txt

update-stop
