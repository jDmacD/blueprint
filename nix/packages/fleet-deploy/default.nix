{
  pkgs,
  ...
}:
pkgs.writeShellScriptBin "fleet-deploy" ''
  export PATH="${pkgs.lib.makeBinPath [ pkgs.openssh ]}:$PATH"

  ${pkgs.deploy-rs}/bin/deploy \
    --ssh-user githubrunner \
    --activation-timeout 300 \
    --ssh-opts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /run/secrets/githubrunner/githubrunner_ed25519" \
    . \
    -- \
      --accept-flake-config \
      --extra-experimental-features flakes
''
