{
  pkgs,
  ...
}:
pkgs.writeShellScriptBin "fleet-deploy" ''
  export PATH="${pkgs.lib.makeBinPath [ pkgs.openssh ]}:$PATH"

  ${pkgs.deploy-rs}/bin/deploy \
    --skip-checks \
    --ssh-user githubrunner \
    --activation-timeout 300 \
    --ssh-opts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /run/secrets/githubrunner/githubrunner_ed25519" \
    --targets .#pi01 .#pi02 .#pi03 .#pi04 .#pi05 .#tpi04 .#tpi03 .#tpi02 .#tpi01 .#picard
    . \
    -- \
      --accept-flake-config \
      --extra-experimental-features flakes
''
