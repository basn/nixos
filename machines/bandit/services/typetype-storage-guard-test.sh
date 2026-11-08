set -eu
guard=$1
findmnt() {
  [ "$*" = "-rn --mountpoint /data/typetype --output SOURCE,FSTYPE" ] || exit 99
  printf '%s' "$mount_result"
  return "$mount_status"
}
export -f findmnt
check() {
  export mount_result=$1 mount_status=$2
  actual=0
  bash "$guard" || actual=$?
  [ "$actual" -eq "$3" ] || { echo "Unexpected guard result: $actual" >&2; exit 1; }
}
check '' 1 1
check 'data/other zfs' 0 1
check 'data/typetype ext4' 0 1
check 'data/typetype zfs' 1 1
check $'data/typetype zfs\ndata/other zfs' 0 1
check 'data/typetype zfs' 0 0
