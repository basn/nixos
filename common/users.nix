{ pkgs, ... }:
{
  users  = {
    users = {
      basn = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        shell = pkgs.fish;
        packages = [ pkgs.whois pkgs.asn pkgs.gh pkgs.nixpkgs-review ];
        openssh = {
          authorizedKeys = {
            keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICdxg/zlW4GiU6kRJcTQ6UYEbF07uBJWD5zhcm6gk//T basn@battlestation"
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJaybi1pQnJp1dE/LhhPGiy94000SpKG6q3Qg0UjryOi evl755@KX4H4MFHW1"
              "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAFuVdK5MvjlkAypdfCHVqkmNGjK/+8zyq+XXmZ3D/JUtSdI5owSSefXkYhX1QoopQ2HJBsoyzorMIZD9UNixGgQpwHyW7RZ/w2pERcYA5P63eWWvASQ9seO1Bl1ngwztnCs0Xe7KUbdDYF9vyq0liQeelE0eU8ZMLyu9C8nIJN+S9zwog== basn@laptop"
            ];
          };
        };
      };
    };
  };
}
