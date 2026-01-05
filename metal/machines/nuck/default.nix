let
  vars = import ../../../vars;
in
{
  imports = [
    ./hardware.nix
    ./system.nix
    ./services/caddy.nix
    ./services/kanidm.nix
  ];

  _module.args = { inherit vars; };
}
