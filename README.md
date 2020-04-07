# LILiK SDK

Automated script based on *QEMU* to build at home a virtual simulated
LILiK infrastructure.

IPs are hardcoded in the provided images, with the following subnets:

- `10.151.40.0/24` for emulated physical host
- `10.151.42.0/24` for emulated lxc container

The configured entities are the following:

- `10.151.40.1`,`10.151.42.1`: OpenWRT Firewall
- `10.151.40.60`: **SkyBlue** emulated physical host
- `/tmp/lilik_switch.mgmt`: Management terminal of the virtual switch

## Setup

To install the current version SDK, simply run:

    wget https://github.com/LILiK-117bis/SDK/releases/download/v0.2-alpha/liliksdk.sh
    sh liliksdk.sh

The interactive installer will guide you.

If you prefer to install from source, do the following

	git clone https://github.com/LILiK-117bis/SDK.git
	cd SDK
	sh build.sh
	sh liliksdk.sh

## Use

After the installation you will find yourself with *switch*, *firewall*
and *host* started, but the *switch* will be disconnected from the host
running the SDK.

To access the virtual networks `10.151.x.x` directly from the host
running the SDK you can **connect** the switch to a virtual network
interface with the following command (sudo required):

    cd <SDK INST PATH>
    ./lilik.sh switch connnect

You can start and (brutally) stop hosts with the lilik.sh script.
Before staring any host you have to start the switch, otherwise they
won't boot.

## Requirements

Only for the installation process:

- genisoimage
- bsdtar
- curl
- sed

To run Lilik SDK:

- qemu (with foreign arch support)
- vde2

On Debian you can satify the dependencies with:

    sudo apt install qemu-kvm vde2 bsdtar genisoimage curl sed

Or in Arch and Manjaro you can use:

    sudo pacman -S qemu qemu-arch-extra vde2 curl cdrtools libarchive sed
