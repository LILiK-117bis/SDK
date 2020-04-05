#!/usr/bin/sh

DEPS="sudo gunzip ssh-copy-id ssh-keygen qemu-img qemu-system-i386 qemu-system-x86_64 vde_switch vdecmd vdeterm vde_plug2tap vde_tunctl"
echo "Checking dependencies..."
FAIL="false"
for dep in $deps; do
    if [ ! $(command -v $dep)  ]; then
        printf "\t$dep missing\n"
        FAIL="true"
    fi
done

if [ "${FAIL}" = "true" ]; then
    exit 1
fi

echo "All dependencies satisfied"

read -e -p "Select an installation path: " -i "${HOME}/LILiK-SDK" INSTALLPATH

mkdir -p "${INSTALLPATH}"
mkdir -p "${INSTALLPATH}/disks"

echo "Copying lilik.sh to ${INSTALLPATH}..."
cp lilik.sh "${INSTALLPATH}"
chmod 700 "${INSTALLPATH}/lilik.sh"
echo "Copying debian-preseed to ${INSTALLPATH}..."
cp debian-preseed.iso "${INSTALLPATH}/disks"
echo "Extracting openwrt-preseed.gz to ${INSTALLPATH}/disks..."
gunzip openwrt-preseed.img.gz -c > "${INSTALLPATH}/disks/firewall-disk.img"
read -e -p "Select a size for the debian host virtual hard disk: " -i "10G" IMGSIZE
echo "Creating QEMU virtual hard disk..."
qemu-img create -f raw "${INSTALLPATH}/disks/host-disk.img" "${IMGSIZE}" -o preallocation=off

read -r -p "Do you want to symlink ${HOME}/bin/lilik to lilik.sh? [Y/n] " USER_BIN_YN
case "${USER_BIN_YN}" in
    [nN])
        ;;
    *)
        ln -s "${INSTALLPATH}/lilik.sh" "${HOME}/bin/lilik"
esac

read -r -p "I'd like to automatically create a new dedicated SSH key, is it okay for you? [Y/n] " GEN_SSH_YN
case "${GEN_SSH_YN}" in
    [nN])
        SSH_KEY_PATH="${HOME}/.ssh/id_rsa"
        ;;
    *)
        read -e -p "Confirm new ssh key path: " -i "${HOME}/.ssh/id_ed25519_LILIK_SDK" SSH_KEY_PATH
        ssh-keygen -t ed25519 -f "${SSH_KEY_PATH}" -a 64 -N ''
esac

echo "Starting virtual network swtich..."
"${INSTALLPATH}/lilik.sh" switch start
echo "Starting firewall..."
"${INSTALLPATH}/lilik.sh" fw start
echo "Starting host installation..."
echo -e "\033[1mPlease wait for installation to finish on the VM\033[0m"
"${INSTALLPATH}/lilik.sh" host install
echo "Rebooting host"
"${INSTALLPATH}/lilik.sh" host start

read -r -p "Would you like to automatically set your key in authorized_keys for firewall and host (sudo required)? [Y/n] " SET_SSH_YN
case "${SET_SSH_YN}" in
    [nN])
        echo "Ok, please configure access to your VMs manually..."
        ;;
    *)
        read -e -p "Confirm ssh key path: " -i "${SSH_KEY_PATH}" SET_KEY_PATH
        echo "Attaching virtual switch to host (sudo required)..."
        "${INSTALLPATH}/lilik.sh" switch connect
        echo "Cleaning host keys for 10.150.40.1, 10.150.40.60"
        ssh-keygen -R 10.151.40.1
        ssh-keygen -R 10.151.40.60
        echo "Copying key to firewall..."
        echo -e "\033[1mProvide default password 'pippopippo' when asked\033[0m"
        ssh-copy-id -i "${SSH_KEY_PATH}" -o StrictHostKeyChecking=accept-new root@10.151.40.1
        echo "Copying key to host... provide default password 'pippopippo' when asked"
        ssh-copy-id -i "${SSH_KEY_PATH}" -o StrictHostKeyChecking=accept-new root@10.151.40.60
        echo "Detaching virtual switch from host..."
        "${INSTALLPATH}/lilik.sh" switch disconnect
esac
