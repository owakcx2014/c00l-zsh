#!/bin/bash

# --- 1. Choose Distro ---
echo "Your linux distro is [arch-based(a) Debian-based(d) redhat-fedora(r)]:"
read -p "Select (a/d/r): " distro

case $distro in
    a) PKG_MGR="sudo pacman -S --noconfirm" ;;
    d) PKG_MGR="sudo apt-get install -y" ;;
    r) PKG_MGR="sudo dnf install -y" ;;
    *) echo "Invalid option. Exiting."; exit 1 ;;
esac

# --- 2. Check for ZSH ---
if ! command -v zsh &> /dev/null; then
    echo "Zsh is not installed."
    read -p "Do you want to install zsh?[Y/N]: " install_zsh
    # تحويل الإجابة لحرف صغير دائماً للفحص
    if [[ "${install_zsh,,}" == "y" ]]; then
        echo "Installing Zsh..."
        $PKG_MGR zsh
    else
        echo "Exiting..."
        exit 1
    fi
fi

# --- 3. Set ZSH as Default ---
if [[ $SHELL != *"zsh"* ]]; then
    echo "Setting Zsh as default shell..."
    sudo chsh -s $(which zsh) $(whoami)
fi

# --- 4. Install Core Dependencies ---
echo "Installing dependencies (git, curl, btop, fastfetch)..."
$PKG_MGR git curl btop fastfetch

# --- 5. Oh My Zsh & Powerlevel10k ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

echo "Installing Themes and Plugins..."
# Re-cloning to ensure they exist
sudo rm -rf ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

sudo rm -rf ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

sudo rm -rf ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# --- 6. Handle .zshrc ---
if [ -f "$HOME/.zshrc" ]; then
    read -p "The Operation will replace zsh file[Y/N]: " replace_zsh
    # فحص ذكي للـ Y أو y
    if [[ "${replace_zsh,,}" == "y" ]]; then
        echo "Replacing .zshrc..."
        rm "$HOME/.zshrc"
    else
        echo "Returning to terminal..."
        exit 0
    fi
fi

# [هنا نضع محتوى ملف .zshrc الذي أرسلته أنت سابقاً]
cat <<EOF > "$HOME/.zshrc"
# 1. نظام التشغيل الفوري لثيم Powerlevel10k
if [[ -r "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh" ]]; then
  source "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh"
fi

export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-syntax-highlighting zsh-autosuggestions)

source \$ZSH/oh-my-zsh.sh

autoload -U compinit && compinit
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# --- Aliases ---
alias shd='sudo poweroff'
alias rb='sudo reboot'
alias ff='fastfetch'
alias tm='btop'
alias update-zsh='source ~/.zshrc'
alias edit-zsh='nano ~/.zshrc'
alias edit-grub='sudo nano /etc/default/grub'
EOF

# إضافة الـ Distro Specific Aliases بناءً على اختيارك الأول
if [[ $distro == "a" ]]; then
cat <<EOF >> "$HOME/.zshrc"
alias clearc='sudo journalctl --vacuum-time=1d && rm -rf ~/.cache/* && yay -Sc --noconfirm'
alias updatep='sudo pacman -Syu'
alias updatey='yay -Sua --noconfirm'
alias updatea='yay -Syu --noconfirm'
alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'
alias edit-grub='sudo nano /etc/default/grub'
installp() { sudo pacman -S "\$@"; }
instally() { yay -S "\$@"; }
EOF
elif [[ $distro == "d" ]]; then
cat <<EOF >> "$HOME/.zshrc"
alias clearc='sudo apt autoremove && sudo apt clean'
alias update='sudo apt update && sudo apt upgrade -y'
install() { sudo apt install "\$@"; }
EOF
elif [[ $distro == "r" ]]; then
cat <<EOF >> "$HOME/.zshrc"
# RedHat/Fedora Specific
alias clearc='sudo dnf clean all && rm -rf ~/.cache/*'
alias update='sudo dnf check-update'
alias upgrade='sudo dnf upgrade -y'
alias update-grub='sudo grub2-mkconfig -o /boot/grub2/grub.cfg'
install() { sudo dnf install -y "\$@"; }
EOF
fi
# --- 7. Create shortcuts.txt ---
echo "Creating shortcuts.txt..."
cat <<EOF > "$HOME/zsh shortcuts.txt"
Universal{
shd = shutdown
rb = reboot
ff = fastfetch
tm = btop (task manager)
update-zsh = update zsh (Needed if you edit on .zshrc file)
edit-zsh = if you want to edit .zshrc file
clearc = clear cache
edit-grub = edit grub config
}

Arch-Based{
updatep = update official repos (pacman)
updatey = update yay (aur)
updatea = update everything
update-grub = update grub bootloader
installp = install package/packages from pacman
instally = install package/packages from yay (AUR)
}

Debian/Ubuntu-Based{
update = update official repos (apt)
update-grub = update grub bootloader
install = install package/packages
}

Red Hat / Fedora{
update = update official repos (dnf)
upgrade = upgrade official repos (dnf)
update-grub = update grub bootloader
install = install package/packages
}

Note: Most commands handle sudo internally.
Note: if you want to add/customize your own shortcuts you should go to ~/.zshrc file and go down to last of the file where is (alias [shortcut]='[command]'
Warning: Never type Capital letters (A-B-C-Z) in the commands IT's all small case (a-b-c-z)
Note: When You Use Install command for install a package like nano, you Must type like that: install nano
EOF

echo "All done! Please close and reopen your terminal."
echo "you should see ~/zsh shortcuts.txt file to see the shortcuts!"
