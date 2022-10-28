#!/bin/sh

# You might need to change this...
ESP_QEMU_PATH=/mnt/hgfs/app/qemu-esp-develop-20220203/qemu/bin
BUILD=debug

TARGET=xtensa-esp32-espidf # Don't change this. Only the ESP32 chip is supported in QEMU for now

#D:\tools\esptool-v3.3-win64\esptool
#gcc build/main/libmain.a freertos -o main.out
#esptool.py --chip esp32 elf2image build/main/main.out
#esptool.py --chip esp32 image_info build/lorawan_esp32_gw.bin
esptool.py --chip esp32 merge_bin --output build/esp32-main-qemu.bin --fill-flash-size 4MB 0x1000 build/bootloader/bootloader.bin  0x8000 build/partition_table/partition-table.bin  0x10000 build/lorawan_esp32_gw.bin --flash_mode dio --flash_freq 40m --flash_size 4MB
$ESP_QEMU_PATH/qemu-system-xtensa -nographic -M esp32 -no-reboot -netdev tap,id=n1,ifname=tap0,script=no,downscript=no -drive file=build/esp32-main-qemu.bin,if=mtd,format=raw

#cargo espflash --monitor /dev/ttyUSB0 E:\app\julia\lorawan_esp32_gw\build2\lorawan_esp32_gw.bin
#cargo espflash --monitor COM3 E:\app\julia\lorawan_esp32_gw\build2\lorawan_esp32_gw.bin
#D:\tools\esptool-v3.3-win64\esptool --chip esp32 -p COM3 -b 115200 write_flash --flash_freq 40m --flash_mode dio 0x1000 E:\app\julia\lorawan_esp32_gw\build2\bootloader\bootloader.bin 0x8000 E:\app\julia\lorawan_esp32_gw\build2\partition_table\partition-table.bin 0x10000 E:\app\julia\lorawan_esp32_gw\build2\lorawan_esp32_gw.bin
--flash_size 32m
idf.py -p COM3 monitor

esptool.py --chip esp32 merge_bin --output build/qemu-esp32-wifitest.bin --fill-flash-size 4MB 0x1000 build/bootloader/bootloader.bin  0x8000 build/partition_table/partition-table.bin  0x10000 build/emulation.bin --flash_mode dio --flash_freq 40m --flash_size 4MB
$ESP_QEMU_PATH/qemu-system-xtensa -nographic -M esp32 -m 4 -no-reboot -nic user,model=open_eth,netdev=n1,hostfwd=tcp::8000-:80 -drive file=build/qemu-esp32-wifitest.bin,if=mtd,format=raw


qemu-system-arm -cpu arm1176 -m 256 -M versatilepb \
  -kernel kernel-qemu-arm1176-versatilepb \
  -hda rpi-wheezy-overlay \
  -append "console=ttyAMA0 root=/dev/sda2 ro init=/sbin/init-overlay" \
  -nographic \
  -virtfs local,path=shareddir,security_model=none,mount_tag=shareddir \
  -object can-bus,id=canbus0 \
  -object can-host-socketcan,id=canhost0,if=can0,canbus=canbus0 \
  -device kvaser_pci,canbus=canbus0,host=can0 \
guest machine:
ip link set can0 type can bitrate 1000000
ip link set can0 up
cansend can0 1807EC0B#1122334455667788
cansend can0 5A1#11.22.33.44.55.66.77.88
host machine:
ip link add dev can0 type vcan
ip link set can0 up
ifconfig
candump can0
host machine output:
vcan0  1807EC0B  [08]  11 22 33 44 55 66 77 88
vcan0       5A1  [08]  11 22 33 44 55 66 77 88


leafcolor@ubuntu20vm:~/app$ $ESP_QEMU_PATH/qemu-system-xtensa -machine esp32 -device help
Controller/Bridge/Hub devices:
name "i82801b11-bridge", bus PCI
name "pci-bridge", bus PCI, desc "Standard PCI Bridge"
name "pci-bridge-seat", bus PCI, desc "Standard PCI Bridge (multiseat)"
name "usb-hub", bus usb-bus

USB devices:
name "ich9-usb-ehci1", bus PCI
name "ich9-usb-ehci2", bus PCI
name "ich9-usb-uhci1", bus PCI
name "ich9-usb-uhci2", bus PCI
name "ich9-usb-uhci3", bus PCI
name "ich9-usb-uhci4", bus PCI
name "ich9-usb-uhci5", bus PCI
name "ich9-usb-uhci6", bus PCI
name "nec-usb-xhci", bus PCI
name "pci-ohci", bus PCI, desc "Apple USB Controller"
name "piix3-usb-uhci", bus PCI
name "piix4-usb-uhci", bus PCI
name "qemu-xhci", bus PCI
name "usb-ehci", bus PCI

Storage devices:
name "am53c974", bus PCI, desc "AMD Am53c974 PCscsi-PCI SCSI adapter"
name "dc390", bus PCI, desc "Tekram DC-390 SCSI adapter"
name "ich9-ahci", bus PCI, alias "ahci"
name "ide-cd", bus IDE, desc "virtual IDE CD-ROM"
name "ide-hd", bus IDE, desc "virtual IDE disk"
name "lsi53c810", bus PCI
name "lsi53c895a", bus PCI, alias "lsi"
name "megasas", bus PCI, desc "LSI MegaRAID SAS 1078"
name "megasas-gen2", bus PCI, desc "LSI MegaRAID SAS 2108"
name "mptsas1068", bus PCI, desc "LSI SAS 1068"
name "nvme", bus PCI, desc "Non-Volatile Memory Express"
name "nvme-ns", bus nvme-bus, desc "Virtual NVMe namespace"
name "nvme-subsys", desc "Virtual NVMe subsystem"
name "pvscsi", bus PCI
name "scsi-block", bus SCSI, desc "SCSI block device passthrough"
name "scsi-cd", bus SCSI, desc "virtual SCSI CD-ROM"
name "scsi-generic", bus SCSI, desc "pass through generic scsi device (/dev/sg*)"
name "scsi-hd", bus SCSI, desc "virtual SCSI disk"
name "sd-card", bus sd-bus
name "sdhci-pci", bus PCI
name "usb-bot", bus usb-bus
name "usb-mtp", bus usb-bus, desc "USB Media Transfer Protocol device"
name "usb-storage", bus usb-bus
name "usb-uas", bus usb-bus
name "vhost-scsi", bus virtio-bus
name "vhost-scsi-pci", bus PCI
name "vhost-scsi-pci-non-transitional", bus PCI
name "vhost-scsi-pci-transitional", bus PCI
name "vhost-user-blk", bus virtio-bus
name "vhost-user-blk-pci", bus PCI
name "vhost-user-blk-pci-non-transitional", bus PCI
name "vhost-user-blk-pci-transitional", bus PCI
name "vhost-user-fs-device", bus virtio-bus
name "vhost-user-fs-pci", bus PCI
name "vhost-user-scsi", bus virtio-bus
name "vhost-user-scsi-pci", bus PCI
name "vhost-user-scsi-pci-non-transitional", bus PCI
name "vhost-user-scsi-pci-transitional", bus PCI
name "virtio-blk-device", bus virtio-bus
name "virtio-blk-pci", bus PCI, alias "virtio-blk"
name "virtio-blk-pci-non-transitional", bus PCI
name "virtio-blk-pci-transitional", bus PCI
name "virtio-scsi-device", bus virtio-bus
name "virtio-scsi-pci", bus PCI, alias "virtio-scsi"
name "virtio-scsi-pci-non-transitional", bus PCI
name "virtio-scsi-pci-transitional", bus PCI

Network devices:
name "e1000", bus PCI, alias "e1000-82540em", desc "Intel Gigabit Ethernet"
name "e1000-82544gc", bus PCI, desc "Intel Gigabit Ethernet"
name "e1000-82545em", bus PCI, desc "Intel Gigabit Ethernet"
name "i82550", bus PCI, desc "Intel i82550 Ethernet"
name "i82551", bus PCI, desc "Intel i82551 Ethernet"
name "i82557a", bus PCI, desc "Intel i82557A Ethernet"
name "i82557b", bus PCI, desc "Intel i82557B Ethernet"
name "i82557c", bus PCI, desc "Intel i82557C Ethernet"
name "i82558a", bus PCI, desc "Intel i82558A Ethernet"
name "i82558b", bus PCI, desc "Intel i82558B Ethernet"
name "i82559a", bus PCI, desc "Intel i82559A Ethernet"
name "i82559b", bus PCI, desc "Intel i82559B Ethernet"
name "i82559c", bus PCI, desc "Intel i82559C Ethernet"
name "i82559er", bus PCI, desc "Intel i82559ER Ethernet"
name "i82562", bus PCI, desc "Intel i82562 Ethernet"
name "i82801", bus PCI, desc "Intel i82801 Ethernet"
name "ne2k_pci", bus PCI
name "pcnet", bus PCI
name "rtl8139", bus PCI
name "tulip", bus PCI
name "usb-net", bus usb-bus
name "virtio-net-device", bus virtio-bus
name "virtio-net-pci", bus PCI, alias "virtio-net"
name "virtio-net-pci-non-transitional", bus PCI
name "virtio-net-pci-transitional", bus PCI
name "vmxnet3", bus PCI, desc "VMWare Paravirtualized Ethernet v3"

Input devices:
name "ipoctal232", bus IndustryPack, desc "GE IP-Octal 232 8-channel RS-232 IndustryPack"
name "pci-serial", bus PCI
name "pci-serial-2x", bus PCI
name "pci-serial-4x", bus PCI
name "tpci200", bus PCI, desc "TEWS TPCI200 IndustryPack carrier"
name "usb-braille", bus usb-bus
name "usb-ccid", bus usb-bus, desc "CCID Rev 1.1 smartcard reader"
name "usb-kbd", bus usb-bus
name "usb-mouse", bus usb-bus
name "usb-serial", bus usb-bus
name "usb-tablet", bus usb-bus
name "usb-wacom-tablet", bus usb-bus, desc "QEMU PenPartner Tablet"
name "vhost-user-i2c-device", bus virtio-bus
name "vhost-user-i2c-pci", bus PCI
name "vhost-user-input", bus virtio-bus
name "vhost-user-input-pci", bus PCI
name "vhost-user-rng", bus virtio-bus
name "vhost-user-rng-pci", bus PCI
name "virtconsole", bus virtio-serial-bus
name "virtio-input-host-device", bus virtio-bus
name "virtio-input-host-pci", bus PCI, alias "virtio-input-host"
name "virtio-keyboard-device", bus virtio-bus
name "virtio-keyboard-pci", bus PCI, alias "virtio-keyboard"
name "virtio-mouse-device", bus virtio-bus
name "virtio-mouse-pci", bus PCI, alias "virtio-mouse"
name "virtio-serial-device", bus virtio-bus
name "virtio-serial-pci", bus PCI, alias "virtio-serial"
name "virtio-serial-pci-non-transitional", bus PCI
name "virtio-serial-pci-transitional", bus PCI
name "virtio-tablet-device", bus virtio-bus
name "virtio-tablet-pci", bus PCI, alias "virtio-tablet"
name "virtserialport", bus virtio-serial-bus

Display devices:
name "ati-vga", bus PCI
name "bochs-display", bus PCI
name "cirrus-vga", bus PCI, desc "Cirrus CLGD 54xx VGA"
name "secondary-vga", bus PCI
name "VGA", bus PCI
name "vhost-user-gpu", bus virtio-bus
name "vhost-user-gpu-pci", bus PCI
name "virtio-gpu-device", bus virtio-bus
name "virtio-gpu-pci", bus PCI, alias "virtio-gpu"
name "vmware-svga", bus PCI

Sound devices:
name "AC97", bus PCI, alias "ac97", desc "Intel 82801AA AC97 Audio"
name "ES1370", bus PCI, alias "es1370", desc "ENSONIQ AudioPCI ES1370"
name "hda-duplex", bus HDA, desc "HDA Audio Codec, duplex (line-out, line-in)"
name "hda-micro", bus HDA, desc "HDA Audio Codec, duplex (speaker, microphone)"
name "hda-output", bus HDA, desc "HDA Audio Codec, output-only (line-out)"
name "ich9-intel-hda", bus PCI, desc "Intel HD Audio Controller (ich9)"
name "intel-hda", bus PCI, desc "Intel HD Audio Controller (ich6)"
name "usb-audio", bus usb-bus

Misc devices:
name "ctucan_pci", bus PCI, desc "CTU CAN PCI"
name "guest-loader", desc "Guest Loader"
name "i2c-ddc", bus i2c-bus
name "kvaser_pci", bus PCI, desc "Kvaser PCICANx"
name "loader", desc "Generic Loader"
name "mioe3680_pci", bus PCI, desc "Mioe3680 PCICANx"
name "pcm3680_pci", bus PCI, desc "Pcm3680i PCICANx"
name "pvpanic-pci", bus PCI
name "tmp105", bus i2c-bus
name "u2f-passthru", bus usb-bus, desc "QEMU U2F passthrough key"
name "vfio-pci", bus PCI, desc "VFIO-based PCI device assignment"
name "vfio-pci-nohotplug", bus PCI, desc "VFIO-based PCI device assignment"
name "vhost-user-vsock-device", bus virtio-bus
name "vhost-user-vsock-pci", bus PCI
name "vhost-user-vsock-pci-non-transitional", bus PCI
name "vhost-vsock-device", bus virtio-bus
name "vhost-vsock-pci", bus PCI
name "vhost-vsock-pci-non-transitional", bus PCI
name "virtio-balloon-device", bus virtio-bus
name "virtio-balloon-pci", bus PCI, alias "virtio-balloon"
name "virtio-balloon-pci-non-transitional", bus PCI
name "virtio-balloon-pci-transitional", bus PCI
name "virtio-crypto-device", bus virtio-bus
name "virtio-crypto-pci", bus PCI
name "virtio-iommu-device", bus virtio-bus
name "virtio-iommu-pci", bus PCI, alias "virtio-iommu"
name "virtio-rng-device", bus virtio-bus
name "virtio-rng-pci", bus PCI, alias "virtio-rng"
name "virtio-rng-pci-non-transitional", bus PCI
name "virtio-rng-pci-transitional", bus PCI

Watchdog devices:
name "i6300esb", bus PCI, desc "Intel 6300ESB"

Uncategorized devices:
name "160s33b", bus SSI
name "320s33b", bus SSI
name "640s33b", bus SSI
name "at25128a-nonjedec", bus SSI
name "at25256a-nonjedec", bus SSI
name "at25df041a", bus SSI
name "at25df321a", bus SSI
name "at25df641", bus SSI
name "at25fs010", bus SSI
name "at25fs040", bus SSI
name "at26df081a", bus SSI
name "at26df161a", bus SSI
name "at26df321", bus SSI
name "at26f004", bus SSI
name "at45db081d", bus SSI
name "en25f32", bus SSI
name "en25p32", bus SSI
name "en25p64", bus SSI
name "en25q32b", bus SSI
name "en25q64", bus SSI
name "gd25q32", bus SSI
name "gd25q64", bus SSI
name "is25lp016d", bus SSI
name "is25lp032", bus SSI
name "is25lp064", bus SSI
name "is25lp080d", bus SSI
name "is25lp128", bus SSI
name "is25lp256", bus SSI
name "is25lq040b", bus SSI
name "is25wp032", bus SSI
name "is25wp064", bus SSI
name "is25wp128", bus SSI
name "is25wp256", bus SSI
name "m25p05", bus SSI
name "m25p10", bus SSI
name "m25p128", bus SSI
name "m25p16", bus SSI
name "m25p20", bus SSI
name "m25p32", bus SSI
name "m25p40", bus SSI
name "m25p64", bus SSI
name "m25p80", bus SSI
name "m25pe16", bus SSI
name "m25pe20", bus SSI
name "m25pe80", bus SSI
name "m25px32", bus SSI
name "m25px32-s0", bus SSI
name "m25px32-s1", bus SSI
name "m25px64", bus SSI
name "m45pe10", bus SSI
name "m45pe16", bus SSI
name "m45pe80", bus SSI
name "mt25ql01g", bus SSI
name "mt25ql02g", bus SSI
name "mt25ql512ab", bus SSI
name "mt25qu01g", bus SSI
name "mt25qu02g", bus SSI
name "mx25l12805d", bus SSI
name "mx25l12855e", bus SSI
name "mx25l1606e", bus SSI
name "mx25l2005a", bus SSI
name "mx25l25635e", bus SSI
name "mx25l25655e", bus SSI
name "mx25l3205d", bus SSI
name "mx25l4005a", bus SSI
name "mx25l6405d", bus SSI
name "mx25l8005", bus SSI
name "mx66l1g45g", bus SSI
name "mx66l51235f", bus SSI
name "mx66u1g45g", bus SSI
name "mx66u51235f", bus SSI
name "n25q00", bus SSI
name "n25q00a", bus SSI
name "n25q032", bus SSI
name "n25q032a11", bus SSI
name "n25q032a13", bus SSI
name "n25q064", bus SSI
name "n25q064a11", bus SSI
name "n25q064a13", bus SSI
name "n25q128", bus SSI
name "n25q128a11", bus SSI
name "n25q128a13", bus SSI
name "n25q256a", bus SSI
name "n25q256a11", bus SSI
name "n25q256a13", bus SSI
name "n25q512a", bus SSI
name "n25q512a11", bus SSI
name "n25q512a13", bus SSI
name "n25q512ax3", bus SSI
name "s25fl016k", bus SSI
name "s25fl064k", bus SSI
name "s25fl129p0", bus SSI
name "s25fl129p1", bus SSI
name "s25fl256s0", bus SSI
name "s25fl256s1", bus SSI
name "s25fl512s", bus SSI
name "s25fs512s", bus SSI
name "s25sl004a", bus SSI
name "s25sl008a", bus SSI
name "s25sl016a", bus SSI
name "s25sl032a", bus SSI
name "s25sl032p", bus SSI
name "s25sl064a", bus SSI
name "s25sl064p", bus SSI
name "s25sl12800", bus SSI
name "s25sl12801", bus SSI
name "s70fl01gs", bus SSI
name "s70fs01gs", bus SSI
name "ssi_psram", bus SSI
name "sst25vf016b", bus SSI
name "sst25vf032b", bus SSI
name "sst25vf040b", bus SSI
name "sst25vf080b", bus SSI
name "sst25wf010", bus SSI
name "sst25wf020", bus SSI
name "sst25wf040", bus SSI
name "sst25wf080", bus SSI
name "sst25wf512", bus SSI
name "w25q256", bus SSI
name "w25q32", bus SSI
name "w25q32dw", bus SSI
name "w25q512jv", bus SSI
name "w25q64", bus SSI
name "w25q80", bus SSI
name "w25q80bl", bus SSI
name "w25x10", bus SSI
name "w25x16", bus SSI
name "w25x20", bus SSI
name "w25x32", bus SSI
name "w25x40", bus SSI
name "w25x64", bus SSI
name "w25x80", bus SSI
name "xtensa.esp32"