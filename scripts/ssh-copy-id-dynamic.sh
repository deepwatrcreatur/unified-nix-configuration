#!/usr/bin/env bash
# Wrapper for ssh-copy-id that uses authorized_keys_dynamic
# Usage: ssh-copy-id-dynamic [ssh-copy-id options] user@host

ssh-copy-id -t .ssh/authorized_keys_dynamic "$@"
