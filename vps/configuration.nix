{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix 
  ];

  # Настройки для облачного сервера
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  # Пользователь
  users.users.vladyslav = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [ btop ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCiEh409bch92WPBXRDlqtGwf8GwsblTLxBBmjNI5296XvU9M+RLFDDM02r0uRH6ExknaK377R81WugOvdQmdaqY7vkhrCG25cZvjKKxif302L6KLXVu1/Q7MWLvO/xY2w60UiaNxaFH6eg9gveC5PV/LFPANKtHuX1wom8sEJg8Zxk3Z1zR1pwCHmC/oJ7Zhi+DcEBJezqed/7ar6xTdJQCn+Gzrd+oWv5Ityyml6IN1gELNliRT9vWF/b5SxUyvlQTXXW4CkTLAszF+P9Pu56Q7n5x5hOe/ZabYmt61DJ1nAnH2dUXKXaB4Low3WEXdoPthYxMcqkVQu+3nADBSE7DwcqqUYuYW+SoayvVNfmhSIebOcgFu8+pwRQBb1SQX8Pc9IiCYrHSECrJf1Ud9WGGfYEmB7WjI+FMH92kqFYGCqyheGJ0tnYYXYXb2HE8ns+7HhcgfKDTo29CaAybzJl1e9meWMMs5UzF6RO58Uq9JVfLOjb7vc4J0e9EUoY6WE= vvodopia@c2r6s5.42luxembourg.lu"
    ];
  };

  # SSH обязателен для VPS
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true; # Пока не проверите вход по ключу

  system.stateVersion = "25.05"; 
}
