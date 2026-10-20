{
  pkgs,
  lib,
  config,
  ...
}:
# A Claude Code skill for a read-only health sweep of the k3s cluster and its
# Gatus endpoints. The checks live in one script (also on PATH as
# `cluster-sweep`) so a sweep costs one tool call and gives the same output
# every time; SKILL.md tells Claude how to triage what it reports.
let
  cfg = config.cluster-sweep;

  cluster-sweep = pkgs.writeShellApplication {
    name = "cluster-sweep";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      gawk
      jq
      kubectl
    ];
    runtimeEnv.GATUS_URL = cfg.gatusUrl;
    text = builtins.readFile ./cluster-sweep.sh;
  };

  skill = pkgs.runCommand "cluster-sweep-skill" { } ''
    mkdir -p $out
    substitute ${./SKILL.md} $out/SKILL.md \
      --replace-fail @sweep@ ${lib.getExe cluster-sweep} \
      --replace-fail @gatusUrl@ ${cfg.gatusUrl}
  '';
in
{
  options.cluster-sweep = {
    enable = lib.mkEnableOption "the cluster-sweep Claude Code skill";

    gatusUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://gatus.local.jtec.xyz";
      description = "Base URL of Gatus; the sweep reads its unauthenticated /api/v1/endpoints/statuses.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cluster-sweep ];
    programs.claude-code.skills.cluster-sweep = skill;
  };
}
