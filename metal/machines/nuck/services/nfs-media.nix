{ ... }:
let
  commonConfig = import ../../../common-config.nix;
in
{
  # NFS mount configuration for Synology NAS media storage
  # Mount path on Synology: /volume1/media
  # NFS permissions configured for *.mac.lab with Read/Write access

  # Ensure NFS client support is enabled
  boot.supportedFilesystems = [ "nfs" ];
  services.rpcbind.enable = true;

  # NFS mount configuration
  fileSystems."${commonConfig.machines.nuck.mediaDir}" = {
    # Synology NAS via LAN
    device = "192.168.2.41:/volume1/media";

    fsType = "nfs";
    options = [
      "nfsvers=4" # Use NFSv4
      "rw" # Read-write access
      "hard" # Hard mount - wait for server if unavailable
      "intr" # Allow interrupting hung operations
      "noatime" # Don't update access times (better performance)
      "rsize=131072" # Read buffer size (128KB - good for streaming)
      "wsize=131072" # Write buffer size (128KB - good for downloads)
      "timeo=600" # Timeout in deciseconds (60 seconds)
      "retrans=2" # Number of retransmissions before error
      "_netdev" # Wait for network before mounting
      "x-systemd.automount" # Auto-mount on access
      "x-systemd.idle-timeout=600" # Unmount after 10 minutes of inactivity
    ];
  };

  # Create mount point and media subdirectories that *arr apps expect
  systemd.tmpfiles.rules = [
    "d ${commonConfig.machines.nuck.mediaDir} 0755 root root -"
    "d ${commonConfig.machines.nuck.mediaDir}/movies 0755 root root -"
    "d ${commonConfig.machines.nuck.mediaDir}/tv 0755 root root -"
    "d ${commonConfig.machines.nuck.mediaDir}/music 0755 root root -"
    "d ${commonConfig.machines.nuck.mediaDir}/downloads 0755 root root -"
    "d ${commonConfig.machines.nuck.mediaDir}/torrents 0755 root root -"
    "d ${commonConfig.machines.nuck.mediaDir}/youtube 0755 root root -"
  ];
}
