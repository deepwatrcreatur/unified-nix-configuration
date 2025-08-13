# modules/nix-darwin/rsync-enhanced.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.rsync-enhanced;

  logDir = "/var/log/rsync";

  # Generate rsync command with all options
  mkRsyncCommand = job: let
    baseArgs = [
      "--verbose"
      "--progress"
      "--stats"
      "--human-readable"
    ] ++ job.extraArgs;

    archiveArgs = optionals job.archive [
      "--archive"
    ];

    deleteArgs = optionals job.deleteExtraneous [
      "--delete"
      "--delete-excluded"
    ];

    compressionArgs = optionals job.compress [
      "--compress"
    ];

    dryRunArgs = optionals job.dryRun [
      "--dry-run"
    ];

    excludeArgs = concatMap (pattern: ["--exclude" pattern]) job.exclude;

    allArgs = baseArgs ++ archiveArgs ++ deleteArgs ++ compressionArgs ++ dryRunArgs ++ excludeArgs;

    logFile = "${logDir}/${job.name}.log";

    rsyncCmd = "${pkgs.rsync}/bin/rsync ${concatStringsSep " " (map escapeShellArg allArgs)} ${escapeShellArg job.source} ${escapeShellArg job.destination}";
  in ''
    # Create log directory
    mkdir -p "${logDir}"

    # Log start time
    echo "$(date): Starting rsync job '${job.name}'" >> "${logFile}"

    # Run rsync with logging
    if ${rsyncCmd} 2>&1 | tee -a "${logFile}"; then
      echo "$(date): Rsync job '${job.name}' completed successfully" >> "${logFile}"
      ${optionalString (job.onSuccess != "") job.onSuccess}
    else
      echo "$(date): Rsync job '${job.name}' failed with exit code $?" >> "${logFile}"
      ${optionalString (job.onFailure != "") job.onFailure}
      exit 1
    fi

    # Rotate log if it gets too large (keep last 1000 lines)
    if [ $(wc -l < "${logFile}") -gt 1000 ]; then
      tail -n 1000 "${logFile}" > "${logFile}.tmp" && mv "${logFile}.tmp" "${logFile}"
    fi
  '';

  # Generate launchd plist for macOS - FIXED SYNTAX
  mkLaunchdPlist = name: job: {
    Label = "org.nixos.rsync-${name}";
    ProgramArguments = [
      "${pkgs.bash}/bin/bash"
      "-c"
      (mkRsyncCommand (job // {
        exclude = job.exclude ++ cfg.globalExcludes;
      }))
    ];
    StandardOutPath = "${logDir}/${job.name}.stdout.log";
    StandardErrorPath = "${logDir}/${job.name}.stderr.log";
  } 
  // optionalAttrs (job.schedule != null) {
    StartCalendarInterval = 
      if job.schedule == "daily" then [{
        Hour = 2;
        Minute = 0;
      }]
      else if job.schedule == "weekly" then [{
        Weekday = 0; # Sunday
        Hour = 2;
        Minute = 0;
      }]
      else if job.schedule == "hourly" then [{
        Minute = 0;
      }]
      else []; # Custom schedules would need manual plist configuration
  }
  // optionalAttrs (job.user != "root" && job.user != "$(whoami)" && job.user != "") {
    UserName = job.user;
  }
  // optionalAttrs (job.group != "staff" && job.group != "") {
    GroupName = job.group;
  }
  // optionalAttrs (job.environment != {}) {
    EnvironmentVariables = job.environment;
  };

  jobType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Name of the rsync job (used for logging and launchd label)";
      };

      source = mkOption {
        type = types.str;
        description = "Source path or remote location";
        example = "/Users/username/Documents/";
      };

      destination = mkOption {
        type = types.str;
        description = "Destination path or remote location";
        example = "user@backup-server:/backup/documents/";
      };

      schedule = mkOption {
        type = types.nullOr (types.enum [ "hourly" "daily" "weekly" ]);
        default = null;
        description = ''
          Schedule for automatic execution using launchd.
          For custom schedules, configure the launchd plist manually after activation.
        '';
        example = "daily";
      };

      archive = mkOption {
        type = types.bool;
        default = true;
        description = "Use archive mode (-a): preserve permissions, timestamps, symbolic links, etc.";
      };

      compress = mkOption {
        type = types.bool;
        default = false;
        description = "Compress data during transfer";
      };

      deleteExtraneous = mkOption {
        type = types.bool;
        default = false;
        description = "Delete files in destination that don't exist in source";
      };

      dryRun = mkOption {
        type = types.bool;
        default = false;
        description = "Perform a trial run with no changes made";
      };

      exclude = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of patterns to exclude";
        example = [ "*.tmp" "*.log" ".git/" "node_modules/" ];
      };

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional rsync arguments";
        example = [ "--backup" "--backup-dir=/backup/old" ];
      };

      onSuccess = mkOption {
        type = types.str;
        default = "";
        description = "Command to run on successful completion";
        example = ''osascript -e 'display notification "Backup completed" with title "Rsync"' '';
      };

      onFailure = mkOption {
        type = types.str;
        default = "";
        description = "Command to run on failure";
        example = ''osascript -e 'display notification "Backup failed" with title "Rsync"' '';
      };

      user = mkOption {
        type = types.str;
        default = "";
        description = "User to run the rsync job as (empty string for current user)";
      };

      group = mkOption {
        type = types.str;
        default = "staff";
        description = "Group to run the rsync job as";
      };

      environment = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Environment variables for the rsync job";
        example = { SSH_AUTH_SOCK = "/tmp/launch-ssh-auth-sock"; };
      };
    };
  };

in {
  options.services.rsync-enhanced = {
    enable = mkEnableOption "enhanced rsync service with launchd scheduling and monitoring";

    jobs = mkOption {
      type = types.attrsOf jobType;
      default = {};
      description = "Rsync jobs configuration";
      example = literalExpression ''
        {
          documents-backup = {
            name = "documents-backup";
            source = "/Users/username/Documents/";
            destination = "backup-server:/backups/documents/";
            schedule = "daily";
            compress = true;
            exclude = [ "*.tmp" ".git/" ];
            onSuccess = "osascript -e 'display notification \"Documents backed up\" with title \"Rsync\"'";
          };
        }
      '';
    };

    globalExcludes = mkOption {
      type = types.listOf types.str;
      default = [
        "*.tmp"
        "*.temp"
        "*.swp"
        "*~"
        ".DS_Store"
        "Thumbs.db"
        ".Trash-*"
        ".cache/"
        ".DocumentRevisions-V100"
        ".fseventsd"
        ".Spotlight-V100"
        ".TemporaryItems"
        ".VolumeIcon.icns"
        ".com.apple.timemachine.donotpresent"
      ];
      description = "Global exclude patterns applied to all jobs (includes macOS-specific excludes)";
    };

    logRetentionDays = mkOption {
      type = types.int;
      default = 30;
      description = "Number of days to retain rsync logs";
    };

    enableMonitoring = mkOption {
      type = types.bool;
      default = true;
      description = "Enable monitoring and status reporting";
    };
  };

  config = mkIf cfg.enable {
    # Ensure rsync package is available
    environment.systemPackages = [ pkgs.rsync ] ++ optional cfg.enableMonitoring (
      pkgs.writeShellScriptBin "rsync-status" ''
        #!/bin/sh
        echo "=== Rsync Enhanced Status (macOS/launchd) ==="
        echo

        echo "Active Jobs:"
        ${concatStringsSep "\n" (mapAttrsToList (name: job: ''
          echo "  ${job.name}:"
          echo "    LaunchAgent: org.nixos.rsync-${name}"
          if launchctl list | grep -q "org.nixos.rsync-${name}" 2>/dev/null; then
            echo "    Status: loaded"
          else
            echo "    Status: not loaded"
          fi
          echo "    Last log entries:"
          if [ -f "${logDir}/${job.name}.log" ]; then
            tail -n 3 "${logDir}/${job.name}.log" | sed 's/^/      /'
          else
            echo "      No log file found"
          fi
          echo
        '') cfg.jobs)}

        echo "Log files:"
        ls -lah ${logDir}/ 2>/dev/null || echo "  No log directory found"

        echo
        echo "Manual job execution:"
        ${concatStringsSep "\n" (mapAttrsToList (name: job: ''
          echo "  rsync-${name}  # Run ${job.name} job manually"
        '') cfg.jobs)}

        echo
        echo "LaunchD Management:"
        echo "  launchctl load ~/Library/LaunchAgents/org.nixos.rsync-*.plist    # Load agents"
        echo "  launchctl unload ~/Library/LaunchAgents/org.nixos.rsync-*.plist  # Unload agents"
        echo "  launchctl list | grep rsync                                      # List rsync agents"
      ''
    ) ++ (mapAttrsToList (name: job:
      pkgs.writeShellScriptBin "rsync-${name}" (mkRsyncCommand (job // {
        exclude = job.exclude ++ cfg.globalExcludes;
      }))
    ) cfg.jobs);

    # Create launchd agents for scheduled jobs
    launchd.agents = mapAttrs (name: job:
      mkIf (job.schedule != null) {
        enable = true;
        config = mkLaunchdPlist name job;
      }
    ) cfg.jobs;
  };
}
