{ ... }: {
  system.stateVersion = "25.05";

  networking.hostName = "nixos-vm";

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
  networking.firewall.allowedTCPPorts = [ 22 ];

  virtualisation.vmVariant = {
    virtualisation.forwardPorts = [
      { from = "host"; host.port = 2222; guest.port = 22; }
    ];
    virtualisation.memorySize = 2048;
    virtualisation.cores = 2;
  };

  users.users.iamveen = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKHH7BNzLFwTQBWPNH0gZBYsTUOKxYpg7/mDP58rIxI+"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
}
