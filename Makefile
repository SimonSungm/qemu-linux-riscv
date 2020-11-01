##################################################
## Author: SimonSungm							##
## Data: 10-21-2020								##
## Description: qemu-riscv-linux project		##
##################################################

ifeq ("$(origin V)", "command line")
  BUILD_VERBOSE = $(V)
endif

ifeq ($(BUILD_VERBOSE),1)
  quiet =
  Q =
else
  quiet=quiet_
  Q = @
endif

export quiet Q BUILD_VERBOSE

#BUSYBOX_SRC := $(CURDIR)/fs/busybox
LINUX_SRC := $(CURDIR)/kernel/linux
QEMU_SRC := $(CURDIR)/simulator/qemu
OPENSBI_SRC := $(CURDIR)/firmware/opensbi
BUILD_TOOLS_DIR := $(CURDIR)/build_tools
TOOLCHAIN_DIR := $(CURDIR)/toolchain

OUT_DIR := $(CURDIR)/out/build
#OUT_DIR_BUSYBOX := $(OUT_DIR)/busybox
OUT_DIR_LINUX := $(OUT_DIR)/linux
OUT_DIR_QEMU := $(OUT_DIR)/qemu
OUT_DIR_OPENSBI := $(OUT_DIR)/opensbi

INSTALL_DIR := $(CURDIR)/out/install
INSTALL_DIR_QEMU := $(CURDIR)/out/install/qemu

ARCH := riscv
CROSS_COMPILE := $(TOOLCHAIN_DIR)/bin/riscv64-unknown-linux-gnu-
ROOTFS := $(BUILD_TOOLS_DIR)/prebuilt/rootfs.ext2


#busybox_image := $(INSTALL_DIR)/busybox
linux_image := $(INSTALL_DIR)/Image
qemu_image := $(INSTALL_DIR_QEMU)/bin/qemu-system-riscv64
opensbi_image := $(INSTALL_DIR)/fw_jump.bin


ifeq ($(DEBUG),on) 
	DEBUG_MODE := "-S -s"
else
	DEBUG_MODE := 
endif

BIOS := $(opensbi_image)



PHONY := all

all: 
	@echo -e "Usage: make [target]"
	@echo -e "Tagerts:"
	@echo -e "	build:      	Build all necessary images needed to run qemu\n" \
			 "	            	Note: riscv-gnu-toolchain is needed"
	@echo -e "	run:        	Run qemu, use DEBUG=on to enable deug mode"
	@echo -e ""
#	@echo -e "	busybox:    	Build root file system with busybox"
	@echo -e "	linux:      	Build linux kenrel image"
	@echo -e "	qemu:       	Build qemu simulator"
	@echo -e "	opensbi:    	Build opensbi image"
	@echo -e "	clean_linux: 	Clean linux kenrel target files and image"
	@echo -e "	qemu:       	Clean qemu target files and image"
	@echo -e "	opensbi:    	Clean opensbi target files and image"
	@echo -e "	clean       	Clean all target files"



image_dir:
	mkdir -p $(INSTALL_DIR)

#busybox: image_dir
#	mkdir -p $(OUT_DIR_BUSYBOX)
#	$(MAKE) -C $(BUSYBOX_SRC) O=$(OUT_DIR_BUSYBOX) CROSS_COMPILE=$(CROSS_COMPILE) defconfig
#	$(MAKE) -C $(BUSYBOX_SRC) O=$(OUT_DIR_BUSYBOX) CROSS_COMPILE=$(CROSS_COMPILE) all -j$$(nproc)
#	cd $(OUT_DIR_BUSYBOX) && $(MAKE) CROSS_COMPILE=$(CROSS_COMPILE) install && cp _install/bin/busybox $(INSTALL_DIR)
#PHONY += busybox

linux: image_dir
	mkdir -p $(OUT_DIR_LINUX)
	$(MAKE) -C $(LINUX_SRC) O=$(OUT_DIR_LINUX) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) defconfig
	$(MAKE) -C $(LINUX_SRC) O=$(OUT_DIR_LINUX) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -j$$(nproc)
	cp $(OUT_DIR_LINUX)/arch/riscv/boot/Image $(linux_image)

qemu: image_dir
	mkdir -p $(OUT_DIR_QEMU)
	mkdir -p $(INSTALL_DIR_QEMU)
	cd $(QEMU_SRC) && ./configure --target-list=riscv64-softmmu --prefix=$(INSTALL_DIR_QEMU)
	$(MAKE) -C $(QEMU_SRC) O=$(OUT_DIR_QEMU) -j$$(nproc)
	$(MAKE) -C $(QEMU_SRC) O=$(OUT_DIR_QEMU) install

opensbi: image_dir
	mkdir -p $(OUT_DIR_OPENSBI)
	make -C $(OPENSBI_SRC) O=$(OUT_DIR_OPENSBI) PLATFORM=generic CROSS_COMPILE=$(TOOLCHAIN_DIR)/bin/riscv64-unknown-elf- -j$$(nproc)
	cp $(OUT_DIR_OPENSBI)/platform/generic/firmware/fw_jump.bin $(opensbi_image)

PHONY += image_dir linux opensbi qemu

#clean_busybox:
#	rm -rf $(OUT_DIR_BUSYBOX)
#	rm $(INSTALL_DIR)/busybox
#PHONY += clean_busybox

clean_linux:
	rm -rf $(OUT_DIR_LINUX)
	rm $(INSTALL_DIR)/Image

clean_qemu:
	rm -rf $(OUT_DIR_QEMU)
	rm -rf $(INSTALL_DIR_QEMU)

clean_opensbi:
	rm -rf $(OUT_DIR_OPENSBI)
	rm -rf $(INSTALL_DIR)/fw_jump.bin

clean: 
	rm -rf $(OUT_DIR)
	rm -rf $(INSTALL_DIR)

PHONY += clean_linux clean_opensbi clean_qemu clean


build: linux opensbi qemu

run:
	$(qemu_image) -nographic -machine virt \
     -bios $(BIOS) -kernel $(linux_image) \
	 -append "root=/dev/vda ro console=ttyS0" \
     -drive file=$(ROOTFS),format=raw,id=hd0 \
     -device virtio-blk-device,drive=hd0 $(DEBUG_MODE) \
	 -netdev user,id=net0 -device virtio-net-device,netdev=net0


PHONY += build run

