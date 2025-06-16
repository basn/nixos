{ pkgs, ...}:
{
  environment = {
    systemPackages = with pkgs; [
      blocky
    ];
 };
 services = {
   blocky = {
     enable = true;
     settings = {
       ports = {
         dns = "10.1.1.8:53"; # Port for incoming DNS Queries.
       };
       connectIPVersion = "v4";
       upstreams = {
         strategy = "parallel_best";
         groups = {
           default = [
             "https://one.one.one.one/dns-query" # cloudflare
             "https://dns.google/dns-query" # google
           ];
         };
       };
       # For initially solving DoH/DoT Requests when no system Resolver is available.
       bootstrapDns = {
         upstream = "https://one.one.one.one/dns-query";
         ips = [ "1.1.1.1" "1.0.0.1" "8.8.8.8" "8.8.8.6" ];
       };
       #Enable Blocking of certian domains.
       blocking = {
         blackLists = {
           #Adblocking
           ads = [
             "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
             "http://sysctl.org/cameleon/hosts"
             "https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt"
             "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
             "https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts"
             "https://www.github.developerdan.com/hosts/lists/ads-and-tracking-extended.txt"
             "https://raw.githubusercontent.com/buggerman/SwitchBlockerForPiHole/master/Paranoid.txt"
           ];
         };
         #Configure what block categories are used
         clientGroupsBlock = {
           default = [ "ads" ];
         };
       };
       caching = {
         minTime = "5m";
         maxTime = "30m";
         prefetching = true;
       };
       customDNS = {
         customTTL = "30m";
  	 filterUnmappedTypes = false;
 	 mapping = {
           "bandit.basn.se" = "192.168.180.10";
	   "hass.basn.se" = "10.1.1.8";
           "rt.basn.se" = "192.168.180.10";
	   "vmware.basn.se" = "192.168.195.5";
           "services.basn.se" = "10.1.1.8";
	   "cygate.basn.se" = "10.140.12.5";
	 };
       };
     };
   };
 };
}
