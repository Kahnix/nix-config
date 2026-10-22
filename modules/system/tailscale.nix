{
  flake.modules.nixos.tailscale =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.my.tailscale.ownDevicesOnly) allowedTCPPorts allowedUDPPorts;

      # My devices' Tailscale addresses (`tailscale status`), as opposed to the
      # devices of users this node is shared with. A device keeps its addresses
      # until it is removed from the tailnet; re-adding it assigns new ones.
      ownDevices = [
        "100.93.135.72" # kacpers-macbook-pro
        "fd7a:115c:a1e0::153b:8749"
        "100.112.177.58" # iphone183
        "fd7a:115c:a1e0::c73b:b13b"
      ];

      chain = "tailnet-own-devices";
      removeChain = ''
        ip46tables -t mangle -D INPUT -i tailscale0 -j ${chain} 2>/dev/null || true
        ip46tables -t mangle -F ${chain} 2>/dev/null || true
        ip46tables -t mangle -X ${chain} 2>/dev/null || true
      '';
      returnFrom =
        address:
        let
          iptables = if lib.hasInfix ":" address then "ip6tables" else "iptables";
        in
        "${iptables} -w -t mangle -A ${chain} -s ${address} -j RETURN\n";
      dropTo =
        proto: ports:
        let
          dports = lib.concatMapStringsSep "," toString ports;
        in
        lib.optionalString (ports != [ ]) ''
          ip46tables -t mangle -A ${chain} -p ${proto} -m multiport --dports ${dports} -m conntrack --ctdir ORIGINAL -j DROP
        '';
    in
    {
      options.my.tailscale.ownDevicesOnly = {
        allowedTCPPorts = lib.mkOption {
          type = with lib.types; listOf port;
          default = [ ];
          description = "TCP ports open over Tailscale to my own devices only.";
        };
        allowedUDPPorts = lib.mkOption {
          type = with lib.types; listOf port;
          default = [ ];
          description = "UDP ports open over Tailscale to my own devices only.";
        };
      };

      config = {
        services.tailscale.enable = true;
        environment.systemPackages = [ pkgs.tailscale ];

        networking.firewall = lib.mkIf (allowedTCPPorts != [ ] || allowedUDPPorts != [ ]) {
          interfaces.tailscale0 = { inherit allowedTCPPorts allowedUDPPorts; };

          # tailscaled puts `-i tailscale0 -j ACCEPT` (its ts-input chain) at the
          # top of filter/INPUT, ahead of nixos-fw, so tailscale0 port lists never
          # keep out the devices this node is shared with. mangle/INPUT runs before
          # filter/INPUT and a DROP there is final: connections that other devices
          # open to these ports end here.
          extraCommands = ''
            ${removeChain}
            ip46tables -t mangle -N ${chain}
            ${lib.concatMapStrings returnFrom ownDevices}
            ${dropTo "tcp" allowedTCPPorts}
            ${dropTo "udp" allowedUDPPorts}
            ip46tables -t mangle -A INPUT -i tailscale0 -j ${chain}
          '';
          extraStopCommands = removeChain;
        };
      };
    };
}
