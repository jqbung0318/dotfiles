# Ubuntu Setup Files
This folder holds the setup template for the ubuntu machine.
Note that you must have sudo access to use this.

## Contents
- Docker
    - [Docker Compose](https://github.com/docker/compose)
- ZSH
    - [Oh My Zsh](https://ohmyz.sh/)
    - [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
    - [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
    - [Powerlevel10k](https://github.com/romkatv/powerlevel10k)

## How to Setup
1. Go into the service folder you would like to install (Docker, ZSH, etc...)
2. Give proper permission to execute the `setup.sh`
3. Run `setup.sh`

### Quick Sample
```shell
cd zsh
sudo chmod +x setup.sh
./setup.sh
```

```shell
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/jqbung0318/dotfiles/main/ubuntu/zsh/setup.sh)"
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/jqbung0318/dotfiles/main/ubuntu/docker/setup.sh)"
```