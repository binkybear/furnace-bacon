#!/system/bin/sh
kernel=$(uname -r)

if [[ $kernel == *-furnace-dirty* ]]; then
	echo "furnace-dirty kernel detected!" | tee /dev/kmsg
elif [[ $kernel == *-furnace* ]]; then
	echo "furnace kernel detected!" | tee /dev/kmsg
else
	echo "unknown kernel detected!" | tee /dev/kmsg
	exit 1
fi
