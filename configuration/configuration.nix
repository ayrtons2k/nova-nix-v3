#REFERENCE CONFIG


{ config, pkgs, self, ... }:
let
  # Fetch the Steven Black hosts file.
  stevenBlackHosts = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
    sha256 = "sha256:0mlx9l8k3mmx41hrlmqk6bibz8fvg6xzzpazkfizkc8ivw2nrgb7";
  };

in
{
  #--- LABEL ----------------------------------------------------------------
  system.nixos.label = "V3";
  #--------------------------------------------------------------------------
  
  imports = [ 
    ./hardware-configuration.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  hardware = {

    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = false;
      open = false;  # Use proprietary drivers
      nvidiaSettings = true;
      #package = config.boot.kernelPackages.nvidiaPackages.beta;
      #package = config.boot.kernelPackages.nvidiaPackages.latest;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      #package = config.boot.kernelPackages.nvidiaPackages.production;
    };

    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        "D6:B9:E9:7A:65:A5" = {
          name = "MX Master 3";
          trusted = "yes";
          paired = "yes";
          auto-connect = "yes";
        };
      };
    };
  
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        linuxPackages.nvidia_x11
        libGLU
        libGL
        cudatoolkit
        gperf
      ];
    };
  };

  # In your configuration.nix

  # This is the correct way to define the service inside configuration.nix
  systemd.user.services.cliphist-daemon = {
    # 'Unit' options are now top-level
    description = "Clipboard History Daemon (cliphist)";
    after = [ "graphical-session-pre.target" ];
    partOf = [ "graphical-session.target" ];

    # 'Install' options are now top-level
    wantedBy = [ "graphical-session.target" ];

    # 'Service' options go into the 'serviceConfig' block,
    # and the main command goes in the 'script'.
    script = ''
      # The script block gives us a clean shell to run our command
      ${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store
    '';

    serviceConfig = {
      Restart = "on-failure";
    };
  }; 

  nixpkgs.config = {
    allowUnfree = true;
    config = {
      allowUnfreePredicate = (_: true);
    };
  };

  # networking.extraHosts takes a string and appends it to /etc/hosts.
  # We read the file we just fetched and use its content.
  networking = {
    extraHosts = builtins.readFile stevenBlackHosts;  
    hostName = "nova-nix";
    networkmanager.enable = true;
    nameservers = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
  };

  # Bootloader
  boot = {
    extraModulePackages = [ config.boot.kernelPackages.nvidiaPackages.stable ];
    loader = {
      systemd-boot = {
        enable = true;
        #configurationLimit = 7;

      };
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_6_12;
    kernelParams = [
      "nvidia_drm.modeset=1"
    ];    
  };

  services = {

    xserver.videoDrivers = [ "nvidia" ];

    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      
      # settings = {
      #   Autologin = {
      #     Session = "hyprland.desktop";
      #   };
      # };
      sugarCandyNix = {
       enable = true;
        # Point this to your actual wallpaper path
        settings = {
          # Set your configuration options here.
          # Here is a simple example:
          #Background = lib.cleanSource ./background.png;
          ScreenWidth = 5120;
          ScreenHeight = 1440;
          FormPosition = "left";
          HaveFormBackground = true;
          PartialBlur = true;
        };
      };
    };  
    
  
    gnome.gnome-keyring.enable = true;
    openssh.enable = true;

    pulseaudio.enable = false;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };


    # ollama.enable = true;
    # open-webui = {
    #   enable = true;
    #   environment.OLLAMA_API_BASE_URL = "http://localhost:11434";
    # };

    resolved = {
      enable = true;
      dnssec = "true";
      domains = [ "~." ];
      fallbackDns = [
        "9.9.9.9#dns.quad9.net" # Quad9 as a fallback
        "8.8.8.8#dns.google"   # Google as a fallback
      ];
    };

      # Stubby DNS over TLS
      # It uses Cloudflare's DNS servers with DNSSEC validation.
      # You can customize the upstream servers and settings as needed.
      # For more information, see:  https://nixos.wiki/wiki/Encrypted_DNS
    stubby = {
      enable = true;
      settings = pkgs.stubby.passthru.settingsExample // {
        upstream_recursive_servers = [{
          address_data = "1.1.1.1";
          tls_auth_name = "cloudflare-dns.com";
          tls_pubkey_pinset = [{
            digest = "sha256";
            value = "GP8Knf7qBae+aIfythytMbYnL+yowaWVeD6MoLHkVRg=";
          }];
        } {
          address_data = "1.0.0.1";
          tls_auth_name = "cloudflare-dns.com";
          tls_pubkey_pinset = [{
            digest = "sha256";
            value = "GP8Knf7qBae+aIfythytMbYnL+yowaWVeD6MoLHkVRg=";
          }];
        }];
      };
    };
  };
 
  time.timeZone = "America/New_York";
 
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  programs = {
    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = "/home/ayrton/nova-nix-config";
    };

    hyprland = {
      enable = true; # Set to true if you want to use Hyprland instead of Sway
    };


    firefox = {
      enable = true;
      package = pkgs.firefox;
      nativeMessagingHosts.packages = [ pkgs.firefoxpwa ];
    };
    
    ssh.startAgent = true;

    git.config = {
      init.defaultBranch = "main";
      url."https://github.com/".insteadOf = [ "gh:" "github:" ];
    };

    # Nix-LD for compatibility
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        alsa-lib
        at-spi2-atk
        at-spi2-core
        atk
        cairo
        cups
        curl
        dbus
        expat
        fontconfig
        freetype
        fuse3
        gdk-pixbuf
        glib
        gtk3
        icu
        libGL
        libappindicator-gtk3
        libdrm
        libglvnd
        libnotify
        #libpulseaudiofontconfig
        libunwind
        libusb1
        libuuid
        libxkbcommon
        libxml2
        mesa
        nspr
        nss
        openssl
        pango
        pipewire
        stdenv.cc.cc
        systemd
        microsoft-edge
        vulkan-loader
        xorg.libX11
        xorg.libXScrnSaver
        xorg.libXcomposite
        xorg.libXcursor
        xorg.libXdamage
        xorg.libXext
        xorg.libXfixes
        xorg.libXi
        xorg.libXrandr
        xorg.libXrender
        xorg.libXtst
        xorg.libxcb
        xorg.libxkbfile
        xorg.libxshmfence
        zlib
        libsecret
      ];
    };
  };
  # Enable Bluetooth
  
  # User configuration
  users.users.ayrton = {
    isNormalUser = true;
    description  = "ayrton";
    extraGroups  = [ "networkmanager" "wheel" ];
    packages     = with pkgs; [
      kdePackages.kate
      git
    ];
  };
  # This enables the daemon that talks to the YubiKey hardware
  #services.pcscd.enable = true;
  security = {
    rtkit.enable = true;
    pam.services.sddm.enableGnomeKeyring = true;
    pam.services.swaylock = {
      text = "auth include login";
    };  

    pam = {
      u2f = {
        enable = true;
        control = "sufficient"; # This means the key is SUFFICIENT for auth.
        settings = {
          cue = true;             # Prints "Please touch the device."
          authFile = "/home/ayrton/.config/Yubico/u2f_keys"; # Path to your Yubikey key file};
        };
      };
      services =  {
    # This enables U2F/Passkey authentication for the 'sudo' service
        login.u2fAuth = true;
        sudo.u2fAuth = true;
        u2f.enable = true;
      };       
    };
  }; 

  services.udev.packages = [ pkgs.libu2f-host ];
  environment = {
    #Variables used by Hyprland
    
    sessionVariables = {
      LIBVA_DRIVER_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      NIXOS_OZONE_WL = "1"; # Hint for Electron apps to use Wayland
      WLR_NO_HARDWARE_CURSORS = "1";
      HYPRCURSOR_THEME = "Future-Cyan";
      HYPRCURSOR_SIZE = "24";
   };    
    systemPackages = with pkgs; [
      git
      lnav 
      # rofi  
      wofi # Wayland-native replacement for Rofi
      mako # Wayland-native notification daemon
      swaybg # Sway's own background/wallpaper tool
      wdisplays # Wayland-native display configuration tool
      grim # Wayland screenshot tool
      slurp # Wayland region selection tool (used with grim)
      pavucontrol
      nwg-look # GTK theme configuration for Wayland
      networkmanagerapplet
      blueman
      wl-clipboard # Provides wl-copy/wl-paste for the command line
      hyprpaper # Wallpaper daemon for Hyprland
      hyprlock # The native screen locker
      kdePackages.qtsvg
      kdePackages.dolphin
      pam_u2f
      peazip
      nix-output-monitor
      nvd
    ];
  };

   programs.thunar = {
    enable = true;
  };


  # Font configuration
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      #nerdfonts
      dejavu_fonts
      font-awesome
      liberation_ttf
      fira-code
      roboto
    ]++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

    fontconfig = {
      enable = true;
      antialias = true;
      hinting = {
        enable = true;
        style = "none";  # Options: "none", "slight", "medium", "full"'. 
      };
      subpixel = {
        rgba = "rgb";  # Options: none, rgb, bgr, vrgb, vbgr
        lcdfilter = "default";  # Options: none, default, light, legacy
      };
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [ "Fira Code" ];
      };
    };
  };
  #https://github.com/nix-community/NUR
  /*
    The Nix User Repository (NUR) is a community-driven meta repository for Nix packages. 
    It provides access to user repositories that contain package descriptions (Nix expressions) 
    and allows you to install packages by referencing them via attributes. In contrast to Nixpkgs, 
    packages are built from source and are not reviewed by any Nixpkgs member.  
  */
  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/main.tar.gz") {
      inherit pkgs;
    };
  };
     
  system.stateVersion = "25.05";
}
