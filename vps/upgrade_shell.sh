#!/bin/bash
set -euo pipefail

# Определяем пользователя
if [ -n "${SUDO_USER:-}" ]; then
  TARGET_USER="$SUDO_USER"
else
  TARGET_USER="$(whoami)"
fi

# Не даём ставить для root
if [ "$TARGET_USER" = "root" ]; then
  echo "Do not run this as root directly."
  echo "Run as normal user with: sudo ./install-zsh.sh"
  exit 1
fi

USER_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
ZSHRC="${USER_HOME}/.zshrc"

echo ">>> Installing zsh for user: $TARGET_USER"

echo ">>> Updating packages..."
apt update -y

echo ">>> Installing zsh + deps..."
apt install -y zsh curl git

echo ">>> Setting zsh as default shell..."
chsh -s "$(command -v zsh)" "$TARGET_USER"

echo ">>> Installing Oh My Zsh..."
sudo -u "$TARGET_USER" -H sh -c '
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    echo "Oh My Zsh already installed"
  fi
'

echo ">>> Ensuring .zshrc exists..."
sudo -u "$TARGET_USER" -H bash -lc "touch '$ZSHRC'"

echo ">>> Checking Homebrew..."
if ! sudo -u "$TARGET_USER" -H bash -lc "command -v brew >/dev/null 2>&1"; then
  echo ">>> Homebrew not found, installing..."
  sudo -u "$TARGET_USER" -H bash -lc '
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  '

  echo ">>> Adding brew shellenv to .zshrc (idempotent)..."
  sudo -u "$TARGET_USER" -H bash -lc "
    if ! grep -Fq 'brew shellenv' '$ZSHRC'; then
      printf '\n# Homebrew\neval \"\$(brew shellenv)\"\n' >> '$ZSHRC'
    else
      echo 'brew shellenv already present in .zshrc'
    fi
  "
else
  echo "Homebrew already installed"
fi

echo ">>> Loading brew env for this script run..."
# подтянем brew в текущий процесс, чтобы дальше работали brew install
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
else
  # fallback: попробуем из PATH (если уже был)
  if sudo -u "$TARGET_USER" -H bash -lc "command -v brew >/dev/null 2>&1"; then
    :
  else
    echo "ERROR: brew not found after install."
    exit 1
  fi
fi

echo ">>> Updating brew..."
sudo -u "$TARGET_USER" -H bash -lc "brew update"

echo ">>> Installing Starship + plugins via brew..."
sudo -u "$TARGET_USER" -H bash -lc "brew install starship zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting || true"
sudo -u "$TARGET_USER" -H bash -lc "brew upgrade starship zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting || true"

echo ">>> Enabling Starship in .zshrc (idempotent)..."
sudo -u "$TARGET_USER" -H bash -lc "
  if ! grep -Fq 'eval \"\$(starship init zsh)\"' '$ZSHRC'; then
    printf '\n# Starship prompt\neval \"\$(starship init zsh)\"\n' >> '$ZSHRC'
  else
    echo 'Starship init already present in .zshrc'
  fi
"

echo ">>> Enabling brew zsh plugins in .zshrc (idempotent, via brew --prefix)..."
sudo -u "$TARGET_USER" -H bash -lc "
  if ! grep -Fq '# Brew zsh plugins' '$ZSHRC'; then
    printf '\n# Brew zsh plugins\n' >> '$ZSHRC'
  fi

  if ! grep -Fq 'zsh-autosuggestions.zsh' '$ZSHRC'; then
    printf 'source \$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh\n' >> '$ZSHRC'
  fi

  if ! grep -Fq 'zsh-history-substring-search.zsh' '$ZSHRC'; then
    printf 'source \$(brew --prefix)/share/zsh-history-substring-search/zsh-history-substring-search.zsh\n' >> '$ZSHRC'
  fi

  if ! grep -Fq 'zsh-syntax-highlighting.zsh' '$ZSHRC'; then
    printf 'source \$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh\n' >> '$ZSHRC'
  fi
"

echo "================================="
echo "Zsh installed + set as default for: $TARGET_USER"
echo "Oh My Zsh installed (if missing)"
echo "Homebrew installed (if missing)"
echo "Starship installed via brew + enabled"
echo "Plugins installed via brew + sourced in .zshrc:"
echo " - zsh-autosuggestions"
echo " - zsh-history-substring-search"
echo " - zsh-syntax-highlighting"
echo "Now: log out and log back in (or reconnect SSH)"
echo "================================="
