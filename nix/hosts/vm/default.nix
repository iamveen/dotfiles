{ ... }: {
  imports = [ ../../profiles/base.nix ];

  home-manager.users.iamveen = import ../../home/default.nix;

  system.stateVersion = "25.05";
  networking.hostName = "nixos-vm";

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  boot.loader.grub.device = "/dev/vda";

  virtualisation.vmVariant = {
    virtualisation.forwardPorts = [
      { from = "host"; host.port = 2222; guest.port = 22; }
    ];
    virtualisation.memorySize = 2048;
    virtualisation.cores = 2;
  };
}
