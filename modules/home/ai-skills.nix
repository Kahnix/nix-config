{ inputs, ... }:
let
  # One canonical root: ~/.agents/skills. Zed reads it directly and OpenCode
  # reads it as a global compatibility path; ai-skills-sync.sh links the same
  # tree into ~/.claude/skills and ~/.gemini/config/skills for Claude Code and
  # Antigravity. Every skill is one direct child, `<name>/SKILL.md`, the
  # layout all four tools understand.
  pack =
    skillsDir: names:
    builtins.listToAttrs (
      map (name: {
        name = ".agents/skills/${name}";
        value = {
          source = "${skillsDir}/${name}";
          force = true;
        };
      }) names
    );
in
{
  flake.modules.homeManager.dev =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      sync = pkgs.writeShellApplication {
        name = "ai-skills-sync";
        runtimeInputs = [ pkgs.coreutils ];
        text = builtins.readFile ./ai-skills-sync.sh;
      };
    in
    {
      # Pinned packs update with `nix flake update`, not `npx skills add`.
      # The vendored skills in ./skills were installed by that CLI and are
      # copied here so every host gets them from the flake.
      home.file =
        pack ./skills [
          "antislop"
          "antislop-code"
          "antislop-copywriting"
          "antislop-human"
          "antislop-layoutmobile"
          "antislop-ui"
          "brandkit"
          "design-taste-frontend-v1"
          "full-output-enforcement"
          "gpt-taste"
          "high-end-visual-design"
          "image-to-code"
          "imagegen-frontend-mobile"
          "imagegen-frontend-web"
          "industrial-brutalist-ui"
          "minimalist-ui"
          "redesign-existing-projects"
          "rex"
          "sandbox-sdk"
          "stitch-design-taste"
        ]
        // pack "${inputs.ponytail}/skills" [
          "ponytail"
          "ponytail-audit"
          "ponytail-debt"
          "ponytail-gain"
          "ponytail-help"
          "ponytail-review"
        ]
        // pack "${inputs.cloudflare-skills}/skills" [
          "agents-sdk"
          "cloudflare"
          "cloudflare-email-service"
          "cloudflare-one"
          "cloudflare-one-migrations"
          "durable-objects"
          "turnstile-spin"
          "web-perf"
          "workers-best-practices"
          "wrangler"
        ]
        // pack "${inputs.supabase-skills}/skills" [
          "supabase"
          "supabase-postgres-best-practices"
        ]
        // pack "${inputs.janestreet-skills}" [
          "socratic-tutor"
        ]
        // pack "${inputs.anti-slop}/skills" [
          "install-anti-slop"
        ]
        // {
          # The repo keeps this skill at a different path than its name.
          ".agents/skills/design-taste-frontend" = {
            source = "${inputs.taste-skill}/skills/taste-skill";
            force = true;
          };
        };

      # Runs after Home Manager has linked ~/.agents/skills, so the links the
      # sync script makes point at store paths that already exist. The home
      # path is passed explicitly because nix-darwin activation does not
      # always export HOME. Also on PATH to pick up ad-hoc skills without a
      # rebuild.
      home.activation.aiSkills = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        run ${sync}/bin/ai-skills-sync ${lib.escapeShellArg config.home.homeDirectory}
      '';
      home.packages = [ sync ];
    };
}
