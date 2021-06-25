{ stdenvNoCC, fetchurl, newScope, pkgs
, xar, cpio, python3, pbzx }:

let
  MacOSX-SDK = stdenvNoCC.mkDerivation rec {
    pname = "MacOSX-SDK";
    version = "11.0.0";

    # https://swscan.apple.com/content/catalogs/others/index-10.16.merged-1.sucatalog
    src = fetchurl {
      url = "http://swcdn.apple.com/content/downloads/02/62/071-54303-A_EU2CL1YVT7/943i95dpeyi2ghlnj2mgyq3t202t5gf18b/CLTools_macOSNMOS_SDK.pkg";
      sha256 = "ec0e70de35ac8c09868eee0a88b52c1c6992fb3ed825de5e3054c80ea5bb3481";
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
