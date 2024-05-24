{ config, lib, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
      (import ./disko.nix { device = "/dev/vda"; } )
    ];
  
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.postDeviceCommands = lib.mkAfter ''
    mkdir /btrfs_tmp
    mount /dev/root_vg/root /btrfs_tmp
    if [[ -e /btrfs_tmp/root ]]; then
        mkdir -p /btrfs_tmp/old_roots
        timestamp = $(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
        mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
    fi

    delete_subvolume_recursively() {
       IFS=$'\n'
       for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
           delete_subvolume_recursively "/btrfs_tmp/$i"
       done
       btrfs subvolume delete "$1"
    }

    for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +15); do
        delete_subvolume_recursively "$i"
    done 

    btrfs subvolume create /btrfs_tmp/root
    umount /btrfs_tmp
  '';

  nix.settings.experimental-features = ["nix-command" "flakes"];

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Kolkata";

  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver.enable = true;

  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "";

  services.xserver.videoDrivers = [ "qxl" ];

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable OpenGL and QXL Video Driver
  hardware.opengl.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users."rishab" = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "1234";
    shell = pkgs.zsh;
  };

  environment.systemPackages = with pkgs; [
    vim
    git
    kitty
    sl
    spice-gtk
    spice-vdagent
    firefox 
    wget
    awesome
    libsForQt5.sddm
  ];
  programs.zsh.enable = true;

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "23.11"; # DONT CHANGE THIS
}

