{ stdenvNoCC, fetchurl, newScope, pkgs
, xar, cpio, python3, pbzx }:

let
  MacOSX-SDK = stdenvNoCC.mkDerivation rec {
    pname = "MacOSX-SDK";
    version = "11.0.0";

    # https://swscan.apple.com/content/catalogs/others/index-10.16.merged-1.sucatalog
    src = fetchurl {
      url = "http://swcdn.apple.com/content/downloads/50/51/071-29699-A_YC8SX0OHH3/7479xojqghsvgtnt3dxjpnxuz9sjpmbmds/CLTools_macOSNMOS_SDK.pkg";
      sha256 = "6faff385985c1dad1bfc4eb24bc83b779ff5ac8ebbd5055c9c6381386048df2d";
    };

    dontBuild = true;
    darwinDontCodeSign = true;

    nativeBuildInputs = [ cpio pbzx ];

    outputs = [ "out" ];

    unpackPhase = ''
      pbzx $src | cpio -idm
    '';

    installPhase = ''
      cd Library/Developer/CommandLineTools/SDKs/MacOSX11.0.sdk

      mkdir $out
      cp -r System usr $out/
    '';

    passthru = {
      inherit version;
    };
  };

  callPackage = newScope (packages // pkgs.darwin // { inherit MacOSX-SDK; });

  packages = {
    inherit (callPackage ./apple_sdk.nix {}) frameworks libs;

    # TODO: this is nice to be private. is it worth the callPackage above?
    # Probably, I don't think that callPackage costs much at all.
    inherit MacOSX-SDK;

    Libsystem = callPackage ./libSystem.nix {};
    LibsystemCross = pkgs.darwin.Libsystem;
    libcharset = callPackage ./libcharset.nix {};
    libunwind = callPackage ./libunwind.nix {};
    libnetwork = callPackage ./libnetwork.nix {};
    objc4 = callPackage ./libobjc.nix {};

    # questionable aliases
    configd = pkgs.darwin.apple_sdk.frameworks.SystemConfiguration;
    IOKit = pkgs.darwin.apple_sdk.frameworks.IOKit;
  };
in packages
