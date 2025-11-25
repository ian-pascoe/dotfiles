{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "broadcom-sta-6.30.223.271-59-6.17.8"
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "usb_storage"
      "sd_mod"
      "sr_mod"
      "rtsx_usb_sdmmc"
    ];
    initrd.kernelModules = [ ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [
      "kvm-intel"
      "wl"
    ];
    boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/27f0ba12-7cdc-4daa-8e77-5320e1220bea";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/1347-7610";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  swapDevices = [
    {
      device = "/dev/disk/by-uuid/a4c36db6-ecf9-4c30-8146-0d1183df38c7";
    }
  ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
