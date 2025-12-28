{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  haosImage = pkgs.stdenv.mkDerivation {
    name = "haos-16.3-qcow2";
    src = pkgs.fetchurl {
      url = "https://github.com/home-assistant/operating-system/releases/download/16.3/haos_ova-16.3.qcow2.xz";
      sha256 = "1kn845bz845vcgzy4kccmjm7wf8ig9aagcmi6ln77hfdfap6rxgk";
    };
    nativeBuildInputs = [ pkgs.xz ];
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out
      xz -d -c $src > $out/haos.qcow2
    '';
  };

  volumeDefinition = inputs.nixvirt.lib.volume.writeXML {
    name = "haos-16.3.qcow2";
    capacity = {
      count = 32;
      unit = "GiB";
    };
    target = {
      format = { type = "qcow2"; };
    };
  };
in
{
  # Note: nixvirt module must be imported in the host configuration

  # Create the libvirt images directory and copy HAOS image
  systemd.tmpfiles.rules = [
    "d /var/lib/libvirt/images 0755 root root -"
  ];

  systemd.services.haos-image-setup = {
    description = "Copy Home Assistant OS image to libvirt pool";
    before = [ "nixvirt.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if [ ! -f /var/lib/libvirt/images/haos-backing.qcow2 ]; then
        ${pkgs.coreutils}/bin/cp ${haosImage}/haos.qcow2 /var/lib/libvirt/images/haos-backing.qcow2
        ${pkgs.coreutils}/bin/chmod 644 /var/lib/libvirt/images/haos-backing.qcow2
      fi
      if [ ! -f /var/lib/libvirt/images/haos-16.3.qcow2 ]; then
        ${pkgs.qemu}/bin/qemu-img create -f qcow2 -F qcow2 -b /var/lib/libvirt/images/haos-backing.qcow2 /var/lib/libvirt/images/haos-16.3.qcow2
      fi
    '';
  };

  virtualisation.libvirt = {
    enable = true;
    connections."qemu:///session" = {
      networks = [
        {
          definition = inputs.nixvirt.lib.network.writeXML (
            inputs.nixvirt.lib.network.templates.bridge {
              uuid = "41883939-1851-42fa-a2b6-f50ea327e725";
              subnet_byte = 122;
            }
          );
          active = true;
        }
      ];
      pools = [
        {
          definition = inputs.nixvirt.lib.pool.writeXML {
            name = "default";
            uuid = "650816df-aa63-4990-9e0a-4c586cb0f04c";
            type = "dir";
            target = { path = "/var/lib/libvirt/images"; };
          };
          active = true;
          volumes = [
            {
              definition = volumeDefinition;
            }
          ];
        }
      ];
      domains = [
        {
          definition = inputs.nixvirt.lib.domain.writeXML (
            inputs.nixvirt.lib.domain.templates.linux {
              name = "home-assistant";
              uuid = "cc7439ed-36af-4696-a6f2-1f0c4474d87e";
              memory = {
                count = 6;
                unit = "GiB";
              };
              storage_vol = {
                pool = "default";
                volume = "haos-16.3.qcow2";
              };
              graphics_type = "none";
            }
          );
          active = true;
        }
      ];
    };
  };
}
