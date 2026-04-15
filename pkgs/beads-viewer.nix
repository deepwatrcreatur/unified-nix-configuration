# pkgs/beads-viewer.nix
# beads_viewer (bv) — terminal UI and robot-triage CLI for the Beads issue tracker
# https://github.com/Dicklesworthstone/beads_viewer
{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule {
  pname = "beads-viewer";
  version = "0.15.2";

  src = fetchFromGitHub {
    owner = "Dicklesworthstone";
    repo = "beads_viewer";
    rev = "02ec2b741510ccb65c4910ba6c8ee707ebc898fa";
    hash = "sha256-WlZhzycf02s1tHMrr7CE4B1OFSiSLbp45WoZd+1ZIqE=";
  };

  # Repo ships a vendor/ directory; no network fetch needed.
  vendorHash = null;

  subPackages = [ "cmd/bv" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/Dicklesworthstone/beads_viewer/pkg/version.version=v0.15.2"
  ];

  meta = {
    description = "Terminal UI and robot-triage engine for the Beads issue tracker";
    longDescription = ''
      bv provides a rich terminal UI on top of a .beads/ store and exposes
      graph-aware prioritization via --robot-triage.  PageRank and
      critical-path scores let agents pick "what to do next" without
      relying on manually ranked queues.

      Key commands:
        bv                          — interactive TUI
        bv --robot-triage --json    — JSON priority list for agents
        bv --robot-triage --labels tooling  — filter to a label
    '';
    homepage = "https://github.com/Dicklesworthstone/beads_viewer";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "bv";
  };
}
