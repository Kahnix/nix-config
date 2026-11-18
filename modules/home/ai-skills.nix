{ inputs, ... }:
let
  ponytailSkills = [
    "ponytail"
    "ponytail-audit"
    "ponytail-debt"
    "ponytail-gain"
    "ponytail-help"
    "ponytail-review"
  ];

  # Link each skill individually so ad-hoc `npx skills add` can still write to the parent dirs.
  mkSkillLinks =
    sourceDir: names: targetDirs:
    builtins.listToAttrs (
      builtins.concatMap (
        name:
        map (dir: {
          name = "${dir}/${name}";
          value = {
            source = "${sourceDir}/${name}";
            force = true;
          };
        }) targetDirs
      ) names
    );
in
{
  flake.modules.homeManager.dev =
    { ... }:
    {
      home.file = mkSkillLinks "${inputs.ponytail}/skills" ponytailSkills [
        ".agents/skills"
        ".claude/skills"
      ];
    };
}
