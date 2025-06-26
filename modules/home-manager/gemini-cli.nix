
	{ config, pkgs, ... }:
	
	{
	  home.packages = with pkgs; [
	    nodejs # Ensure nodejs is available
	    nodePackages."@google/gemini-cli"
	  ];
	}
