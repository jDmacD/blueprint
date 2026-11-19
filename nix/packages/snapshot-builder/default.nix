# Build the cloud image that temporary build servers boot from.
#
#   nix run .#snapshot-builder -- arm             # Hetzner (default)
#   nix run .#snapshot-builder -- x86
#   nix run .#snapshot-builder -- arm scaleway    # Scaleway, arm only
#
# Creates a throwaway Debian/Ubuntu seed server, installs
# nixosConfigurations.<arch>-builder on it with nixos-anywhere (kexec, built
# on the server itself), shuts it down cleanly, saves its disk as an image,
# and deletes the seed, also on failure. Older images are kept; consumers
# (crann's build-ephemeral) pick the newest and pin the image's SSH host key:
#
#   Hetzner   snapshot, labels role=<arch>-builder rev=<commit>; the host key
#             is in the description. Needs the hcloud CLI context
#             (sops-nix ~/.config/hcloud/cli.toml).
#   Scaleway  instance image over a Block Storage snapshot, in ZONE
#             (nl-ams-1); tags role=<arch>-builder, rev=<commit> and
#             hostkey=<ed25519 base64>. Needs scw credentials
#             (sops-nix ~/.config/scw/config.yaml, or SCW_* env vars). The
#             IAM SSH key SSH_PUBKEY is registered in the project if missing:
#             Scaleway's Debian seeds take root's keys from the project.
{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "snapshot-builder";
  runtimeInputs = with pkgs; [
    hcloud
    scaleway-cli
    nixos-anywhere
    openssh
    git
    jq
    coreutils
  ];
  text = ''
    ARCH=''${1:-}
    PROVIDER=''${2:-hetzner}
    case "$PROVIDER/$ARCH" in
      hetzner/arm) SEED_TYPE=cax11 ;;
      hetzner/x86) SEED_TYPE=cx23 ;;
      scaleway/arm) SEED_TYPE=BASIC2-A2C-4G ;;
      *)
        echo "usage: snapshot-builder <arm|x86> [hetzner|scaleway]  (scaleway: arm only)" >&2
        exit 2
        ;;
    esac
    HOST="$ARCH-builder"
    FLAKE=''${FLAKE:-.}
    SSH_KEY=''${SSH_KEY:-James@nixos-surface}             # Hetzner key name
    SSH_PUBKEY=''${SSH_PUBKEY:-$HOME/.ssh/id_ed25519.pub} # Scaleway IAM key
    LOCATION=''${LOCATION:-hel1}                          # Hetzner
    ZONE=''${ZONE:-nl-ams-1}                              # Scaleway

    if [ -n "$(git -C "$FLAKE" status --porcelain)" ]; then
      echo "refusing: $FLAKE has uncommitted changes (the image is labelled with its revision)" >&2
      exit 1
    fi
    REV=$(git -C "$FLAKE" rev-parse --short HEAD)
    NAME="$HOST-seed-$(date -u +%Y%m%d%H%M)"
    KNOWN=$(mktemp)
    SSHO=(-o StrictHostKeyChecking=accept-new -o UserKnownHostsFile="$KNOWN" -o ConnectTimeout=5)
    SERVER_ID=""

    # --- Hetzner -------------------------------------------------------------
    hetzner_create() {
      hcloud server create --name "$NAME" --type "$SEED_TYPE" --image ubuntu-24.04 \
        --location "$LOCATION" --ssh-key "$SSH_KEY" --without-ipv6 \
        --label role="$HOST-seed" >/dev/null
      SERVER_ID=$NAME
      IP=$(hcloud server ip "$NAME")
    }
    hetzner_delete() {
      if hcloud server describe "$NAME" >/dev/null 2>&1; then
        echo "deleting $NAME"
        hcloud server delete "$NAME" >/dev/null
      fi
    }
    hetzner_stop() {
      # `shutdown` (ACPI), not `poweroff` (a hard power cut).
      hcloud server shutdown "$NAME" >/dev/null
      for _ in $(seq 60); do
        [ "$(hcloud server describe "$NAME" -o format='{{.Status}}')" = off ] && return 0
        sleep 5
      done
      echo "timed out waiting for $NAME to stop" >&2
      return 1
    }
    hetzner_image() {
      hcloud server create-image --type snapshot \
        --description "nixos-$HOST $REV $HOSTKEY" \
        --label role="$HOST" --label rev="$REV" \
        "$NAME" >/dev/null
      IMAGE=$(hcloud image list --type snapshot --selector "role=$HOST,rev=$REV" -o json \
        | jq -r 'max_by(.created) | .id')
    }

    # --- Scaleway ------------------------------------------------------------
    scaleway_create() {
      local pub project
      pub=$(cut -d" " -f1-2 "$SSH_PUBKEY")
      project=''${SCW_DEFAULT_PROJECT_ID:-$(scw config get default-project-id 2>/dev/null || true)}
      if ! scw iam ssh-key list project-id="$project" -o json \
        | jq -e --arg k "$pub" 'any(.[]; (.public_key | split(" ")[0:2] | join(" ")) == $k)' >/dev/null; then
        echo "registering $SSH_PUBKEY as a Scaleway IAM SSH key"
        scw iam ssh-key create name="$(cut -d" " -f3 "$SSH_PUBKEY")" \
          public-key="$pub" project-id="$project" >/dev/null
      fi
      # 10 GB keeps the snapshot (billed per GB) small; clones ask for a
      # bigger root volume and grow into it.
      SERVER_ID=$(scw instance server create zone="$ZONE" name="$NAME" \
        type="$SEED_TYPE" image=debian_trixie root-volume=sbs:10GB ip=ipv4 \
        tags.0="role=$HOST-seed" -o json | jq -r .id)
      scw instance server wait "$SERVER_ID" zone="$ZONE" >/dev/null
      IP=$(scw instance server get "$SERVER_ID" zone="$ZONE" -o json \
        | jq -r '.public_ips[0].address // .public_ip.address')
    }
    scaleway_delete() {
      # A create that failed after the API accepted it leaves no ID; find it.
      [ -n "$SERVER_ID" ] || SERVER_ID=$(scw instance server list zone="$ZONE" name="$NAME" -o json \
        | jq -r --arg n "$NAME" '[.[] | select(.name == $n)][0].id // empty')
      if [ -n "$SERVER_ID" ] && scw instance server get "$SERVER_ID" zone="$ZONE" >/dev/null 2>&1; then
        echo "deleting $NAME"
        scw instance server delete "$SERVER_ID" zone="$ZONE" \
          with-volumes=all with-ip=true force-shutdown=true >/dev/null
      fi
    }
    scaleway_stop() {
      # Halt from inside first so the host keys are on disk, then let the
      # API stop (and deallocate) the server.
      ssh "''${SSHO[@]}" "jmacdonald@$IP" 'sudo systemctl poweroff' || true
      for _ in $(seq 24); do
        ssh "''${SSHO[@]}" "jmacdonald@$IP" true 2>/dev/null || break
        sleep 5
      done
      sleep 10
      scw instance server stop "$SERVER_ID" zone="$ZONE" >/dev/null 2>&1 || true
      scw instance server wait "$SERVER_ID" zone="$ZONE" >/dev/null
      [ "$(scw instance server get "$SERVER_ID" zone="$ZONE" -o json | jq -r .state)" = stopped ]
    }
    scaleway_image() {
      local vol snap keyb64
      # The CLI's own JSON view names it "Volumes" (the API: "volumes").
      vol=$(scw instance server get "$SERVER_ID" zone="$ZONE" -o json \
        | jq -r '[(.Volumes // .volumes)[]][0].id')
      snap=$(scw block snapshot create zone="$ZONE" volume-id="$vol" name="nixos-$HOST-$REV" \
        tags.0="role=$HOST" tags.1="rev=$REV" -o json | jq -r .id)
      scw block snapshot wait "$snap" zone="$ZONE" >/dev/null
      keyb64=$(cut -d" " -f2 <<<"$HOSTKEY")
      IMAGE=$(scw instance image create zone="$ZONE" snapshot-id="$snap" arch=arm64 \
        name="nixos-$HOST-$REV" tags.0="role=$HOST" tags.1="rev=$REV" \
        tags.2="hostkey=$keyb64" -o json | jq -r '.image.id')
    }

    cleanup() {
      rm -f "$KNOWN"
      "''${PROVIDER}_delete"
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

    echo "creating $NAME ($PROVIDER $SEED_TYPE)"
    "''${PROVIDER}_create"
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

    # The host keys generated on first boot must reach the disk, or every
    # clone makes new ones.
    ssh "''${SSHO[@]}" "jmacdonald@$IP" 'sudo sync' || true
    echo "stopping $NAME"
    "''${PROVIDER}_stop"
    echo "imaging $NAME"
    "''${PROVIDER}_image"

    echo "image $IMAGE ($PROVIDER, $HOST, rev $REV)"
    echo "host key: $HOSTKEY"
  '';
}
