base64 installer/openwrt-preseed.img.gz > openwrt.b64
base64 installer/lilik.sh > lilik.sh.b64
base64 preseed.cfg > preseed.cfg.b64
sed \
  -e '/LILIKSH_B64HERE$/ r lilik.sh.b64' \
  -e '/OPENWRT_B64HERE$/ r openwrt.b64' \
  -e '/PRESEED_B64HERE$/ r preseed.cfg.b64' \
  installer/install_template.sh > liliksdk.sh

rm openwrt.b64
rm lilik.sh.b64
