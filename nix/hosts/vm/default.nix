{ ... }: {
  imports = [ ../../profiles/base.nix ];

  system.stateVersion = "25.05";
  networking.hostName = "nixos-vm";

  virtualisation.vmVariant = {
    virtualisation.forwardPorts = [
      { from = "host"; host.port = 2222; guest.port = 22; }
    ];
    virtualisation.memorySize = 2048;
    virtualisation.cores = 2;
  };
}
