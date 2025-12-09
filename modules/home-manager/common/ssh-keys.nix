# This module is deprecated - SSH keys should be managed at the system level
# in individual host configurations using users.users.<name>.openssh.authorizedKeys.keys
{ config, lib, ... }:
{
  # This file intentionally left mostly empty
  # SSH keys are now managed in host configurations
}
