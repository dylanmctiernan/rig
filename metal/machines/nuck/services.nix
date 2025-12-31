{...}: {
  services.forgejo = {
    enable = true;
    settings = {
      server = {
        DOMAIN = "nuck";
        HTTP_PORT = 3000;
      };
    };
  };
}
