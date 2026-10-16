{ pkgs, ... }:

let
  rcloneConfigPath = "/root/.config/rclone/rclone.conf";
  logFile = "/var/log/rclone-log.txt";
  mountPoint = "/mnt/telia";
  mountSource = "encrypted:/files/";
  mountType = "fuse.rclone";
  cacheDir = "/data2/rclone-cache";
  bwlimit = "50M:off";
  vfsCacheMaxSize = "185G";
  vfsCacheMaxAge = "438300h";
  vfsReadChunkSize = "16M";
  vfsReadChunkSizeLimit = "1G";
  vfsReadChunkStreams = 4;

  normalUnmount = pkgs.writeShellScript "rclone-normal-unmount" ''
    echo "rclone: attempting normal unmount of ${mountPoint}"
    if ${pkgs.fuse}/bin/fusermount -u ${mountPoint}; then
      echo "rclone: normal unmount of ${mountPoint} succeeded"
    else
      status=$?
      echo "rclone: normal unmount of ${mountPoint} failed (status $status)" >&2
      exit "$status"
    fi
  '';

  inspectMountInfo =
    name: mountInfo:
    pkgs.writeShellScript name ''
      ${pkgs.gawk}/bin/awk -v target='${mountPoint}' '
        $5 == target {
          separator = 0
          for (field = 7; field <= NF; field++) {
            if ($field == "-") {
              separator = field
              break
            }
          }
          if (separator == 0 || separator + 2 > NF) {
            print "rclone: malformed mountinfo entry for " target > "/dev/stderr"
            exit 2
          }
          print $(separator + 2) "|" $(separator + 1)
        }
      ' ${mountInfo}
    '';

  inspectMounts = inspectMountInfo "rclone-inspect-mounts" "/proc/self/mountinfo";

  cleanupScript =
    {
      inspectCommand,
      fusermountCommand,
    }:
    ''
      mounts="$(${inspectCommand})" || {
        status=$?
        echo "rclone: failed to inspect the mount table for ${mountPoint} (status $status)" >&2
        exit "$status"
      }

      if [ -z "$mounts" ]; then
        echo "rclone: no post-stop mount remains at ${mountPoint}"
        exit 0
      fi

      expected='${mountSource}|${mountType}'
      if [ "$mounts" != "$expected" ]; then
        echo "rclone: refusing post-stop cleanup of ${mountPoint}; expected exactly $expected, found:" >&2
        printf '%s\n' "$mounts" >&2
        exit 1
      fi

      echo "rclone: lazily detaching verified stale mount $expected from ${mountPoint}" >&2
      if ${fusermountCommand} -uz ${mountPoint}; then
        :
      else
        status=$?
        echo "rclone: lazy detach of ${mountPoint} failed (status $status)" >&2
        exit "$status"
      fi

      remaining="$(${inspectCommand})" || {
        status=$?
        echo "rclone: failed to verify cleanup of ${mountPoint} (status $status)" >&2
        exit "$status"
      }
      if [ -n "$remaining" ]; then
        echo "rclone: mount remains at ${mountPoint} after lazy detach:" >&2
        printf '%s\n' "$remaining" >&2
        exit 1
      fi
      echo "rclone: verified ${mountPoint} is detached"
    '';

  cleanupMount = pkgs.writeShellScript "rclone-cleanup-mount" (cleanupScript {
    inspectCommand = inspectMounts;
    fusermountCommand = "${pkgs.fuse}/bin/fusermount";
  });

  mockInspectMounts = pkgs.writeShellScript "rclone-mock-inspect-mounts" ''
    case "$MOCK_SCENARIO" in
      absent)
        ;;
      expected | detach-failure | post-inspect-error)
        if [ "$MOCK_SCENARIO" = post-inspect-error ] && [ -e "$MOCK_STATE/detached" ]; then
          exit 25
        fi
        if [ ! -e "$MOCK_STATE/detached" ]; then
          printf '%s\n' '${mountSource}|${mountType}'
        fi
        ;;
      detach-remains)
        printf '%s\n' '${mountSource}|${mountType}'
        ;;
      unexpected)
        printf '%s\n' 'other:/files/|${mountType}'
        ;;
      stacked)
        printf '%s\n' '${mountSource}|${mountType}' '${mountSource}|${mountType}'
        ;;
      inspect-error)
        exit 23
        ;;
    esac
  '';

  mockFusermount = pkgs.writeShellScript "rclone-mock-fusermount" ''
    printf '%s\n' "$*" >> "$MOCK_STATE/calls"
    if [ "$MOCK_SCENARIO" = detach-failure ]; then
      exit 24
    fi
    touch "$MOCK_STATE/detached"
  '';

  cleanupMountTestScript = pkgs.writeShellScript "rclone-cleanup-mount-test" (cleanupScript {
    inspectCommand = mockInspectMounts;
    fusermountCommand = mockFusermount;
  });

  validMountInfo = pkgs.writeText "rclone-valid-mountinfo" ''
    20 1 0:20 / /mnt/telia-other rw - ext4 /dev/other rw
    21 1 0:21 / /mnt/telia/subdir rw - fuse.rclone wrong:/subdir rw
    22 1 0:22 / /mnt/telia rw,nosuid - fuse.rclone encrypted:/files/ rw
  '';
  absentMountInfo = pkgs.writeText "rclone-absent-mountinfo" ''
    20 1 0:20 / /mnt/other rw - fuse.rclone encrypted:/files/ rw
  '';
  malformedMountInfo = pkgs.writeText "rclone-malformed-mountinfo" ''
    22 1 0:22 / /mnt/telia rw,nosuid malformed
  '';
  inspectValidMountInfo = inspectMountInfo "rclone-inspect-valid-mountinfo" validMountInfo;
  inspectAbsentMountInfo = inspectMountInfo "rclone-inspect-absent-mountinfo" absentMountInfo;
  inspectMalformedMountInfo = inspectMountInfo "rclone-inspect-malformed-mountinfo" malformedMountInfo;
  inspectMissingMountInfo = inspectMountInfo "rclone-inspect-missing-mountinfo" "/does/not/exist";

  cleanupMountTest = pkgs.runCommand "rclone-cleanup-mount-test" { } ''
    run_success() {
      scenario="$1"
      state="$TMPDIR/$scenario"
      mkdir -p "$state"
      MOCK_SCENARIO="$scenario" MOCK_STATE="$state" ${cleanupMountTestScript}
    }

    run_failure() {
      scenario="$1"
      state="$TMPDIR/$scenario"
      mkdir -p "$state"
      if MOCK_SCENARIO="$scenario" MOCK_STATE="$state" ${cleanupMountTestScript}; then
        echo "scenario $scenario unexpectedly succeeded" >&2
        exit 1
      fi
    }

    run_success absent
    test ! -e "$TMPDIR/absent/calls"

    run_success expected
    test "$(cat "$TMPDIR/expected/calls")" = "-uz ${mountPoint}"

    run_failure unexpected
    test ! -e "$TMPDIR/unexpected/calls"

    run_failure stacked
    test ! -e "$TMPDIR/stacked/calls"

    run_failure inspect-error
    test ! -e "$TMPDIR/inspect-error/calls"

    run_failure detach-failure
    test "$(cat "$TMPDIR/detach-failure/calls")" = "-uz ${mountPoint}"

    run_failure detach-remains
    test "$(cat "$TMPDIR/detach-remains/calls")" = "-uz ${mountPoint}"

    run_failure post-inspect-error
    test "$(cat "$TMPDIR/post-inspect-error/calls")" = "-uz ${mountPoint}"

    test "$(${inspectValidMountInfo})" = '${mountSource}|${mountType}'
    test -z "$(${inspectAbsentMountInfo})"
    if ${inspectMalformedMountInfo}; then
      echo "malformed mountinfo unexpectedly succeeded" >&2
      exit 1
    fi
    if ${inspectMissingMountInfo}; then
      echo "missing mountinfo unexpectedly succeeded" >&2
      exit 1
    fi

    printf '%s\n' \
      'PASS absent mount' \
      'PASS expected mount detached and verified absent' \
      'PASS unexpected identity rejected without detach' \
      'PASS stacked mounts rejected without detach' \
      'PASS initial inspection failure propagated' \
      'PASS detach failure propagated' \
      'PASS successful detach with remaining mount rejected' \
      'PASS second inspection failure propagated' \
      'PASS production parser exact-target and source/type parsing' \
      'PASS production parser absent exact target' \
      'PASS production parser malformed entry rejected' \
      'PASS production parser unreadable input rejected' \
      > "$out"
  '';
in

{
  systemd.services.rclone = {
    description = "Telia Crypt (rclone)";
    after = [ "network.target" ];
    unitConfig.RequiresMountsFor = [ cacheDir ];

    serviceConfig = {
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount \
          --log-file=${logFile} \
          --progress \
          --stats=1m \
          --log-level=INFO \
          --config=${rcloneConfigPath} \
          --allow-other \
          --allow-non-empty \
          --use-mmap \
          --transfers=8 \
          --cache-dir=${cacheDir} \
          --dir-cache-time=10000h \
          --buffer-size 100M \
          --vfs-cache-mode full \
          --vfs-read-chunk-size ${vfsReadChunkSize} \
          --vfs-read-chunk-size-limit ${vfsReadChunkSizeLimit} \
          --vfs-read-chunk-streams ${toString vfsReadChunkStreams} \
          --vfs-cache-max-age ${vfsCacheMaxAge} \
          --vfs-cache-max-size ${vfsCacheMaxSize} \
          --umask=0000 ${mountSource} ${mountPoint} \
          --bwlimit ${bwlimit} \
          --jottacloud-hard-delete
      '';
      ExecStop = normalUnmount;
      ExecStopPost = cleanupMount;
      Restart = "always";
      RestartSec = 10;
    };

    wantedBy = [ "default.target" ];
  };

  system.build.rcloneCleanupMountTest = cleanupMountTest;
}
