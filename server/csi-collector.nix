{ pkgs, config, secrets, ... }: {
  users.groups.csi-collector = { };
  users.users.csi-collector = {
    isSystemUser = true;
    createHome = true;
    home = "/var/lib/csi-collector";
    homeMode = "700";
    group = "csi-collector";
  };

  systemd.services."csi-collector" = {
    enable = true;
    wantedBy = [ "multi-user.target" ];

    script = ''
      exec ${pkgs.csi-collector}/bin/csi-collector --host 10.65.90.1 --port 8000 &
    '';

    environment = {
      "RUST_LOG" = "debug";
      "CSI_COLLECTOR_DATADIR" = config.users.users.csi-collector.home;
    };

    serviceConfig = {
      Type = "forking";
      User = config.users.users.csi-collector.name;
      Restart = "always";
    };
  };

  systemd.services."csi-collector-gc" = {
    path = with pkgs; [ coreutils findutils ];
    script = ''
      for folder in ${config.users.users.csi-collector.home}/*;
      do
        count=$(find $folder -mindepth 2 -maxdepth 2 | wc -l)

        if [[ $count -ne 4 ]]; then
          echo "Deleting folder $folder with $count/4 measurements"
          rm -r $folder
        fi
      done
    '';
    serviceConfig = {
      Type = "oneshot";
      User = config.users.users.csi-collector.name;
    };
  };
  systemd.timers."csi-collector-gc" = {
    wantedBy = [ "timers.target" ];
    partOf = [ "csi-collector-gc.service" ];
    timerConfig = {
      # start five minutes after boot
      OnBootSec = 5 * 60;
      # start five minutes after last exit
      OnUnitInactiveSec = 5 * 60;
      Unit = "csi-collector-gc";
    };
  };
}
