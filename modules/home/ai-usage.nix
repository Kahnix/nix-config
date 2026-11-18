{ inputs, ... }:
let
  # Real plan quotas for Claude, Antigravity, and OpenCode Go, read with the
  # logins those tools already have. One tool drives every surface: the macOS
  # menu bar, the Noctalia bar, and a TUI/CLI for headless hosts.
  version = "1.52.2";

  # macOS: the signed release bundle, which is the only build that ships the
  # menu-bar app (AI Usage.app). CLI and TUI come from the same archive so all
  # three stay on one version. Bump `version` and the hash together.
  darwinBundle =
    pkgs:
    pkgs.stdenvNoCC.mkDerivation {
      pname = "ai-usagebar";
      inherit version;
      src = pkgs.fetchurl {
        url = "https://github.com/akitaonrails/ai-usagebar/releases/download/v${version}/ai-usagebar-macos-aarch64.tar.gz";
        sha256 = "ffa70d0e4a7be4ddbe684c84eaced1d816fdd17c82bfff1e53176b8bd5663d62";
      };
      sourceRoot = ".";
      # Re-signing or stripping would break the bundle's code signature,
      # which the Keychain checks before handing over Claude's credentials.
      dontFixup = true;
      installPhase = ''
        mkdir -p $out/bin $out/Applications
        cp ai-usagebar ai-usagebar-tui $out/bin/
        cp -R "AI Usage.app" $out/Applications/
      '';
    };

  package =
    pkgs:
    if pkgs.stdenv.hostPlatform.isDarwin then
      darwinBundle pkgs
    else
      inputs.ai-usagebar.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  flake.modules.homeManager.ai-usage =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Only the three services in use; the rest default to on and would show
      # credential errors.
      settings = {
        anthropic.enabled = true;
        antigravity.enabled = true;
        opencode-go.enabled = true;
        openai.enabled = false;
        copilot.enabled = false;
        zai.enabled = false;
        openrouter.enabled = false;
      };
      configFile = (pkgs.formats.toml { }).generate "ai-usagebar.toml" settings;
      target = "${config.xdg.configHome}/ai-usagebar/config.toml";
    in
    {
      home.packages = [ (package pkgs) ];

      # `usage` in any shell; `ai-usagebar-tui` for the tabbed view over SSH.
      programs.fish.shellAliases.usage = "ai-usagebar usage";

      # A real file, not a store symlink: the tray's Settings window saves
      # into it. Each switch resets it to the values above, so make lasting
      # changes here.
      home.activation.aiUsagebarConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "$(dirname ${lib.escapeShellArg target})"
        run install -m 600 ${configFile} ${lib.escapeShellArg target}
      '';
    };

  # Menu-bar app, started at login. copyApps puts it in
  # ~/Applications/Home Manager Apps, which gives it a stable path for the
  # Keychain and menu-bar managers. Leave the app's own "Start at Login" off,
  # or it starts twice.
  flake.modules.homeManager.darwin-desktop =
    { config, ... }:
    {
      launchd.agents.ai-usagebar-tray = {
        enable = true;
        config = {
          ProgramArguments = [
            "/usr/bin/open"
            "-g"
            "${config.home.homeDirectory}/Applications/Home Manager Apps/AI Usage.app"
          ];
          RunAtLoad = true;
        };
      };
    };
}
