#! /bin/sh

mkdir /jffs/opt
mkdir /tmp/opt
ln -nsf /jffs/opt /tmp/opt
# mount -o bind /jffs/opt /opt
wget -O - http://bin.entware.net/armv7sf-k2.6/installer/generic.sh |sh

cat > /jffs/scripts/services-start << EOF
#!/bin/sh

ln -nsf /jffs/opt /tmp/opt

/opt/etc/init.d/rc.unslung start

EOF
chmod +x /jffs/scripts/services-start

cat > /jffs/scripts/services-stop << EOF
#!/bin/sh

/opt/etc/init.d/rc.unslung stop
EOF
chmod +x /jffs/scripts/services-stop

if [ "$(nvram get jffs2_scripts)" != "1" ] ; then
  echo -e "$INFO Enabling custom scripts and configs from /jffs..."
  nvram set jffs2_scripts=1
  nvram commit
fi
