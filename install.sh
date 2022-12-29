#!/bin/env bash

#
# Author: Afiniel 
#
# Description: This script will install the required packages for the XMRig miner
#              and will configure the miner to run on boot.
#

# Install required packages
sudo apt-get update
sudo apt-get install -y unzip git build-essential cmake libuv1-dev libssl-dev libhwloc-dev msr-tools

# Download and extract XMRig
wget https://github.com/xmrig/xmrig/releases/download/v6.18.1/xmrig-6.18.1-linux-static-x64.tar.gz

tar -xvf xmrig-6.18.1-linux-static-x64.tar.gz
sudo rm -rf xmrig-6.18.1-linux-static-x64.tar.gz

# Build complete
clear
echo "Build complete"

sysctl -w vm.nr_hugepages=$(nproc)

for i in $(find /sys/devices/system/node/node* -maxdepth 0 -type d);
do
    echo 3 > "$i/hugepages/hugepages-1048576kB/nr_hugepages";
done

echo "1GB pages successfully enabled"
sleep 2
echo "----------------------------------------"
echo

# randomx boost

MSR_FILE=/sys/module/msr/parameters/allow_writes

if test -e "$MSR_FILE"; then
	echo on > $MSR_FILE
else
	modprobe msr allow_writes=on
fi

if grep -E 'AMD Ryzen|AMD EPYC' /proc/cpuinfo > /dev/null;
	then
	if grep "cpu family[[:space:]]\{1,\}:[[:space:]]25" /proc/cpuinfo > /dev/null;
		then
			if grep "model[[:space:]]\{1,\}:[[:space:]]97" /proc/cpuinfo > /dev/null;
				then
					echo "Detected Zen4 CPU"
					wrmsr -a 0xc0011020 0x4400000000000
					wrmsr -a 0xc0011021 0x4000000000040
					wrmsr -a 0xc0011022 0x8680000401570000
					wrmsr -a 0xc001102b 0x2040cc10
					echo "MSR register values for Zen4 applied"
				else
					echo "Detected Zen3 CPU"
					wrmsr -a 0xc0011020 0x4480000000000
					wrmsr -a 0xc0011021 0x1c000200000040
					wrmsr -a 0xc0011022 0xc000000401500000
					wrmsr -a 0xc001102b 0x2000cc14
					echo "MSR register values for Zen3 applied"
				fi
		else
			echo "Detected Zen1/Zen2 CPU"
			wrmsr -a 0xc0011020 0
			wrmsr -a 0xc0011021 0x40
			wrmsr -a 0xc0011022 0x1510000
			wrmsr -a 0xc001102b 0x2000cc16
			echo "MSR register values for Zen1/Zen2 applied"
		fi
elif grep "Intel" /proc/cpuinfo > /dev/null;
	then
		echo "Detected Intel CPU"
		wrmsr -a 0x1a4 0xf
		echo "MSR register values for Intel applied"
else
	echo "No supported CPU detected"
fi

# Create .sh script to run miner
echo "#!/bin/env bash" > start-xmrig.sh
echo "cd xmrig-6.18.1/" >> start-xmrig.sh
echo "sudo ./xmrig --url pool.hashvault.pro:443 --user 47GCWzqRpagW8KM2Kwzd527XyF1s21PJXP4xC5BG9yG6T9AafTKPTc5XVKNhL7dkCKfJF23wjPLeTWEcq2w4JDXGAsScGCy --pass x --donate-level 1 --tls --tls-fingerprint 420c7850e09b7c0bdcf748a7da9eb3647daf8515718f36d9ccfdd6b9ff834b14" >> start-xmrig.sh

# Restart system in 5 seconds
echo "----------------------------------------"
echo "Restarting system in 5 seconds"
echo "----------------------------------------"
echo "Hugepages enabled, MSR register values applied"
echo "----------------------------------------"
echo 5
sleep 1
echo 4
sleep 1
echo 3
sleep 1
echo 2
sleep 1
echo 1
sleep 1
echo 0

sudo rm -rf install.sh
sudo reboot
