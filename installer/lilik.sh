#!/usr/bin/env bash

CONTROLLER_IF_NAME="lilik"
CONTROLLER_IP_ADDR="10.151.40.210/24"
VM_SUBNET="10.151.42.0/24"
FW_IP_ADDR="10.151.40.1"

cd $(dirname $0)

switch() {
    case $1 in
        'start' )
            if [ -f /tmp/lilik_switch.pid ]; then
                echo "Switch already started."
                exit
            fi

            vde_switch \
                --daemon \
                --sock /tmp/lilik_switch.sock \
                --mgmt /tmp/lilik_switch.mgmt \
                --pidfile /tmp/lilik_switch.pid

            # Create three unallocated ports (1: firewall, 2: host, 3: tap interface)
            vdecmd -s /tmp/lilik_switch.mgmt port/create 1
            vdecmd -s /tmp/lilik_switch.mgmt port/create 2
            vdecmd -s /tmp/lilik_switch.mgmt port/create 3
            # Create VLAN with ID 5
            vdecmd -s /tmp/lilik_switch.mgmt vlan/create 5
            # Add port 1 and 2 tagged traffic to VLAN 5
            vdecmd -s /tmp/lilik_switch.mgmt vlan/addport 5 1
            vdecmd -s /tmp/lilik_switch.mgmt vlan/addport 5 2
            ;;
        'stop' ) 
            if [ -f /tmp/lilik_switch.pid ]; then
                pkill --pidfile /tmp/lilik_switch.pid
            fi
            ;;
        'console' )
            if [ -f /tmp/lilik_switch.pid ]; then
                vdeterm /tmp/lilik_switch.mgmt
            else
                echo "Switch not running"
            fi
            ;;
        'connect' )
            # Create new TAP interafaces named lilik and owned by user
            myname=$(whoami)
            sudo vde_tunctl -u "${myname}" -t "${CONTROLLER_IF_NAME}"
            # Plug the lilik tap interface to the switch
            vde_plug2tap \
                --daemon \
                --port=3 \
                --sock=/tmp/lilik_switch.sock \
                --pidfile=/tmp/lilik_tap.pid \
                "${CONTROLLER_IF_NAME}"
            # Configure lilik interface and routing
            sudo ip link set "${CONTROLLER_IF_NAME}" up
            sudo ip addr add "${CONTROLLER_IP_ADDR}" dev "${CONTROLLER_IF_NAME}"
            sudo ip route add "${VM_SUBNET}" via "${FW_IP_ADDR}" dev "${CONTROLLER_IF_NAME}"
        ;;
        'disconnect' )
            if [ -f /tmp/lilik_tap.pid ]; then
                pkill --pidfile /tmp/lilik_tap.pid
            fi
            sudo ip route del "${VM_SUBNET}" via "${FW_IP_ADDR}" dev "${CONTROLLER_IF_NAME}"
            sudo ip addr del "${CONTROLLER_IP_ADDR}" dev "${CONTROLLER_IF_NAME}"
            sudo ip link set "${CONTROLLER_IF_NAME}" down
            vde_tunctl -d "${CONTROLLER_IF_NAME}"
    esac
}


firewall() {
    case $1 in
        'start' )
            if [ -f /tmp/lilik_fw.pid ]; then
                echo "Firewall already started."
                exit
            fi

            /usr/bin/env qemu-system-i386 \
                -enable-kvm \
                -drive file=disks/firewall-disk.img,format=raw,if=virtio \
                -nic user,model=virtio-net-pci \
                -nic vde,sock=/tmp/lilik_switch.sock,port=1,model=virtio-net-pci \
                -pidfile /tmp/lilik_fw.pid \
                -daemonize
            ;;
        'stop' ) 
            if [ -f /tmp/lilik_fw.pid ]; then
                pkill --pidfile /tmp/lilik_fw.pid
            fi
    esac
}



host() {
    case $1 in
        'start' )
            if [ -f /tmp/lilik_host.pid ]; then
                echo "Host already started."
                exit
            fi

            /usr/bin/env qemu-system-x86_64 \
                -enable-kvm \
                -m 1024 \
                -drive file=disks/host-disk.img,format=raw,if=virtio \
                -nic vde,sock=/tmp/lilik_switch.sock,port=2,model=virtio-net-pci \
                -pidfile /tmp/lilik_host.pid \
                -daemonize
            ;;
        'install' )
            if [ -f /tmp/lilik_host.pid ]; then
                echo "Host already started."
                exit
            fi

            qemu-system-x86_64 \
                -enable-kvm \
                -m 1024 \
                -drive file=disks/host-disk.img,format=raw,if=virtio \
                -nic vde,sock=/tmp/lilik_switch.sock,port=2,model=virtio-net-pci \
                -pidfile /tmp/lilik_host.pid \
                -cdrom disks/debian-preseed.iso -boot d \
            ;;
        'stop' ) 
            if [ -f /tmp/lilik_host.pid ]; then
                pkill --pidfile /tmp/lilik_host.pid
            fi
    esac
}



case $1 in
    'fw' )
        firewall $2;
        ;;
    'host' )
        host $2;
        ;;
    'switch' )
        switch $2;
        ;;
    'all' )
        switch $2
        firewall $2
        host $2
        ;;
    * )
        printf "Usage: $0\n"
        printf "\t all {start|stop} \t # Start/stop all services \n"
        printf "\t {fw|host|switch} {start|stop} \t # Start/stop one service \n"
        printf "\t switch console \t # Open the switch console \n"
        printf "\t switch {connect|disconnect} \t # Connect/disconnect the switch to the host \n"
esac

