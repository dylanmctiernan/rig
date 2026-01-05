rec {
  people.dylan = {
    host.username = "dylan";
    host.hashedPassword = "$6$r8oR.kCfQebQKt6Z$8rYD.A1BjBLLwkaDOk.U1hURaUfqy5JGqXSlZDZCKc6dFZrJ1OAihMqrBXz0W0lZ6YZlFNW1PMbIkezx.CvKA/";

    git.name = "Dylan McTiernan";
    git.email = "dylan@mctiernan.io";

    ssh.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE9aV63mII6UUHP9Shz6zMmGIlAd752I7LzgMTEshkYN dylan@mctiernan.io";
    ssh.privateKey = "";
  };

  machines.nuck = {
    hostName = "nuck";
    lanIp = "192.168.2.10";
    hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIODNVgWjUqXpHUa3I4hqe8S1txz3X2ADrWVe5KcnVF2g";
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

  services.kanidm = {
    name = "kanidm";
    port = 8443;
    subdomain = "auth";
    host = machines.nuck;
    fqdn = "${services.kanidm.subdomain}.${networks.tld}";
  };
}
