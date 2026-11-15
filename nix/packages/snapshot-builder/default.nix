# Build the Hetzner snapshot that temporary build servers boot from.
#
#   nix run .#snapshot-builder -- arm      # from a clean blueprint checkout
#   nix run .#snapshot-builder -- x86
#
# Creates a throwaway Ubuntu server (cax11 / cx23), installs
# nixosConfigurations.<arch>-builder on it with nixos-anywhere (kexec, built
# on the server itself), shuts it down, saves it as a snapshot labelled
# role=<arch>-builder, and deletes the server, also on failure. The snapshot's
# description carries the image's SSH host key, which crann's build-ephemeral
# pins. Older snapshots are kept; consumers pick the newest. Needs the hcloud
# CLI context on this host (sops-nix ~/.config/hcloud/cli.toml).
{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "snapshot-builder";
  runtimeInputs = with pkgs; [
    hcloud
    nixos-anywhere
    openssh
    git
    jq
    coreutils
  ];
  text = ''
    case "''${1:-}" in
      arm) SEED_TYPE=cax11 ;;
      x86) SEED_TYPE=cx23 ;;
      *)
        echo "usage: snapshot-builder <arm|x86>" >&2
        exit 2
        ;;
    esac
    ARCH=$1
    HOST="$ARCH-builder"
    FLAKE=''${FLAKE:-.}
    SSH_KEY=''${SSH_KEY:-James@nixos-surface}
    LOCATION=''${LOCATION:-hel1}

    if [ -n "$(git -C "$FLAKE" status --porcelain)" ]; then
      echo "refusing: $FLAKE has uncommitted changes (the snapshot is labelled with its revision)" >&2
      exit 1
    fi
    REV=$(git -C "$FLAKE" rev-parse --short HEAD)
    NAME="$HOST-seed-$(date -u +%Y%m%d%H%M)"
    KNOWN=$(mktemp)
    SSHO=(-o StrictHostKeyChecking=accept-new -o UserKnownHostsFile="$KNOWN" -o ConnectTimeout=5)

    cleanup() {
      rm -f "$KNOWN"
      if hcloud server describe "$NAME" >/dev/null 2>&1; then
        echo "deleting $NAME"
        hcloud server delete "$NAME" >/dev/null
      fi
    }
    trap cleanup EXIT

    wait_ssh() { # user@ip
      for _ in $(seq 60); do
        ssh "''${SSHO[@]}" "$1" true 2>/dev/null && return 0
        sleep 5
      done
      echo "timed out waiting for ssh to $1" >&2
      return 1
    }

    echo "creating $NAME ($SEED_TYPE, $LOCATION)"
    hcloud server create --name "$NAME" --type "$SEED_TYPE" --image ubuntu-24.04 \
      --location "$LOCATION" --ssh-key "$SSH_KEY" --without-ipv6 \
      --label role="$HOST-seed" >/dev/null
    IP=$(hcloud server ip "$NAME")
    wait_ssh "root@$IP"

    echo "installing $HOST ($REV) on $IP"
    nixos-anywhere --flake "$FLAKE#$HOST" --build-on remote \
      --ssh-option UserKnownHostsFile="$KNOWN" \
      --ssh-option StrictHostKeyChecking=no \
      --target-host "root@$IP"

    # The installed system has a new host key.
    : >"$KNOWN"
    wait_ssh "jmacdonald@$IP"
    # shellcheck disable=SC2029 # $HOST is meant to expand locally
    ssh "''${SSHO[@]}" "jmacdonald@$IP" "
      set -e
      test \"\$(hostname)\" = $HOST
      # nix-daemon is socket-activated; ask it instead of systemctl.
      nix store info --store daemon >/dev/null
      sudo nix-collect-garbage -d >/dev/null
      # Each clone generates its own machine-id on first boot.
      sudo rm -f /etc/machine-id
    "
    # ssh-keyscan also prints a "# host:22 SSH-2.0-…" comment line on stdout.
    HOSTKEY=$(ssh-keyscan -t ed25519 "$IP" 2>/dev/null | grep -v '^#' | cut -d" " -f2-3)

    # A clean shutdown, not `poweroff` (a hard power cut): otherwise the host
    # keys generated on first boot may never reach the disk, and every clone
    # makes new ones.
    ssh "''${SSHO[@]}" "jmacdonald@$IP" 'sudo sync' || true
    hcloud server shutdown "$NAME" >/dev/null
    for _ in $(seq 60); do
      [ "$(hcloud server describe "$NAME" -o format='{{.Status}}')" = off ] && break
      sleep 5
    done
    echo "snapshotting $NAME"
    hcloud server create-image --type snapshot \
      --description "nixos-$HOST $REV $HOSTKEY" \
      --label role="$HOST" --label rev="$REV" \
      "$NAME" >/dev/null
    IMAGE=$(hcloud image list --type snapshot --selector "role=$HOST,rev=$REV" -o json \
      | jq -r 'max_by(.created) | .id')

    echo "snapshot $IMAGE ($HOST, rev $REV)"
    echo "host key: $HOSTKEY"
  '';
}
