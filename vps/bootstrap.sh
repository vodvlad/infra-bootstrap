#!/bin/bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Run as root!"
  exit 1
fi

read -p "Enter new username: " NEW_USER

if [[ -z "$NEW_USER" ]]; then
  echo "Username cannot be empty"
  exit 1
fi

SSHD_CONFIG="/etc/ssh/sshd_config"

echo ">>> Creating user..."

if id "$NEW_USER" &>/dev/null; then
    echo "User already exists"
else
    adduser --disabled-password --gecos "" "$NEW_USER"
fi

echo ">>> Adding to sudo group..."
usermod -aG sudo "$NEW_USER" 2>/dev/null || usermod -aG wheel "$NEW_USER"

echo ">>> Copying SSH keys..."
if [ -f /root/.ssh/authorized_keys ]; then
    mkdir -p /home/$NEW_USER/.ssh
    cp /root/.ssh/authorized_keys /home/$NEW_USER/.ssh/authorized_keys
    chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh
    chmod 700 /home/$NEW_USER/.ssh
    chmod 600 /home/$NEW_USER/.ssh/authorized_keys
else
    echo "WARNING: No authorized_keys found for root"
fi

echo ">>> Enabling passwordless sudo..."
echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$NEW_USER
chmod 440 /etc/sudoers.d/$NEW_USER

echo ">>> Hardening SSH..."

# PermitRootLogin no
if grep -q "^PermitRootLogin" "$SSHD_CONFIG"; then
    sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG"
else
    echo "PermitRootLogin no" >> "$SSHD_CONFIG"
fi

# PasswordAuthentication no
if grep -q "^PasswordAuthentication" "$SSHD_CONFIG"; then
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONFIG"
else
    echo "PasswordAuthentication no" >> "$SSHD_CONFIG"
fi

echo ">>> Restarting SSH..."
systemctl restart ssh 2>/dev/null || systemctl restart sshd

echo "================================="
echo "User $NEW_USER created"
echo "Root SSH disabled"
echo "Password auth disabled"
echo "You can now login:"
echo "ssh $NEW_USER@server_ip"
echo "================================="
