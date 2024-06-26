#!/bin/sh

# update first
sudo apt-get update
sudo apt-get install curl git zsh -y

sudo chsh -s $(which zsh)

# install oh my zsh
# RUNZSH=no
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/jqbung0318/dotfiles/main/ubuntu/zsh/install.sh)"

# install plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# copy all config files
curl -L https://raw.githubusercontent.com/jqbung0318/dotfiles/main/ubuntu/zsh/.p10k.zsh -o ~/.p10k.zsh
curl -L https://raw.githubusercontent.com/jqbung0318/dotfiles/main/ubuntu/zsh/.zshrc -o ~/.zshrc
curl -L https://raw.githubusercontent.com/jqbung0318/dotfiles/main/ubuntu/zsh/custom.zsh -o ~/.oh-my-zsh/custom/custom.zsh

# cp .zshrc ~/
# cp .p10k.zsh ~/
# cp custom.zsh ~/.oh-my-zsh/custom/