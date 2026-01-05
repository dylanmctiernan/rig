rec {
  people.dylan = {
    host.username = "dylan";
    # host.hashedPassword = "";

    git.name = "Dylan McTiernan";
    git.email = "dylan@mctiernan.io";

    ssh.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE9aV63mII6UUHP9Shz6zMmGIlAd752I7LzgMTEshkYN dylan@mctiernan.io";
    ssh.privateKey = "";
  };

  machines.nuck = {
    hostName = "nuck";
    lanIp = "192.168.2.10";
  };
  machines.synology = {
    lanIp = "192.168.2.11";
  };

  networks.tld = "dhm.dev";
  networks.home = {
    subnet = "192.168.2.0/24";

    machines = [
      machines.nuck
      machines.synology
    ];
  };

  paths.data = "/data";

  services.caddy = {
    name = "caddy";
    image = "caddy:2.10.2@sha256:dedfbbeb703b2ce9ff4a98fc06aa9c7c7d9a42f0b7d778738c1dd3ef11dcc767";
    dataDir = "${paths.data}/caddy";
    host = machines.nuck;
  };

  services.kanidm = {
    name = "kanidm";
    image = "kanidm/server:1.8.5@sha256:55af50cf02909ff8f62d3a083870e697a47658c2dac94598dc5dbeb7de5955f3";
    port = 8443;
    dataDir = "${paths.data}/kanidm";
    subdomain = "auth";
    host = machines.nuck;
    fqdn = "${services.kanidm.subdomain}.${networks.tld}";
  };
}
