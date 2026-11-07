{ inputs, lib, ... }:
{
  # Mitos modal text editor (Helix fork) alongside Helix (hx stays EDITOR).
  # Reuses Helix's settings, languages, themes, and extraPackages by default,
  # migrating config keys to Mitos's canonical schema and validating at build time.
  flake.modules.homeManager.dev =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      cfg = config.programs.mitos;
      tomlFormat = pkgs.formats.toml { };

      mergeNamedList =
        base: extra:
        let
          extraByName = lib.listToAttrs (map (item: lib.nameValuePair item.name item) extra);
          mergedExisting = map (
            item: if extraByName ? ${item.name} then lib.recursiveUpdate item extraByName.${item.name} else item
          ) base;
          existingNames = map (item: item.name) base;
          newItems = builtins.filter (item: !(builtins.elem item.name existingNames)) extra;
        in
        mergedExisting ++ newItems;

      hasSettings = (config.programs.helix.settings != { }) || (cfg.settings != { });

      mergedLanguages =
        (lib.recursiveUpdate config.programs.helix.languages cfg.languages)
        // lib.optionalAttrs ((config.programs.helix.languages ? language) || (cfg.languages ? language)) {
          language = mergeNamedList (config.programs.helix.languages.language or [ ]) (
            cfg.languages.language or [ ]
          );
        };

      isPlainAttrs = v: builtins.isAttrs v && !(lib.isDerivation v);

      mergedThemes =
        config.programs.helix.themes
        // lib.mapAttrs (
          name: value:
          if
            (config.programs.helix.themes ? ${name})
            && isPlainAttrs config.programs.helix.themes.${name}
            && isPlainAttrs value
          then
            lib.recursiveUpdate config.programs.helix.themes.${name} value
          else
            value
        ) cfg.themes;

      renderThemeFile =
        name: value:
        if builtins.isPath value || lib.isDerivation value || lib.isStorePath value then
          { source = value; }
        else if builtins.isString value then
          { text = value; }
        else
          { source = tomlFormat.generate "mitos-theme-${name}.toml" value; };

      finalPackage = pkgs.symlinkJoin {
        name = "mitos";
        paths = [ cfg.package ];
        nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
        postBuild =
          lib.optionalString (cfg.extraPackages != [ ]) ''
            wrapProgram "$out/bin/ms" \
              --suffix PATH : ${lib.makeBinPath cfg.extraPackages}
          ''
          + ''
            if [ -e "$out/bin/ms" ] && [ ! -e "$out/bin/mitos" ]; then
              ln -s "$out/bin/ms" "$out/bin/mitos"
            fi
          '';
        meta.mainProgram = "ms";
      };

      mitosConfigFile =
        let
          baseToml = tomlFormat.generate "mitos-base-config.toml" config.programs.helix.settings;
          overrideToml = tomlFormat.generate "mitos-override-config.toml" cfg.settings;
        in
        pkgs.runCommandLocal "mitos-config.toml"
          {
            nativeBuildInputs = [
              cfg.package
            ]
            ++ lib.optionals (cfg.settings != { }) [
              pkgs.jq
              pkgs.remarshal
            ];
          }
          (
            ''
              export HOME="$TMPDIR"
              export MITOS_CONFIG_DIR="$TMPDIR/mitos"
              mkdir -p "$MITOS_CONFIG_DIR"
            ''
            + (
              if cfg.settings == { } then
                ''
                  ms --migrate-config ${baseToml} --stdout > "$out"
                ''
              else
                ''
                  ms --migrate-config ${baseToml} --stdout > "$TMPDIR/base.toml"
                  ms --migrate-config ${overrideToml} --stdout > "$TMPDIR/override.toml"
                  jq -s '.[0] * .[1]' \
                    <(toml2json "$TMPDIR/base.toml") \
                    <(toml2json "$TMPDIR/override.toml") \
                    | json2toml - "$out"
                ''
            )
            + ''
              health_out="$(ms -c "$out" --health clipboard)"
              if printf '%s\n' "$health_out" | grep -q "Configuration file malformed"; then
                printf '%s\n' "$health_out" >&2
                exit 1
              fi
            ''
          );

      mitosLanguagesFile =
        let
          rawLanguagesToml = tomlFormat.generate "mitos-raw-languages.toml" mergedLanguages;
        in
        pkgs.runCommandLocal "mitos-languages.toml"
          {
            nativeBuildInputs = [ cfg.package ];
          }
          ''
            export HOME="$TMPDIR"
            export MITOS_CONFIG_DIR="$TMPDIR/mitos"
            mkdir -p "$MITOS_CONFIG_DIR"
            cp ${rawLanguagesToml} "$MITOS_CONFIG_DIR/languages.toml"
            health_err="$(ms --health languages 2>&1 >/dev/null)"
            if [ -n "$health_err" ]; then
              printf '%s\n' "$health_err" >&2
              exit 1
            fi
            cp ${rawLanguagesToml} "$out"
          '';
    in
    {
      options.programs.mitos = {
        enable = lib.mkEnableOption "Mitos modal text editor" // {
          default = true;
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = inputs.mitos.packages.${system}.mitos;
          description = "Base Mitos package to wrap and install.";
        };

        finalPackage = lib.mkOption {
          type = lib.types.package;
          readOnly = true;
          default = finalPackage;
          description = "Wrapped Mitos package with extraPackages on PATH and the `mitos` alias.";
        };

        extraPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = config.programs.helix.extraPackages;
          description = "Extra packages (LSPs, formatters, debuggers) added to Mitos's PATH.";
        };

        defaultEditor = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to set EDITOR and VISUAL to `ms`.";
        };

        settings = lib.mkOption {
          type = tomlFormat.type;
          default = { };
          description = "Mitos overrides merged onto Helix's `settings` after schema migration.";
        };

        languages = lib.mkOption {
          type = tomlFormat.type;
          default = { };
          description = "Mitos language overrides merged onto Helix's `languages`.";
        };

        themes = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.either tomlFormat.type (lib.types.either lib.types.lines lib.types.path)
          );
          default = { };
          description = "Mitos theme definitions merged onto Helix's `themes`.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.finalPackage ];

        home.sessionVariables = lib.mkIf cfg.defaultEditor {
          EDITOR = "ms";
          VISUAL = "ms";
        };

        xdg.configFile = {
          "mitos/config.toml" = lib.mkIf hasSettings {
            source = mitosConfigFile;
          };
          "mitos/languages.toml" = lib.mkIf (mergedLanguages != { }) {
            source = mitosLanguagesFile;
          };
        }
        // lib.mapAttrs' (
          name: value: lib.nameValuePair "mitos/themes/${name}.toml" (renderThemeFile name value)
        ) mergedThemes;

        programs.fish.interactiveShellInit = lib.mkAfter ''
          if command -sq ms
            complete -c mitos -w ms
          end
        '';
      };
    };

  perSystem =
    { pkgs, system, ... }:
    lib.mkIf (inputs.mitos.packages ? ${system}) {
      packages.mitos = pkgs.symlinkJoin {
        name = "mitos";
        paths = [ inputs.mitos.packages.${system}.mitos ];
        postBuild = ''
          if [ -e "$out/bin/ms" ] && [ ! -e "$out/bin/mitos" ]; then
            ln -s "$out/bin/ms" "$out/bin/mitos"
          fi
        '';
        meta.mainProgram = "ms";
      };
    };
}
