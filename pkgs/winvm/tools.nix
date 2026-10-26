{ lib }:

# Ordered guest toolchain, installed by guest/provision.ps1 from tools.json.
# Versions and hashes come from the winget-pkgs manifests and nodejs.org
# SHASUMS256.txt. Entry shape:
#   { name, version, type ("msi"|"exe"|"zip"|"bin"), url, sha256, args ? [], okExitCodes ? [ 0 ], bin ? null, addPath ? null }
# type "bin" copies the download to C:\winvm\tools\<name>\<bin> and puts that dir on the Machine PATH;
# type "zip" extracts to C:\winvm\tools\<name> and, with addPath, puts <that>\<addPath> on the Machine PATH.
let
  vsBase = [
    "--quiet"
    "--wait"
    "--norestart"
    "--nocache"
    "--add"
    "Microsoft.VisualStudio.Workload.VCTools"
    "--add"
    "Microsoft.VisualStudio.Component.VC.Tools.x86.x64"
    "--add"
    "Microsoft.VisualStudio.Component.Windows11SDK.26100"
    "--includeRecommended"
  ];

  vs = extraArgs: {
    name = "vs-buildtools";
    version = "17.14.42";
    type = "exe";
    url = "https://download.visualstudio.microsoft.com/download/pr/c95450be-0a45-4779-b142-33f567ccfd6e/68978bb28916156802e60e04c5ee50b94348d802fe151a3ca24433f27984187b/vs_BuildTools.exe";
    sha256 = "68978bb28916156802e60e04c5ee50b94348d802fe151a3ca24433f27984187b";
    args = vsBase ++ extraArgs;
    okExitCodes = [
      0
      3010
    ];
  };

  gitArgs = [
    "/VERYSILENT"
    "/NORESTART"
    "/NOCANCEL"
    "/SP-"
    "/SUPPRESSMSGBOXES"
    "/CLOSEAPPLICATIONS"
    "/o:PathOption=Cmd"
  ];

  # Shared by both arches. The ARM guest runs x64 Node: workerd and bufferutil
  # ship no win32-arm64 binaries. Mirrors vector/.tool-versions.
  nasm = {
    name = "nasm";
    version = "3.02";
    type = "exe";
    url = "https://www.nasm.us/pub/nasm/releasebuilds/3.02/win64/nasm-3.02-installer-x64.exe";
    sha256 = "0DDB40310861EB29F4D649FEB9466779982A2D251C0DB2B9CF0D21CF591171F3";
    args = [ "/S" ];
  };

  node = {
    name = "node";
    version = "22.16.0";
    type = "msi";
    url = "https://nodejs.org/dist/v22.16.0/node-v22.16.0-x64.msi";
    sha256 = "e2f2802202513e1bf41f7c00307635f6c6fe31c0275c1e03d269d45a76e5fc2e";
  };

  # Standalone pnpm.exe: vector's scripts/build.ts spawns "pnpm" without a shell,
  # which cannot start the pnpm.cmd shim that `npm i -g` creates. pnpm 10 honours
  # each repo's packageManager field (manage-package-manager-versions), so this one
  # exe runs 9.15.4 in vector and 10.30.1 in Silentsuite. x64 on both arches,
  # because pnpm picks optional native deps by its own arch and Node is x64.
  pnpm = {
    name = "pnpm";
    version = "10.30.1";
    type = "bin";
    bin = "pnpm.exe";
    url = "https://github.com/pnpm/pnpm/releases/download/v10.30.1/pnpm-win-x64.exe";
    sha256 = "ACA8D8A4ADBCEEB11AA63AF84D12203850B282677FD5BABB09DD15AC194D948F";
  };

  # Silent args for the .NET "burn" bootstrappers.
  burn =
    attrs:
    attrs
    // {
      type = "exe";
      args = [
        "/install"
        "/quiet"
        "/norestart"
      ];
      okExitCodes = [
        0
        3010
      ];
    };

  # Rustdesk-SVC release signing (scripts/windows/connect-artifact-signing.ps1):
  # `az login` + the Artifact Signing dlib loaded by the x64 signtool. Both x64-only.
  azureCli = {
    name = "azure-cli";
    version = "2.91.0";
    type = "msi";
    url = "https://azcliprod.blob.core.windows.net/msi/azure-cli-2.91.0-x64.msi";
    sha256 = "E9F512D127A9BC6C3832B928CCBF04AB9467A199BCA63A1155F9D533CEB9F461";
  };
  signingTools = {
    name = "artifact-signing-client-tools";
    version = "0.1.128";
    type = "msi";
    url = "https://download.microsoft.com/download/a3c24ba9-ff1f-444f-b626-eff710f345c3/ArtifactSigningClientTools.msi";
    sha256 = "93807bb270e63416912faddcecf21e0165fc8eb8ae444b01458c7849679e0e4f";
  };

  # vector-org/proof-of-concept (tauri-discord-poc uses bun.lock). x64 like Node,
  # since bun also resolves optional native deps by its own arch.
  bun = {
    name = "bun";
    version = "1.4.3";
    type = "zip";
    addPath = "bun-windows-x64";
    url = "https://github.com/oven-sh/bun/releases/download/bun-v1.4.3/bun-windows-x64.zip";
    sha256 = "0BF84E808552BEEA67BF1202A287A35C6C825D837B287B3F8E9DD513DBA35D3D";
  };

  rustupArgs = [
    "-y"
    "--default-toolchain"
    "none"
    "--profile"
    "minimal"
  ];
in
{
  # Build scripts and proc-macros compile for the native host, so the ARM guest
  # also gets the ARM64 MSVC tools and the ARM64 LLVM (libclang must match the
  # arch of the build script that loads it). The product is still x86_64.
  arm64 = [
    (vs [
      "--add"
      "Microsoft.VisualStudio.Component.VC.Tools.ARM64"
    ])
    {
      name = "git";
      version = "2.55.0.5";
      type = "exe";
      url = "https://github.com/git-for-windows/git/releases/download/v2.55.0.windows.5/Git-2.55.0.5-arm64.exe";
      sha256 = "C955DE342B1465BC637F0E71FDDF4E28E8D0B829668EC1866AB32A839303E8E3";
      args = gitArgs;
    }
    {
      name = "gh";
      version = "2.103.0";
      type = "msi";
      url = "https://github.com/cli/cli/releases/download/v2.103.0/gh_2.103.0_windows_arm64.msi";
      sha256 = "D6B25481791926E0E5A83F142C73B7DE1E161A9B7AB7D08B6132AD97C0D71E1D";
    }
    {
      name = "llvm";
      version = "23.1.4";
      type = "msi";
      url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-23.1.4/LLVM-23.1.4-woa64.msi";
      sha256 = "B484F54264400F0A75B63704B1068DA8086F0B14625575F6EFEA08813109B068";
    }
    nasm
    # aws-lc-sys (vector) needs CMake when cross-compiling the x64 target from ARM64.
    {
      name = "cmake";
      version = "4.4.4";
      type = "msi";
      url = "https://github.com/Kitware/CMake/releases/download/v4.4.4/cmake-4.4.4-windows-arm64.msi";
      sha256 = "FA7B42F30E0F941F253A6501D9421ECB7656AC311A74975E0A11CAC73067C487";
      args = [ "ADD_CMAKE_TO_PATH=System" ];
    }
    node
    pnpm
    # Rustdesk-SVC (go.mod `go 1.26.0`; builds GOARCH=amd64 explicitly) and the PoC mock.
    {
      name = "go";
      version = "1.26.7";
      type = "msi";
      url = "https://go.dev/dl/go1.26.7.windows-arm64.msi";
      sha256 = "9E915A4071B5C3A39591FE113EB471EF03321EBA159F7E9B647C324AB4EDBFF3";
    }
    # .NET 8: Rustdesk-SVC WiX 7 MSI build (WixToolset.Sdk targets net8.0).
    # .NET 9: vector-sdk CI (setup-dotnet 9.0.101, dotnet format on the Unity plugin).
    (burn {
      name = "dotnet-sdk-8";
      version = "8.0.426";
      url = "https://download.microsoft.com/download/3c7802f1-46b4-47df-855f-52ec7b87612c/e5fc4bb9-f161-4c26-9393-632fec300e52/dotnet-sdk-8.0.426-win-arm64.exe";
      sha256 = "03EB7F3E528324D12274C04A4255D4CEFA7F24901884B7D6874A2E8809FD8B8A";
    })
    (burn {
      name = "dotnet-sdk-9";
      version = "9.0.319";
      url = "https://download.microsoft.com/download/58f6260d-909a-415c-b8b8-fab39f434acd/eb9f5e28-4610-4aae-b2ce-47636d7a5182/dotnet-sdk-9.0.319-win-arm64.exe";
      sha256 = "46F2AFBEE96272952503938ECA73E60EB517EFE6820A786C170DF68DF366621A";
    })
    # The signing dlib is x64 and loads into the x64 signtool, so it needs the x64 runtime.
    (burn {
      name = "dotnet-runtime-8-x64";
      version = "8.0.32";
      url = "https://download.microsoft.com/download/5ab91d2a-50f7-4cc1-a769-534f6d3d45d9/1943d4b5-db8e-465e-bd87-1c356f523e33/dotnet-runtime-8.0.32-win-x64.exe";
      sha256 = "4FBC22376FA60C8255946920FE0D1B93EE526B6956F8B9C9CE6743CF67E08B43";
    })
    azureCli
    signingTools
    bun
    {
      name = "jq";
      version = "1.8.2";
      type = "bin";
      bin = "jq.exe";
      url = "https://github.com/jqlang/jq/releases/download/jq-1.8.2/jq-windows-arm64.exe";
      sha256 = "083B5377392BC57CF27052B6D20A2D927770683BCA844632901FF38B4B7B0AC7";
    }
    {
      name = "rustup";
      version = "1.29.1";
      type = "exe";
      url = "https://static.rust-lang.org/rustup/archive/1.29.1/aarch64-pc-windows-msvc/rustup-init.exe";
      sha256 = "01AA49CF9574A8BD0AE52005D7DE2590E8F27181DED6748236E702C92AEF826D";
      args = rustupArgs;
    }
    {
      name = "syncthing";
      version = "2.1.7";
      type = "zip";
      url = "https://github.com/syncthing/syncthing/releases/download/v2.1.7/syncthing-windows-arm64-v2.1.7.zip";
      sha256 = "D535FFD611B3AF223DE64BC5DFC60C378881EB13D5C8ECB1431B7407094C15FF";
    }
  ];

  amd64 = [
    (vs [ ])
    {
      name = "git";
      version = "2.55.0.5";
      type = "exe";
      url = "https://github.com/git-for-windows/git/releases/download/v2.55.0.windows.5/Git-2.55.0.5-64-bit.exe";
      sha256 = "D065A4E23C3D9A6B5073D609B5BE0830227EC3CA053C083BA385061DDFAF94C6";
      args = gitArgs;
    }
    {
      name = "gh";
      version = "2.103.0";
      type = "msi";
      url = "https://github.com/cli/cli/releases/download/v2.103.0/gh_2.103.0_windows_amd64.msi";
      sha256 = "58A5E6620407F5A74F9C0E4A7DB21AEF2F18C655B5304BF78D2D9F0FEFC7A877";
    }
    {
      name = "llvm";
      version = "23.1.4";
      type = "msi";
      url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-23.1.4/LLVM-23.1.4-win64.msi";
      sha256 = "15E49ACA3540991A6F28A0E57BABAB67DA82155C4F73F79DD5E8666A851F9127";
    }
    nasm
    {
      name = "cmake";
      version = "4.4.4";
      type = "msi";
      url = "https://github.com/Kitware/CMake/releases/download/v4.4.4/cmake-4.4.4-windows-x86_64.msi";
      sha256 = "F7AAC962E8EEA82C0A1C603BB11EE3514806A43A35147D5B1E9D69926FFD7D7E";
      args = [ "ADD_CMAKE_TO_PATH=System" ];
    }
    node
    pnpm
    {
      name = "go";
      version = "1.26.7";
      type = "msi";
      url = "https://go.dev/dl/go1.26.7.windows-amd64.msi";
      sha256 = "C6E7AA52FA607F93E6E3A7E2FFD733782F3BDB2AA8CD0559A6CD9927AEF49C34";
    }
    (burn {
      name = "dotnet-sdk-8";
      version = "8.0.426";
      url = "https://download.microsoft.com/download/3c7802f1-46b4-47df-855f-52ec7b87612c/bc533d26-b454-4b90-beca-a771425dbbcb/dotnet-sdk-8.0.426-win-x64.exe";
      sha256 = "A87B838B4DA772967ACC40F4B9FA37A5AC16A4C89442C383FE4D3C738FFDA58F";
    })
    (burn {
      name = "dotnet-sdk-9";
      version = "9.0.319";
      url = "https://download.microsoft.com/download/58f6260d-909a-415c-b8b8-fab39f434acd/ff700e08-eebf-49bd-a723-ada5ab981ff6/dotnet-sdk-9.0.319-win-x64.exe";
      sha256 = "EBADA4297B0DD91C42A9E757F02F54DB61DAE6730D7651A42A937D34FD56E519";
    })
    azureCli
    signingTools
    bun
    {
      name = "jq";
      version = "1.8.2";
      type = "bin";
      bin = "jq.exe";
      url = "https://github.com/jqlang/jq/releases/download/jq-1.8.2/jq-windows-amd64.exe";
      sha256 = "A6FC67FEDAF9128A3309A1E2EBB8B986AECCF70122EE46D2CB4849E423F0C627";
    }
    {
      name = "rustup";
      version = "1.29.1";
      type = "exe";
      url = "https://static.rust-lang.org/rustup/archive/1.29.1/x86_64-pc-windows-msvc/rustup-init.exe";
      sha256 = "6F4BEF66261261FCB43131BE8720BAB817D403A09EDEC7455C371974B90BDB7E";
      args = rustupArgs;
    }
    {
      name = "syncthing";
      version = "2.1.7";
      type = "zip";
      url = "https://github.com/syncthing/syncthing/releases/download/v2.1.7/syncthing-windows-amd64-v2.1.7.zip";
      sha256 = "3CE7DA770F546A8D02B65B2E7EE31F2A3B8B7C3F990EDE045590CCA4172ECFE1";
    }
  ];
}
