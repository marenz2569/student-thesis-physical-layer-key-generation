{ pkgs, config, secrets, ... }: {
  users.groups.openwrt-updater = { };
  users.users.openwrt-updater = {
    isSystemUser = true;
    createHome = true;
    home = "/var/lib/openwrt-updater";
    homeMode = "700";
    group = "openwrt-updater";
  };

  sops.secrets.gitlab-token.owner = config.users.users.openwrt-updater.name;
  sops.secrets.router-ssh-privatekey.owner =
    config.users.users.openwrt-updater.name;

  systemd.services."openwrt-updater" = {
    path = with pkgs; [ coreutils curl openssh gawk ];
    script = ''
      RES=0

      # $1 filename
      # $2 gitlab job name
      download() {
        local TOKEN=$(cat ${config.sops.secrets.gitlab-token.path})
        local HASH

        if [ -f "$1" ]; then
          HASH=$(sha256sum $1 | awk '{ print $1; }')
        fi

        local STATUS_CODE=$(curl -Lf -w "%{http_code}" --header "PRIVATE-TOKEN: $TOKEN" "https://git.comnets.net/api/v4/projects/s2599166%2Fcsi-testbed-openwrt/jobs/artifacts/master/raw/$1?job=$2" --output $1 || true)

        if [[ "$STATUS_CODE" -eq "404" ]]; then
          echo "Build not found or no artifacts. Failed downloading $1. Skipping."
          RES=1
          return
        fi
 
        if [[ "$STATUS_CODE" -ne "200" ]]; then
          echo "Failed downloading with HTTP status $STATUS_CODE."
          RES=1
          return
        fi

        if [ -n $HASH ]; then
          local OUTPUT_HASH=$(sha256sum $1 | awk '{ print $1; }')
          if [ "$HASH" == "$OUTPUT_HASH" ]; then
            echo "File did not change. Exiting."
            RES=1
            return
          fi
        fi

        RES=0
      }

      # $1 host
      # $2 filename
      sysupgrade() {
        scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -O -i ${config.sops.secrets.router-ssh-privatekey.path} $2 root@$1:/tmp/sysupgrade.bin
        ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${config.sops.secrets.router-ssh-privatekey.path} root@$1 'sysupgrade -v -n /tmp/sysupgrade.bin' || true
      }

      download "openwrt-ath79-generic-glinet_gl-ar300m16-squashfs-sysupgrade.bin" "build-ar300m16"
      if [ $RES -eq 0 ]; then
        sysupgrade "10.65.90.10" "openwrt-ath79-generic-glinet_gl-ar300m16-squashfs-sysupgrade.bin"
        sysupgrade "10.65.90.11" "openwrt-ath79-generic-glinet_gl-ar300m16-squashfs-sysupgrade.bin"
        sysupgrade "10.65.90.12" "openwrt-ath79-generic-glinet_gl-ar300m16-squashfs-sysupgrade.bin"
      fi

      download "openwrt-ath79-generic-tplink_tl-wr1043nd-v2-squashfs-sysupgrade.bin" "build-tlwr1043ndv2"
      if [ $RES -eq 0 ]; then
        sysupgrade "10.65.90.20" "openwrt-ath79-generic-tplink_tl-wr1043nd-v2-squashfs-sysupgrade.bin"
        sysupgrade "10.65.90.21" "openwrt-ath79-generic-tplink_tl-wr1043nd-v2-squashfs-sysupgrade.bin"
        sysupgrade "10.65.90.22" "openwrt-ath79-generic-tplink_tl-wr1043nd-v2-squashfs-sysupgrade.bin"
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      User = config.users.users.openwrt-updater.name;
      WorkingDirectory = config.users.users.openwrt-updater.home;
    };
  };
  systemd.timers."openwrt-updater" = {
    wantedBy = [ "timers.target" ];
    partOf = [ "openwrt-updater.service" ];
    timerConfig = {
      # start five minutes after boot
      OnBootSec = 5 * 60;
      # start five minutes after last exit
      OnUnitInactiveSec = 5 * 60;
      Unit = "openwrt-updater.service";
    };
  };
}
