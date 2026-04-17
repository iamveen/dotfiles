{ ... }: {
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
  networking.firewall.allowedTCPPorts = [ 22 ];

  users.users.iamveen = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKHH7BNzLFwTQBWPNH0gZBYsTUOKxYpg7/mDP58rIxI+"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
}
