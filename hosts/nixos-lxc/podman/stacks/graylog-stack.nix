# hosts/nixos-lxc/podman/stacks/graylog-stack.nix
# Minimal Graylog 6.x + OpenSearch 2.x + MongoDB sandbox using container-stack module
# Memory-constrained for evaluation with internal security plugin disabled
{ config, lib, pkgs, ... }:

let
  optSec = import ../../../../lib/optional-secrets.nix { inherit lib; };

  graylogEnvSecret = optSec.mkSecret "graylog-env" {
    file = ../../../../secrets-agenix/graylog-env.age;
  };
in

{
  age.secrets."graylog-env" = graylogEnvSecret.definition // {
    owner = "root";
    group = "root";
    mode = "0440";
  };

  services.containerStacks.graylog = {
    network = "graylog";

    secrets = lib.optionalAttrs graylogEnvSecret.exists {
      "graylog-env".path = config.age.secrets."graylog-env".path;
    };

    containers = {
      mongodb = {
        image = "mongo:6.0";
        volumes = [
          "/var/lib/graylog/mongodb:/data/db"
        ];
      };

      opensearch = {
        image = "opensearchproject/opensearch:2.15.0";
        volumes = [
          "/var/lib/graylog/opensearch:/usr/share/opensearch/data"
        ];
        environment = {
          "discovery.type" = "single-node";
          "DISABLE_SECURITY_PLUGIN" = "true";
          "OPENSEARCH_JAVA_OPTS" = "-Xms512m -Xmx512m";
          "bootstrap.memory_lock" = "true";
        };
        extraOptions = [
          "--ulimit=memlock=-1:-1"
          "--ulimit=nofile=65536:65536"
        ];
      };

      graylog = {
        image = "graylog/graylog:6.1";
        dependsOn = [ "mongodb" "opensearch" ];
        ports = [
          "9000:9000"     # Web UI & REST API
          "1514:1514/udp" # Syslog UDP
        ];
        volumes = [
          "/var/lib/graylog/data:/usr/share/graylog/data/data"
        ];
        environment = {
          GRAYLOG_HTTP_BIND_ADDRESS = "0.0.0.0:9000";
          GRAYLOG_HTTP_EXTERNAL_URI = "https://graylog.deepwatercreature.com/";
          GRAYLOG_MONGODB_URI = "mongodb://mongodb:27017/graylog";
          GRAYLOG_ELASTICSEARCH_HOSTS = "http://opensearch:9200";
          GRAYLOG_SERVER_JAVA_OPTS = "-Xms1g -Xmx1g";
        };
      };
    };

    directories = [
      { path = "/var/lib/graylog/mongodb"; mode = "0755"; }
      { path = "/var/lib/graylog/opensearch"; mode = "0777"; user = "1000"; }
      { path = "/var/lib/graylog/data"; mode = "0777"; }
    ];

    firewall.allowedTCPPorts = [ 9000 ];
    firewall.allowedUDPPorts = [ 1514 ];
  };
}
