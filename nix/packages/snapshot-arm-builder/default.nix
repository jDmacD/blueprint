# Build the Hetzner snapshot that temporary aarch64 build servers boot from.
#
#   nix run .#snapshot-arm-builder            # from a clean blueprint checkout
#
# Creates a throwaway Ubuntu cax11, installs nixosConfigurations.arm-builder
# on it with nixos-anywhere (kexec, built on the server itself), powers it
# off, saves it as a snapshot labelled role=arm-builder, and deletes the
# server, also on failure. Older role=arm-builder snapshots are kept; the
# newest is the one consumers pick. Needs the hcloud CLI context on this host
# (sops-nix ~/.config/hcloud/cli.toml).
{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "snapshot-arm-builder";
  runtimeInputs = with pkgs; [
    hcloud
    nixos-anywhere
    openssh
    git
    jq
    coreutils
  ];
  text = ''
    FLAKE=''${FLAKE:-.}
    SSH_KEY=''${SSH_KEY:-James@nixos-surface}
    LOCATION=''${LOCATION:-hel1}

    if [ -n "$(git -C "$FLAKE" status --porcelain)" ]; then
      echo "refusing: $FLAKE has uncommitted changes (the snapshot is labelled with its revision)" >&2
      exit 1
    fi
    REV=$(git -C "$FLAKE" rev-parse --short HEAD)
    NAME="arm-builder-seed-$(date -u +%Y%m%d%H%M)"
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

    echo "creating $NAME (cax11, $LOCATION)"
    hcloud server create --name "$NAME" --type cax11 --image ubuntu-24.04 \
      --location "$LOCATION" --ssh-key "$SSH_KEY" --without-ipv6 \
      --label role=arm-builder-seed >/dev/null
    IP=$(hcloud server ip "$NAME")
    wait_ssh "root@$IP"

    echo "installing arm-builder ($REV) on $IP"
    nixos-anywhere --flake "$FLAKE#arm-builder" --build-on remote \
      --ssh-option UserKnownHostsFile="$KNOWN" \
      --ssh-option StrictHostKeyChecking=no \
      --target-host "root@$IP"

    # The installed system has a new host key.
    : >"$KNOWN"
    wait_ssh "jmacdonald@$IP"
    ssh "''${SSHO[@]}" "jmacdonald@$IP" '
      set -e
      test "$(hostname)" = arm-builder
      systemctl is-active nix-daemon >/dev/null
      sudo nix-collect-garbage -d >/dev/null
      # Each clone generates its own machine-id on first boot.
      sudo rm -f /etc/machine-id
    '
    HOSTKEY=$(ssh-keyscan -t ed25519 "$IP" 2>/dev/null | cut -d" " -f2- | base64 -w0)

    hcloud server poweroff "$NAME" >/dev/null
    echo "snapshotting $NAME"
    hcloud server create-image --type snapshot \
      --description "nixos-arm-builder $REV" \
      --label role=arm-builder --label rev="$REV" \
      "$NAME" >/dev/null
    IMAGE=$(hcloud image list --type snapshot --selector "role=arm-builder,rev=$REV" -o json \
      | jq -r 'max_by(.created) | .id')

    echo "snapshot $IMAGE (rev $REV)"
    echo "publicHostKey for clients: $HOSTKEY"
  '';
}
