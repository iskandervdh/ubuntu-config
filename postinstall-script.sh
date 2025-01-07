#!/bin/bash

# Settings
UBUNTU_VERSION=$(lsb_release -r | cut -f 2)
NODE_VERSION=22
PHP_VERSION=8.3
GO_VERSION=1.23.4

# Flags
WITHOUT_SERVICES=("mysql" "nginx" "dbeaver" "ghostty" "code" "nodejs" "php" "go" "fluent-icons" "spinup")
declare -A WITHOUT_FLAGS

for service in "${WITHOUT_SERVICES[@]}"; do
    WITHOUT_FLAGS["$service"]=false
done

# Functions
parse_without_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --without)
                shift
                while [[ $# -gt 0 && $1 != --* ]]; do
                    if [[ " ${WITHOUT_SERVICES[@]} " =~ " $1 " ]]; then
                        WITHOUT_FLAGS["$1"]=true
                    else
                        echo "Unknown argument for --without: $1"
                    fi
                    shift
                done
                ;;
            *)
                echo "Unknown argument: $1"
                break
                ;;
        esac
    done
}

install_composer() {
    local expected_checksum="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"

    php -r "copy('https://getcomposer.org/installer', 'composer-installer.php');"
    local actual_checksum="$(php -r "echo hash_file('sha384', 'composer-installer.php');")"

    if [ "$expected_checksum" != "$actual_checksum" ]; then
        >&2 echo 'ERROR: Invalid composer installer checksum'
        rm composer-installer.php
        return
    fi

    php composer-installer.php --quiet
    mv composer.phar /usr/local/bin/composer

    rm composer-installer.php

    return
}

download_latest_github_release() {
    local url=$(
        curl -s https://api.github.com/repos/$1/$2/releases/latest \
        | grep "browser_download_url.*deb" \
        | cut -d : -f 2,3 \
        | tr -d \" \
    )

    # Grab the latest release for the current Ubuntu version
    # Check for that version first, as it is the most specific
    # Then check for ubuntu, as it is the most general
    if [[ "$url" == *"$UBUNTU_VERSION"* ]]; then
        url=$(echo "$url" | grep "$UBUNTU_VERSION")
    elif [[ "$url" == *"ubuntu"* ]]; then
        url=$(echo "$url" | grep "ubuntu")
    fi

    wget -qi - $url

    local filename=$(echo $url | rev | cut -d / -f 1 | rev)

    return $filename
}

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run using sudo"
    exit 1
else
    parse_without_args $@

    ########################
    ### General software ###
    ########################

    echo "Updating and upgrading using apt..."
    apt update && apt upgrade -y

    echo "Installing general software..."
    apt install -y git curl wget gpg tmux htop build-essential apt-transport-https software-properties-common


    ###########################
    ### Additional Software ###
    ###########################

    if [ "$WITHOUT_FLAGS[mysql]" = false ]; then
        echo "Installing MySQL..."
        apt install -y mysql-server
    fi

    if [ "$WITHOUT_FLAGS[nginx]" = false ]; then
        echo "Installing nginx..."
        apt install -y nginx
    fi

    if [ "$WITHOUT_FLAGS[dbeaver]" = false ]; then
        echo "Installing dbeaver..."
        snap install dbeaver-ce
    fi


    ###############
    ### Node js ###
    ###############

    if [ "$WITHOUT_FLAGS[nodejs]" = false ]; then
        echo "Installing nodejs..."
        curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION.x | sudo -E bash -
        apt install -y nodejs

        # Install npm-check-updates and pnpm as global nodejs packages
        npm install -g npm-check-updates pnpm
    fi

    ###########
    ### PHP ###
    ###########

    if [ "$WITHOUT_FLAGS[php]" = false ]; then
        echo "Installing PHP $PHP_VERSION..."
        apt install -y php$PHP_VERSION php$PHP_VERSION-mbstring php$PHP_VERSION-xml php$PHP_VERSION-zip php$PHP_VERSION-curl php$PHP_VERSION-gd php$PHP_VERSION-mysql php$PHP_VERSION-intl

        # Disable apache2
        update-rc.d apache2 disable
        service apache2 stop

        echo "Installing composer..."
        install_composer
    fi

    ##########
    ### Go ###
    ##########

    if [ "$WITHOUT_FLAGS[go]" = false ]; then
        wget https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz
        tar -C /usr/local -xzf go$GO_VERSION.linux-amd64.tar.gz
        rm -f go$GO_VERSION.linux-amd64.tar.gz

        go install github.com/mailhog/MailHog@latest
    fi

    ##############
    ### Spinup ###
    ##############

    if [ "$WITHOUT_FLAGS[spinup]" = false ]; then
        echo "Installing spinup..."

        spinup_installer=$(download_latest_github_release "iskandervdh" "spinup")
        dpkg -i $spinup_installer
        rm -f $spinup_installer
    fi

    ###############
    ### Ghostty ###
    ###############

    if [ "$WITHOUT_FLAGS[ghostty]" = false ]; then
        echo "Installing ghostty..."

        ghostty_installer=$(download_latest_github_release "mkasberg" "ghostty-ubuntu")
        dpkg -i $ghostty_installer
        rm -f $ghostty_installer

        # Set ghostty as default terminal
        update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/ghostty 1
        update-alternatives --set x-terminal-emulator /usr/bin/ghostty
    fi

    ############
    ### Code ###
    ############

    if [ "$WITHOUT_FLAGS[code]" = false ]; then
        echo "Installing Code..."

        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
        rm -f packages.microsoft.gpg

        apt update
        apt install -y code
    fi

    ####################
    ### Fluent icons ###
    ####################

    if [ "$WITHOUT_FLAGS[fluent-icons]" = false ]; then
        git clone https://github.com/vinceliuice/Fluent-icon-theme.git
        cd Fluent-icon-theme
        ./install.sh yellow
        cd ..
        rm -rf Fluent-icon-theme
    fi

    #####################
    ### General Setup ###
    #####################

    ### TODO
    # # Generate SSH keys
    # echo "Generating SSH keys"
    # ssh-keygen -o -t ed25519

    # Disable screen blank
    gsettings set org.gnome.desktop.session idle-delay 0

    #################
    ### ZSH + OMZ ###
    #################

    apt install -y fonts-powerline
    apt install -y zsh
    chsh -s $(which zsh)

    bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
    rm ~/.zshrc.pre-oh-my-zsh

    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

    #################
    ### .Dotfiles ###
    #################

    git clone git@github.com/iskandervdh/.dotfiles.git
    cd .dotfiles
    ./install.sh
fi
