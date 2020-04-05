tee liliksdk.sh <<EOF
#!/bin/sh
TMPDIR=\$(mktemp -d)
mkdir -p \$TMPDIR
chmod 700 \$TMPDIR
ARCHIVE=\$(awk '/^__ARCHIVE_BELOW__/ {print NR + 1; exit 0; }' \$0)
tail -n+\$ARCHIVE \$0 | tar x -C \$TMPDIR
cd \$TMPDIR
chmod 755 ./install.sh
./install.sh && rm -rf \$TMPDIR || echo "Installation failed, try again running \${TMPDIR}/install.sh"

exit 0

__ARCHIVE_BELOW__
EOF

chmod +x liliksdk.sh
tar cvf liliksdk.tar -C installer debian-preseed.iso install.sh lilik.sh openwrt-preseed.img.gz
cat liliksdk.tar >> liliksdk.sh
gzip liliksdk.tar
