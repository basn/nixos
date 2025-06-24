{ ... }:
{
  users  = {
    users = {
      basn = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh = {
          authorizedKeys = {
            keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICdxg/zlW4GiU6kRJcTQ6UYEbF07uBJWD5zhcm6gk//T basn@battlestation"
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJaybi1pQnJp1dE/LhhPGiy94000SpKG6q3Qg0UjryOi evl755@KX4H4MFHW1"
            ];
          };
        };
      };
    };
  };
}
