{ inputs, ... }:
{
  # Unified AI usage view: OpenCode, Claude Code, and Antigravity, read from
  # the local data each harness already writes, so it works offline on every
  # host. `ai-usage` (fish alias: `usage`).
  flake.modules.homeManager.ai-usage =
    { pkgs, ... }:
    let
      # Pinned so a rebuild never silently changes the accounting tool.
      ccusage = "ccusage@20.0.51";

      # npx runs with its own user-owned cache: ~/.npm can contain root-owned
      # entries (any past `sudo npm` run) that make installs fail with EACCES.
      aiUsage = pkgs.writeShellApplication {
        name = "ai-usage";
        runtimeInputs = [
          pkgs.jq
          pkgs.nodejs # npx
        ];
        text = ''
          set -euo pipefail
          export npm_config_cache="''${HOME}/.cache/npm"

          # OpenCode Go subscription limits, from the running background server.
          openCodeQuota() {
            command -v opencode >/dev/null 2>&1 || return 0
            opencode api get /api/experimental/usage/limits 2>/dev/null | jq -r '
              .data.go | "OpenCode Go quota: rolling \(.rolling.percent)%  weekly \(.weekly.percent)%  monthly \(.monthly.percent)%"'
          }

          case "''${1:-all}" in
            all)
              # Today across every harness, then quotas and the active
              # Claude billing block with its burn-rate projection.
              npx -y ${ccusage} daily --last 1
              echo
              openCodeQuota || true
              npx -y ${ccusage} blocks --active
              ;;
            quota)
              openCodeQuota || true
              npx -y ${ccusage} blocks --active
              npx -y ${ccusage} antigravity daily --last 1
              ;;
            claude | opencode | antigravity)
              npx -y ${ccusage} "''${1}" daily --last 1
              ;;
            statusline)
              # Compact one-liner for a bar or tmux status; recomputed at most
              # every 15 minutes, served from cache in between.
              cache="''${XDG_CACHE_HOME:-''${HOME}/.cache}/ai-usage/statusline"
              mkdir -p "$(dirname "$cache")"
              if [ -f "$cache" ] && find "$cache" -mmin -15 | grep -q .; then
                cat "$cache"
                exit 0
              fi
              quota=""
              if command -v opencode >/dev/null 2>&1; then
                quota=$(opencode api get /api/experimental/usage/limits 2>/dev/null \
                  | jq -r '.data.go | "\(.weekly.percent)%w/\(.monthly.percent)%m"' || true)
              fi
              occost=$(npx -y ${ccusage} opencode daily --last 1 --json 2>/dev/null \
                | jq -r '((.totals.totalCost*100|round)/100 | tostring)' || true)
              cccost=$(npx -y ${ccusage} claude daily --last 1 --json 2>/dev/null \
                | jq -r '((.totals.totalCost*100|round)/100 | tostring)' || true)
              agycost=$(npx -y ${ccusage} antigravity daily --last 1 --json 2>/dev/null \
                | jq -r '((.totals.totalCost*100|round)/100 | tostring)' || true)
              parts=()
              if [ -n "$quota" ]; then parts+=("OC $quota \$$occost"); fi
              if [ -n "$cccost" ]; then parts+=("CC \$$cccost"); fi
              if [ -n "$agycost" ]; then parts+=("AGY \$$agycost"); fi
              line=$(IFS=' · '; echo "''${parts[*]}")
              printf '%s\n' "$line" > "$cache"
              cat "$cache"
              ;;
            *)
              echo "usage: ai-usage [all|quota|claude|opencode|antigravity|statusline]" >&2
              exit 1
              ;;
          esac
        '';
      };
    in
    {
      config.home.packages = [ aiUsage ];

      # One word in any shell on any host.
      config.programs.fish.shellAliases.usage = "ai-usage";
    };
}
