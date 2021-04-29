{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.zigbee2mqtt;

  format = pkgs.formats.yaml { };
  configFile = format.generate "zigbee2mqtt.yaml" cfg.settings;
in
{
  meta.maintainers = with maintainers; [ sweber ];

  options.services.zigbee2mqtt = {
    enable = mkEnableOption "enable zigbee2mqtt service";

    package = mkOption {
      description = "Zigbee2mqtt package to use";
      default = pkgs.zigbee2mqtt.override {
        dataDir = cfg.dataDir;
      };
      defaultText = literalExample ''
        pkgs.zigbee2mqtt {
          dataDir = services.zigbee2mqtt.dataDir
        }
      '';
      type = types.package;
    };

    dataDir = mkOption {
      description = "Zigbee2mqtt data directory";
      default = "/var/lib/zigbee2mqtt";
      type = types.path;
    };

    settings = mkOption {
      type = format.type;
      default = {};
      example = literalExample ''
        {
          homeassistant = config.services.home-assistant.enable;
          permit_join = true;
          serial = {
            port = "/dev/ttyACM1";
          };
        }
      '';
      description = ''
        Your <filename>configuration.yaml</filename> as a Nix attribute set.
        Check the <link xlink:href="https://www.zigbee2mqtt.io/information/configuration.html">documentation</link>
        for possible options.
      '';
    };
  };

  config = mkIf (cfg.enable) {

    # preset config values
    services.zigbee2mqtt.settings = {
      homeassistant = mkDefault config.services.home-assistant.enable;
      permit_join = mkDefault false;
      mqtt = {
        base_topic = mkDefault "zigbee2mqtt";
        server = mkDefault "mqtt://localhost:1883";
      };
      serial.port = mkDefault "/dev/ttyACM0";
      # reference device configuration, that is kept in a separate file
      # to prevent it being overwritten in the units ExecStartPre script
      devices = mkDefault "devices.yaml";
    };

    systemd.services.zigbee2mqtt = {
      description = "Zigbee2mqtt Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      environment.ZIGBEE2MQTT_DATA = cfg.dataDir;
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/zigbee2mqtt";
        User = "zigbee2mqtt";
        WorkingDirectory = cfg.dataDir;
        Restart = "on-failure";
        ProtectSystem = "strict";
        ReadWritePaths = cfg.dataDir;
        PrivateTmp = true;
        RemoveIPC = true;
      };
      preStart = ''
        cp --no-preserve=mode ${configFile} "${cfg.dataDir}/configuration.yaml"
      '';
    };

    users.users.zigbee2mqtt = {
      home = cfg.dataDir;
      createHome = true;
      group = "zigbee2mqtt";
      extraGroups = [ "dialout" ];
      uid = config.ids.uids.zigbee2mqtt;
    };

    users.groups.zigbee2mqtt.gid = config.ids.gids.zigbee2mqtt;
  };
}
