{ config
, pkgs
, ...
}:
let
  host = "bps-cloud.de";
  backupName = "nexctloud";
  resticRepositoryPath = "/var/backups/restic/nextcloud";
in
{
  users.groups.nextcloud = { };
  users.users.nextcloud = {
    isSystemUser = true;
    group = "nextcloud";
  };

  services.mysqlBackup.databases = [ "nextcloud" ];

  services.restic.backups.${backupName} = {
      paths = [ "/var/lib/nextcloud/data" ];
      repository = "file://${resticRepositoryPath}";
      passwordFile = "/var/run/secrets/restic-password";
    };

  sops.secrets = {
    nextcloud-admin-password = {
      sopsFile = ./secrets.yaml;
      key = "nextcloud-admin-password";
      mode = "0600";
      owner = "nextcloud";
      group = "nextcloud";
    };

    nextcloud-db-password = {
      sopsFile = ./secrets.yaml;
      key = "nextcloud-db-password";
      mode = "0600";
      owner = "nextcloud";
      group = "nextcloud";
    };

    nextcloud-secrets = {
      sopsFile = ./secrets.yaml;
      key = "nextcloud-secrets";
      mode = "0600";
      owner = "nextcloud";
      group = "nextcloud";
    };
    restic-password = { # Add this entry for the Restic password
      sopsFile = ./secrets.yaml;
      key = "restic-password";
      mode = "0400"; # More restrictive if preferred
      owner = "root"; # Or another appropriate user
      group = "root";
    };
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud28;
    https = true;
    hostName = host;
    secretFile = "/var/run/secrets/nextcloud-secrets";

    phpOptions."opcache.interned_strings_buffer" = "13";

    config = {
      dbtype = "mysql";
      dbname = "nextcloud";
      dbhost = "localhost";
      dbpassFile = "/var/run/secrets/nextcloud-db-password";

      adminuser = "admin";
      adminpassFile = "/var/run/secrets/nextcloud-admin-password";
    };

    settings = {
      maintenance_window_start = 2; # 02:00
      default_phone_region = "en";
      filelocking.enabled = true;

      redis = {
        host = config.services.redis.servers.nextcloud.bind;
        port = config.services.redis.servers.nextcloud.port;
        dbindex = 0;
        timeout = 1.5;
      };
    };

    caching = {
      redis = true;
      memcached = true;
    };
  };

  services.redis.servers.nextcloud = {
    enable = true;
    bind = "127.0.0.1"; # Use localhost for better security
    port = 6379;
  };

  services.nginx = {
    enable = true;
    virtualHosts."${host}" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
        extraConfig = ''
          client_max_body_size 10G;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    email = "lexi@bps-pforzheim.de";
    certs = {
      "${host}" = {
        webroot = "/var/lib/acme/acme-challenge";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
