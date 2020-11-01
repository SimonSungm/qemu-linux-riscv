# qemu-linux-riscv project
This project is a combination of projects to develop and test QEMU, OpenSbi and Linux kernel for RISC-V.
You can use this project to develop and test
- Simulator: [QEMU](https://github.com/qemu/qemu)
- Firmware: [RISC-V Open Source Supervisor Binary Interface(OpenSBI)](https://github.com/riscv/opensbi) is supported currently
- Kernel: [Linux kernel](https://github.com/torvalds/linux)
- User programs: Not support yet(support prebuilt file system)

## Quick Start
To fetch the project source files, use command below. It will need several minutes to clone all the project source files.
```
$ mkdir qemu-linux-riscv && cd qemu-linux-riscv
$ repo init -u https://github.com/SimonSungm/manifests -b main -m qemu-linux-riscv.xml
$ repo sync -v -j4
$ cd build_tools/prebuilt
$ git lfs pull
```
When cloning the project source file, it may cause following errors. Just ignore it.
```
curl: (22) The requested URL returned error: 404 Not Found
Unable to retrieve clone.bundle; ignoring.
```
The source files do not include [riscv-gnu-toolchain](https://github.com/riscv/riscv-gnu-toolchain) since it is too big and takes too long to build. Therefore, you need to build the toolchain by yourself and install it in `qemu-linux-riscv/toolchain`. You can use following instructions to build the riscv-gnu-toolchain.
```
$ cd qemu-linux-riscv
$ git clone https://github.com/riscv/riscv-gnu-toolchain.git
$ mkdir toolchain
$ PREFIX_PATH=`pwd`/toolchain
$ cd riscv-gnu-toolchain 
$ ./configure --prefix=$PREFIX_PATH 
$ make
$ make linux
```
You can use make to get the help available targets to build.
```
$ cd qemu-linux-riscv
$ make
Usage: make [target]
Tagerts:
        build:          Build all necessary images needed to run qemu
                        Note: riscv-gnu-toolchain is needed
        run:            Run qemu, use DEBUG=on to enable deug mode

        linux:          Build linux kenrel image
        qemu:           Build qemu simulator
        opensbi:        Build opensbi image
        clean_linux:    Clean linux kenrel target files and image
        qemu:           Clean qemu target files and image
        opensbi:        Clean opensbi target files and image
        clean           Clean all target files
```
Build the project and run qemu
```
$ make build
$ make run
```
The username is `root` and no passwd is required.