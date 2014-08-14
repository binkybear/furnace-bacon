#!/system/bin/sh
# Copyright (c) 2014, Savoca <adeddo27@gmail.com>
# Copyright (c) 2009-2014, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

lt=[furnace]
tcp=westwood
io=deadline
sd_r=255
sd_g=255
sd_b=255
sd_rgb_min=35

# Set TCP westwood
if [ -e /proc/sys/net/ipv4/tcp_congestion_control ]; then
	echo "$tcp" > /proc/sys/net/ipv4/tcp_congestion_control
	echo "$lt TCP: $tcp" | tee /dev/kmsg
fi

# Set IOSched
if [ -e /sys/block/mmcblk0/queue/scheduler ]; then
	echo "$io" > /sys/block/mmcblk0/queue/scheduler
	echo "$lt IOScheduler: $io" | tee /dev/kmsg
fi

# Disable MPD, enable msm_hotplug
if [ -e /sys/module/msm_hotplug/enabled ]; then
    stop mpdecision
	min_susp_freq=1036800
    echo "1" > /sys/module/msm_hotplug/enabled
    echo "1" > /sys/module/msm_hotplug/suspend_max_cpus
    echo "$min_susp_freq" > /sys/module/msm_hotplug/suspend_max_freq
    echo "$lt msm_hotplug: enabled" | tee /dev/kmsg
    echo "$lt msm_hotplug: min_susp_freq: $min_susp_freq" | tee /dev/kmsg
else
    echo "$lt msm_hotplug not found - using default hotplug" | tee /dev/kmsg
    start mpdecision
fi

# Sweep2Dim default
if [ -e /sys/android_touch/sweep2dim ]; then
	echo "0" > /sys/android_touch/sweep2wake
	echo "1" > /sys/android_touch/sweep2dim
	echo "73" > /sys/module/sweep2wake/parameters/down_kcal
	echo "73" > /sys/module/sweep2wake/parameters/up_kcal
	echo "$lt sweep2dim: enabled" | tee /dev/kmsg
fi

# Set RGB KCAL
if [ -e /sys/devices/platform/kcal_ctrl.0/kcal ]; then
	kcal="$sd_r $sd_g $sd_b"
	echo "$kcal" > /sys/devices/platform/kcal_ctrl.0/kcal
	echo "$sd_rgb_min" > /sys/devices/platform/kcal_ctrl.0/kcal_min
	echo "1" > /sys/devices/platform/kcal_ctrl.0/kcal_ctrl
	echo "$lt LCD_KCAL: red=[$sd_r], green=[$sd_g], blue=[$sd_b]" | tee /dev/kmsg
	echo "$lt LCD_KCAL: kcal_min=[$sd_rgb_min]" | tee /dev/kmsg
fi
