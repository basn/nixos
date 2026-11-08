if ! mount=$(findmnt -rn --mountpoint /data/typetype --output SOURCE,FSTYPE) || [ "$mount" != "data/typetype zfs" ]; then
  echo "TypeType requires data/typetype mounted as ZFS at /data/typetype" >&2
  exit 1
fi
