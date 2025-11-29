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
    "broadcom-sta"
  ];

  boot = {
    loader = {
      systemd-boot.enable = lib.mkDefault true;
      efi.canTouchEfiVariables = lib.mkDefault true;
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
    extraModulePackages = [
      config.boot.kernelPackages.broadcom_sta
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/8e43a5dd-3348-4c6f-8e7c-b074b22c218a";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/46BD-6C96";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  swapDevices = [
    {
      device = "/dev/disk/by-uuid/d2ee1d17-0cfe-40dc-8c3e-92034b628d62";
    }
  ];

  hardware = {
    enableAllFirmware = lib.mkDefault true;
    enableRedistributableFirmware = lib.mkDefault true;
    graphics.enable = lib.mkDefault true;
    bluetooth.enable = lib.mkDefault true;
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
