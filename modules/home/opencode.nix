{ inputs, ... }:
{
  # OpenCode: the global config and the advisor agent are generated so every
  # host (NixOS/Wayland desktop and the MacBook) runs the same setup.
  flake.modules.homeManager.opencode =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Pinned: a rebuild must not silently upgrade the MCP servers.
      desktopCommander = "@wonderwhy-er/desktop-commander@0.3.3";
      applescriptMcp = "applescript-mcp@2.3.2";

      # npx runs with its own user-owned cache: the default ~/.npm can contain
      # root-owned entries (any past `sudo npm` run) that make installs fail
      # with EACCES. Harmless on machines with a clean ~/.npm.
      npmCache = "${config.home.homeDirectory}/.cache/npm";

      settings = {
        "$schema" = "https://opencode.ai/config.json";

        # Cheap, fast default for new sessions. Escalate per session with
        # /models: claude-agent/sonnet, claude-agent/opus, #high/#max variants.
        model = "opencode-go/deepseek-v4.1-flash";

        # Keep the provider prompt cache alive while a session idles, so the
        # next prompt does not repay the full context. Small token cost per
        # keep-alive request.
        warming = true;

        # Compaction summaries run on the cheapest Claude model instead of
        # the session model. Falls back to the session model on machines
        # where the claude-agent login is missing.
        agents.compaction.model = "claude-agent/haiku";

        # The base policy allows every shell command; these rails pause the
        # destructive ones for approval. Answer "allow always" once and the
        # rule is saved per project when a rail gets noisy.
        permissions = [
          {
            action = "shell";
            resource = "git push *";
            effect = "ask";
          }
          {
            action = "shell";
            resource = "git clean *";
            effect = "ask";
          }
          {
            action = "shell";
            resource = "git reset --hard *";
            effect = "ask";
          }
          {
            action = "shell";
            resource = "rm -rf *";
            effect = "ask";
          }
          {
            action = "shell";
            resource = "rm -fr *";
            effect = "ask";
          }
          {
            action = "shell";
            resource = "sudo *";
            effect = "ask";
          }
          {
            action = "shell";
            resource = "nixos-rebuild *";
            effect = "ask";
          }
          {
            action = "shell";
            resource = "nh os switch *";
            effect = "ask";
          }
          {
            action = "shell";
            resource = "darwin-rebuild *";
            effect = "ask";
          }
          {
            action = "shell";
            resource = "nh darwin switch *";
            effect = "ask";
          }
        ];

        mcp.servers = {
          # Computer use, terminal half: persistent shell sessions, file
          # operations, process management. Works on both hosts;
          # --no-onboarding stops the first-run browser popup and prompts.
          # npx resolves the pinned package; the first start per machine
          # downloads it into the npm cache above.
          "desktop-commander" = {
            type = "local";
            command = [
              "npx"
              "-y"
              desktopCommander
              "--no-onboarding"
            ];
            pool = true;
            environment.npm_config_cache = npmCache;
          };
        }
        # macOS-only extras: applescript-mcp automates native apps (Finder,
        # System Settings, Notes, ...). browse drives the user's real
        # Chrome: tabs, sign-ins, handoff. On NixOS neither applies; the
        # host's ydotool daemon covers Wayland input injection instead.
        # browse's binary is installed outside nix, so it stays macOS-only
        # until it is packaged.
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          applescript-mcp = {
            type = "local";
            command = [
              "npx"
              "-y"
              applescriptMcp
            ];
            pool = true;
            environment.npm_config_cache = npmCache;
          };

          browse = {
            type = "local";
            command = [
              "${config.home.homeDirectory}/.local/bin/browse"
              "mcp"
            ];
            cwd = config.home.homeDirectory;
            pool = true;
            environment.OPENCODE_BROWSER_RUNTIME = "auto-update";
          };
        };
      };
    in
    {
      # Read-only store symlinks: edit this module, not ~/.config/opencode.
      # The hand-managed cli.json (TUI preferences), plugins/, and skills/
      # are left alone. Auth logins are per machine and not reproducible:
      # run `opencode auth login` once on each host.
      xdg.configFile."opencode/opencode.jsonc".source =
        (pkgs.formats.json { }).generate "opencode.jsonc"
          settings;

      xdg.configFile."opencode/agents/advisor.md".text = ''
        ---
        description: Read-only second opinion on plans and diffs; never edits anything
        mode: all
        model: claude-agent/sonnet
        permissions:
          - action: edit
            resource: "*"
            effect: deny
          - action: subagent
            resource: "*"
            effect: deny
        ---

        You are an advisor, not an implementer. You do not edit files and you
        do not launch other agents. Run read-only commands (git diff, git log,
        ls, cat) to see the real state instead of trusting the description you
        were given.

        For a plan, answer in this order:
        1. What breaks: the failure modes, worst first, each with where it lives.
        2. What is missing: requirements and edge cases the plan ignores.
        3. What is simpler: a cheaper path to the same result, if one exists.

        For a diff, answer in this order:
        1. Correctness: does it do what it claims?
        2. Regressions: what working behavior changes?
        3. Tests: which changed paths lost or lack coverage?

        If the work is sound and low-risk, say exactly that and stop. Do not
        invent objections to seem thorough. Keep every answer under 20 lines
        unless asked for more.
      '';
    };
}
