{
  pkgs,
  lib,
  config,
  ...
}:
# Keeps a claude-obsidian vault in sync across hosts via its git remote, so
# Claude on picard (long-lived zellij/rc session) and on surface share one
# vault. Each sync is fetch + rebase --autostash onto origin + push, run:
#   - every `interval` by a systemd user timer (keeps long-lived sessions and
#     the Obsidian app's view fresh, and clones the vault if it's missing)
#   - on Claude SessionStart
#   - on Claude Stop, but only when local commits are unpushed (cheap local
#     check, so it costs nothing on turns that didn't checkpoint the vault)
# A sync is skipped while .vault-meta/mutation.lock exists (a transaction is
# mid-apply). A transaction that read its expected hashes before a pull fails
# its hash check instead of clobbering, so it just needs re-reading.
# On a rebase conflict the rebase is aborted, the local branch is left
# untouched, and the conflict is reported (into Claude's context on
# SessionStart) to be resolved by hand.
# On hosts where a claude-obsidian retrieval index has been built
# (.vault-meta/bm25 exists, via the wiki-retrieve skill), each sync also
# rebuilds it, local-only (--no-llm), whenever the committed wiki/ tree has
# changed. The index is gitignored, so each host keeps its own copy.
let
  cfg = config.vault-sync;
  obsidian = config.crann.ai-utils.claude-obsidian;

  vault-sync = pkgs.writeShellApplication {
    name = "vault-sync";
    runtimeInputs = with pkgs; [
      coreutils
      git
      openssh
      util-linux
    ];
    text = ''
      vault=${lib.escapeShellArg cfg.path}
      remote=${lib.escapeShellArg cfg.remote}
      if_ahead=false
      [ "''${1:-}" = "--if-ahead" ] && if_ahead=true

      state="''${XDG_RUNTIME_DIR:-/tmp}/vault-sync"
      mkdir -p "$state"
      exec 9>"$state/lock"
      flock -w 30 9 || exit 0

      if [ ! -d "$vault/.git" ]; then
        if [ -e "$vault" ]; then
          echo "vault-sync: $vault exists but is not a git repo; not syncing" >&2
          exit 1
        fi
        mkdir -p "$(dirname "$vault")"
        timeout 60 git clone --quiet "$remote" "$vault"
        echo "vault-sync: cloned $remote into $vault"
        exit 0
      fi

      cd "$vault"
      upstream_ahead() { git rev-list --count '@{u}..HEAD'; }

      refresh_index() {
        [ -d .vault-meta/bm25 ] || return 0
        local tree
        tree=$(git rev-parse HEAD:wiki)
        [ "$tree" = "$(cat "$state/indexed-tree" 2>/dev/null)" ] && return 0
        if ${obsidian.python.package}/bin/python3 ${obsidian.source}/scripts/contextual-prefix.py --vault "$vault" --all --no-llm >/dev/null \
          && ${obsidian.python.package}/bin/python3 ${obsidian.source}/scripts/bm25-index.py --vault "$vault" build >/dev/null; then
          printf '%s\n' "$tree" >"$state/indexed-tree"
          echo "vault-sync: rebuilt the retrieval index"
        else
          echo "vault-sync: retrieval index rebuild failed; wiki-retrieve will fall back to text search" >&2
        fi
      }

      if $if_ahead && [ "$(upstream_ahead)" -eq 0 ]; then
        exit 0
      fi
      if [ -e .vault-meta/mutation.lock ]; then
        echo "vault-sync: skipped, a vault transaction is in progress"
        exit 0
      fi
      gitdir=$(git rev-parse --git-dir)
      if [ -d "$gitdir/rebase-merge" ] || [ -d "$gitdir/rebase-apply" ] || [ -f "$gitdir/MERGE_HEAD" ]; then
        echo "vault-sync: a rebase/merge is in progress in $vault; resolve it by hand" >&2
        exit 1
      fi

      if ! timeout 30 git fetch --quiet origin; then
        echo "vault-sync: fetch failed (offline?); vault not synced"
        refresh_index
        exit 0
      fi

      behind=$(git rev-list --count 'HEAD..@{u}')
      if [ "$behind" -gt 0 ]; then
        if ! out=$(git rebase --autostash '@{u}' 2>&1); then
          git rebase --abort >/dev/null 2>&1 || true
          echo "vault-sync: CONFLICT rebasing $vault onto origin; local branch left unchanged, resolve by hand:" >&2
          printf '%s\n' "$out" | tail -n 15 >&2
          exit 1
        fi
        case "$out" in
          *"autostash resulted in conflicts"*)
            echo "vault-sync: pulled $behind commit(s), but uncommitted local edits conflicted and are kept in 'git stash'"
            ;;
          *)
            echo "vault-sync: pulled $behind commit(s) from origin"
            ;;
        esac
      fi

      ahead=$(upstream_ahead)
      if [ "$ahead" -gt 0 ]; then
        if timeout 30 git push --quiet origin HEAD; then
          echo "vault-sync: pushed $ahead commit(s) to origin"
        else
          echo "vault-sync: push failed; $ahead commit(s) still unpushed" >&2
        fi
      fi

      refresh_index
    '';
  };

  # Moved here from a hand-written ~/.claude/hooks script on surface so every
  # host with the vault gets it.
  block-vault-writes = pkgs.writeShellApplication {
    name = "block-vault-writes";
    runtimeInputs = with pkgs; [
      coreutils
      jq
    ];
    text = ''
      # PreToolUse hook (Edit|Write): blocks raw writes under a claude-obsidian
      # vault's wiki/, .vault-meta/, or inbox/ directories. Vault root is the
      # nearest ancestor directory containing .claude-obsidian.json. Mutations
      # there must go through the claude-obsidian transaction core instead.
      input="$(cat)"
      file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')"

      [ -z "$file_path" ] && exit 0

      abs_path="$(realpath -m -- "$file_path" 2>/dev/null)" || exit 0
      d="$(dirname -- "$abs_path")"

      vault_root=""
      while [ "$d" != "/" ]; do
        if [ -f "$d/.claude-obsidian.json" ]; then
          vault_root="$d"
          break
        fi
        d="$(dirname -- "$d")"
      done

      [ -z "$vault_root" ] && exit 0

      rel="''${abs_path#"$vault_root"/}"

      case "$rel" in
        wiki/*|wiki|.vault-meta/*|.vault-meta|inbox/*|inbox)
          reason="Blocked: '$rel' is inside claude-obsidian vault '$vault_root' (wiki/.vault-meta/inbox). Never use raw Write/Edit here -- use the claude-obsidian transaction core (read expected hashes, build a bundle, transaction inspect, then transaction apply) or the matching claude-obsidian:* skill (e.g. save, wiki-ingest) instead."
          jq -n --arg reason "$reason" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
          ;;
      esac
      exit 0
    '';
  };

  # Hooks ship as a managed plugin rather than programs.claude-code.settings,
  # so ~/.claude/settings.json stays a mutable file.
  plugin = pkgs.runCommand "vault-sync-claude-plugin" { } ''
    mkdir -p $out/.claude-plugin $out/hooks
    cp ${
      pkgs.writers.writeJSON "plugin.json" {
        name = "vault-sync";
        version = "1.0.0";
        description = "Syncs the claude-obsidian vault via git and blocks raw writes into it";
      }
    } $out/.claude-plugin/plugin.json
    cp ${
      pkgs.writers.writeJSON "hooks.json" {
        hooks = {
          SessionStart = [
            {
              matcher = "startup|resume|clear";
              hooks = [
                {
                  type = "command";
                  command = lib.getExe vault-sync;
                  timeout = 90;
                }
              ];
            }
          ];
          Stop = [
            {
              hooks = [
                {
                  type = "command";
                  command = "${lib.getExe vault-sync} --if-ahead";
                  timeout = 90;
                }
              ];
            }
          ];
          PreToolUse = [
            {
              matcher = "Edit|Write";
              hooks = [
                {
                  type = "command";
                  command = lib.getExe block-vault-writes;
                  timeout = 10;
                }
              ];
            }
          ];
        };
      }
    } $out/hooks/hooks.json
  '';
in
{
  options.vault-sync = {
    enable = lib.mkEnableOption "git sync of the claude-obsidian vault";

    path = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/obsidian/technodrome";
      description = "Local checkout of the vault. Cloned from `remote` if missing.";
    };

    remote = lib.mkOption {
      type = lib.types.str;
      default = "ssh://git@codeberg.org/jDmacD/technodrome.git";
      description = "Git remote the vault syncs with.";
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "5min";
      description = "How often the systemd timer syncs the vault.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ vault-sync ];

    programs.claude-code.plugins.vault-sync = plugin;

    programs.claude-code.context = lib.mkAfter ''
      ---
      ## Obsidian vault sync

      The claude-obsidian vault lives at `${cfg.path}` on both surface and
      picard, and is kept in sync through its git remote (`${cfg.remote}`) by
      `vault-sync` (fetch, `rebase --autostash` onto origin, push). It runs from
      a systemd user timer every ${cfg.interval}, on SessionStart, and after
      each turn that leaves unpushed vault commits. It skips while
      `.vault-meta/mutation.lock` exists.

      - Checkpoint (commit) completed vault transactions so they get pushed;
        uncommitted vault changes stay local to this host.
      - If a transaction apply fails its expected-hash check, a sync probably
        pulled newer content: re-read the hashes and rebuild the bundle, don't
        force it.
      - Run `vault-sync` by hand before a large ingest or save to start from
        the latest vault.
      - If vault-sync reports a CONFLICT (usually in the vault's log/index/hot
        cache files), tell the user. Resolve it with a manual rebase in
        `${cfg.path}`, keeping both sides' entries. Don't discard either side
        or force-push.
    '';

    systemd.user.services.vault-sync = {
      Unit.Description = "Sync the claude-obsidian vault with its git remote";
      Service = {
        Type = "oneshot";
        ExecStart = lib.getExe vault-sync;
      };
    };

    systemd.user.timers.vault-sync = {
      Unit.Description = "Periodically sync the claude-obsidian vault";
      Timer = {
        OnBootSec = "1min";
        OnUnitActiveSec = cfg.interval;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
