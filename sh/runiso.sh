#!/bin/bash
# from http://unix.stackexchange.com/questions/9804/how-to-comment-multi-line-commands-in-shell-scripts

cmd=( qemu-system-x86_64
	-machine q35
	-cpu core2duo
# Window title in graphics mode
	-name "Simple OS"
# Boot a multiboot kernel file
#	-kernel ./boot.bin
# Enable a supported NIC
	-device e1000,netdev=net0
	-netdev user,id=net0
# Amount of CPU cores
	-smp 6
# Amount of memory in Megabytes
	-m 2048
# Disk configuration
    -cdrom sys/disk.iso
	#-drive id=disk0,file="sys/disk.img",if=none,format=raw
	#-device ahci,id=ahci
	#-device ide-hd,drive=disk0,bus=ahci.0
# Ouput network to file
#	-net dump,file=net.pcap
# Output serial to file
	-serial file:"sys/serial.log"
# Enable monitor mode
	-monitor telnet:localhost:8086,server,nowait
# Enable GDB debugging
	-s
# Wait for GDB before starting execution
#	-S
)

#execute the cmd string
"${cmd[@]}"
