
	{ config, pkgs, ... }:
	
	{
	  home.packages = with pkgs; [
	    nodejs # Ensure nodejs is available
	    # Directly use the globalPackages of npm.
	    # This assumes 'npm' as provided by 'nodejs' package is sufficient.
	    pkgs.npm.globalPackages.gemini-cli
	  ];
	}
