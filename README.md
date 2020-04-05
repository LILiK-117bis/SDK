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

    curl https://github.com/LILiK-117bis/SDK/releases/download/v0.1/liliksdk.sh | sh

The interactive installer will guide you.

If you prefer you can download the compressed tarball [here] and
proceed with installation running `./install.sh` after decompression.

[here]: https://github.com/LILiK-117bis/SDK/releases/download/v0.1/liliksdk.tar.gz

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

- qemu
- vde2
- tunctl

On Debian you can satify the dependencies with:

    sudo apt install qemu-kvm vde2

Or in Arch and Manjaro you can use:

    sudo pacman -S qemu qemu-arch-extra vde2
