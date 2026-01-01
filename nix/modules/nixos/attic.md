```bash
sudo atticd-atticadm make-token \
    --sub "jtec" \
    --validity "2y" \
    --pull "*" \
    --push "*" \
    --create-cache "*" \
    --delete "*" \
    --configure-cache "*" \
    --configure-cache-retention "*"\
    --destroy-cache "*"
```

```bash
nix path-info --all \
| grep -E "linux_rpi|linux-rpi|linux-headers-static|linux-firmware|zfs-kernel|linux-config" \
| attic push --stdin jtec
```