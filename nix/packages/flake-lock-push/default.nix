{
  pkgs,
  ...
}:
pkgs.writeShellScriptBin "flake-lock-push" ''
  echo "Checking git status..."
  ${pkgs.git}/bin/git status

  echo "Checking for changes to flake.lock..."
  ${pkgs.git}/bin/git diff flake.lock

  # Check if there are changes to commit
  if ${pkgs.git}/bin/git diff --quiet flake.lock; then
    echo "No changes to flake.lock"
  else
    echo "Changes to flake.lock detected, pushing..."
    
    # Configure git
    ${pkgs.git}/bin/git config --local user.name 'github-actions[bot]'
    ${pkgs.git}/bin/git config --local user.email 'github-actions[bot]@users.noreply.github.com'
    ${pkgs.git}/bin/git remote set-url origin https://$${GH_TOKEN}@github.com/jDmacD/blueprint.git
    
    # Commit and push the changes
    ${pkgs.git}/bin/git add flake.lock
    ${pkgs.git}/bin/git commit -m "Update flake.lock via automated workflow"
    
    # Push using the token for authentication
    ${pkgs.git}/bin/git push origin HEAD:main || echo "Failed to push: $?"
''
