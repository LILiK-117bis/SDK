#!/usr/bin/sh
TMP_ISO_DEST=$(mktemp -d)
DEBIAN_IMG="https://debian.mirror.garr.it/debian-cd/10.3.0/amd64/iso-cd/debian-10.3.0-amd64-netinst.iso"
curl "${DEBIAN_IMG}" | bsdtar -C "${TMP_ISO_DEST}" -xf -
chmod -R +w "${TMP_ISO_DEST}"
sed -i \
    -e 's/--- quiet/--- quiet locale=en_GB.UTF-8 keymap=gb file=\/cdrom\/preseed.cfg theme=dark/g' \
    "${TMP_ISO_DEST}/isolinux/txt.cfg"
sed -i -e 's/timeout 0/timeout 1/g' "${TMP_ISO_DEST}/isolinux/isolinux.cfg"
sed -i -e 's/include gtk.cfg//g' "${TMP_ISO_DEST}/isolinux/menu.cfg"
cp preseed.cfg "${TMP_ISO_DEST}"
genisoimage -r -J -b isolinux/isolinux.bin -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -o installer/debian-preseed.iso "${TMP_ISO_DEST}"
