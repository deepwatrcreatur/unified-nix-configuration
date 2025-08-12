{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.rsync-enhanced;
  
  # Detect if we're on Darwin/macOS
  isDarwin = pkgs.stdenv.isDarwin;
  
  # Platform-specific paths
  logDir = if isDarwin then "/var/log/rsync" else "/var/log/rsync";
  
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

  # Generate launchd plist for macOS
  mkLaunchdPlist = name: job: {
    Label = "org.nixos.rsync-${name}";
    ProgramArguments = [
      "${pkgs.bash}/bin/bash"
      "-c"
      (mkRsyncCommand (job // {
        exclude = job.exclude ++ cfg.globalExcludes;
      }))
    ];
    ${optionalString (job.schedule != null) "StartCalendarInterval"} = mkIf (job.schedule != null) (
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
      else [] # Custom schedules would need manual plist configuration
    );
    ${optionalString (job.user != "root") "UserName"} = mkIf (job.user != "root") job.user;
    ${optionalString (job.group != "root") "GroupName"} = mkIf (job.group != "root") job.group;
    StandardOutPath = "${logDir}/${job.name}.stdout.log";
    StandardErrorPath = "${logDir}/${job.name}.stderr.log";
    EnvironmentVariables = job.environment;
  };

  jobType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Name of the rsync job (used for logging and service name)";
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
          Schedule for automatic execution. 
          On Linux: creates systemd timer. On macOS: creates launchd job.
          For custom schedules, configure manually after activation.
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
        example = if isDarwin then "osascript -e 'display notification \"Backup completed\" with title \"Rsync\"'" 
                              else "notify-send 'Backup completed successfully'";
      };
      
      onFailure = mkOption {
        type = types.str;
        default = "";
        description = "Command to run on failure";
        example = if isDarwin then "osascript -e 'display notification \"Backup failed\" with title \"Rsync\"'"
                              else "notify-send 'Backup failed!'";
      };
      
      user = mkOption {
        type = types.str;
        default = if isDarwin then "$(whoami)" else "root";
        description = "User to run the rsync job as";
      };
      
      group = mkOption {
        type = types.str;
        default = if isDarwin then "staff" else "root";
        description = "Group to run the rsync job as";
      };
      
      environment = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Environment variables for the rsync job";
        example = { 
          SSH_AUTH_SOCK = if isDarwin then "/tmp/launch-ssh-auth-sock" else "/run/user/1000/ssh-agent";
        };
      };
    };
  };

in {
  options.services.rsync-enhanced = {
    enable = mkEnableOption "enhanced rsync service with scheduling and monitoring";
    
    jobs = mkOption {
      type = types.attrsOf jobType;
      default = {};
      description = "Rsync jobs configuration";
      example = literalExpression ''
        {
          documents-backup = {
            name = "documents-backup";
            source = "${if isDarwin then "/Users/username" else "/home/user"}/Documents/";
            destination = "backup-server:/backups/documents/";
            schedule = "daily";
            compress = true;
            exclude = [ "*.tmp" ".git/" ];
            onSuccess = ${if isDarwin then ''"osascript -e 'display notification \"Documents backed up\" with title \"Rsync\"'"'' 
                                       else ''"echo 'Documents backed up successfully'"''};
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
      ] ++ optionals isDarwin [
        ".DocumentRevisions-V100"
        ".fseventsd"
        ".Spotlight-V100"
        ".TemporaryItems"
        ".VolumeIcon.icns"
        ".com.apple.timemachine.donotpresent"
      ];
      description = "Global exclude patterns applied to all jobs";
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

  config = mkIf cfg.enable (mkMerge [
    # Common configuration for both platforms
    {
      # Ensure rsync package is available
      environment.systemPackages = [ pkgs.rsync ] ++ optional cfg.enableMonitoring (
        pkgs.writeShellScriptBin "rsync-status" ''
          #!/bin/sh
          echo "=== Rsync Enhanced Status (${if isDarwin then "macOS" else "Linux"}) ==="
          echo
          
          echo "Active Jobs:"
          ${concatStringsSep "\n" (mapAttrsToList (name: job: ''
            echo "  ${job.name}:"
            ${if isDarwin then ''
              echo "    LaunchAgent: org.nixos.rsync-${name}"
              if launchctl list | grep -q "org.nixos.rsync-${name}"; then
                echo "    Status: loaded"
              else
                echo "    Status: not loaded"
              fi
            '' else ''
              echo "    Service: rsync-${name}.service"
              echo "    Status: $(systemctl is-active rsync-${name}.service 2>/dev/null || echo "inactive")"
              ${optionalString (job.schedule != null) ''
                echo "    Timer: $(systemctl is-active rsync-${name}.timer 2>/dev/null || echo "inactive")"
                echo "    Next run: $(systemctl list-timers rsync-${name}.timer --no-legend 2>/dev/null | awk '{print $1, $2}' || echo "Not scheduled")"
              ''}
            ''}
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
        ''
      ) ++ (mapAttrsToList (name: job:
        pkgs.writeShellScriptBin "rsync-${name}" (mkRsyncCommand (job // {
          exclude = job.exclude ++ cfg.globalExcludes;
        }))
      ) cfg.jobs);
    }

    # macOS-specific configuration
    (mkIf isDarwin {
      launchd.agents = mapAttrs (name: job:
        mkIf (job.schedule != null) {
          enable = true;
          config = mkLaunchdPlist name job;
        }
      ) cfg.jobs;
    })

    # Linux-specific configuration
    (mkIf (!isDarwin) {
      systemd.tmpfiles.rules = [
        "d ${logDir} 0755 root root -"
      ];
      
      systemd.services = (mapAttrs' (name: job:
        nameValuePair "rsync-${name}" {
          description = "Rsync job: ${job.name}";
          serviceConfig = {
            Type = "oneshot";
            User = job.user;
            Group = job.group;
            Environment = mapAttrsToList (k: v: "${k}=${v}") job.environment;
          };
          script = mkRsyncCommand (job // {
            exclude = job.exclude ++ cfg.globalExcludes;
          });
          path = with pkgs; [ rsync coreutils util-linux ];
        }
      ) cfg.jobs) // (optionalAttrs (cfg.logRetentionDays > 0) {
        # Log cleanup service for Linux
        rsync-log-cleanup = {
          description = "Clean up old rsync logs";
          serviceConfig = {
            Type = "oneshot";
            User = "root";
          };
          script = ''
            find ${logDir} -name "*.log" -mtime +${toString cfg.logRetentionDays} -delete
          '';
        };
      });
      
      systemd.timers = (mapAttrs' (name: job:
        nameValuePair "rsync-${name}" (mkIf (job.schedule != null) {
          description = "Timer for rsync job: ${job.name}";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = job.schedule;
            Persistent = true;
            RandomizedDelaySec = "5m";
          };
        })
      ) cfg.jobs) // (optionalAttrs (cfg.logRetentionDays > 0) {
        rsync-log-cleanup = {
          description = "Timer for rsync log cleanup";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "weekly";
            Persistent = true;
          };
        };
      });
    })
  ]);
}
