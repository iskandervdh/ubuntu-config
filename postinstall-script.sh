if [[ $EUID -ne 0 ]]; then
	echo "This script must be run using sudo"
	exit 1
else
	########################
	### General software ###
	########################

	echo "Updating and upgrading using apt..."
	apt update && apt upgrade -y

	echo "Installing git..."
	apt install git -y
	echo "Installing curl..."
	apt install curl -y
	echo "Installing build essential..."
	apt install -y build-essential
 	echo "Installing htop"
  	apt install -y htop
   	echo "Installing MySQL"
   	apt install -y mysql-server
    	echo "Installing nginx"
     	apt install -y nginx
        echo "Installing dbeaver..."
	snap install dbeaver-ce

	############
	### tmux ###
	############
 
	echo "Installing tmux"
   	apt install -y tmux

	# TODO: Get from .dotfiles repo
    	echo "# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1" > .tmux.conf

	############
 	### Code ###
  	############
   
   	apt install -y wget gpg
	wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
	sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
	echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
	rm -f packages.microsoft.gpg
 
 	apt install -y apt-transport-https
 	apt update
  	apt install -y code

	###############
	### Node js ###
	###############

	echo "Installing nodejs..."
	curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
	apt install -y nodejs

	# Install npm-check-updates, pnpm and concurrently as global nodejs packages
	npm install -g npm-check-updates pnpm concurrently
 
	###########
 	### PHP ###
  	###########

	echo "Installing PHP..."
	apt install -y php8.3 php8.3-mbstring php8.3-xml php8.3-zip php8.3-curl php8.3-gd php8.3-mysql php8.3-intl

	# Disable apache2
  	update-rc.d apache2 disable
   	service apache2 stop

	echo "Installing composer..."
 	wget https://raw.githubusercontent.com/composer/getcomposer.org/76a7060ccb93902cd7576b67264ad91c8a2700e2/web/installer -O - -q | php --
	mv composer.phar /usr/local/bin/composer

 	####################
  	### Fluent icons ###
   	####################
    
    	git clone https://github.com/vinceliuice/Fluent-icon-theme.git
     	cd Fluent-icon-theme
	./install.sh yellow
 	cd ..
  	rm -rf Fluent-icon-theme

	##########
 	### Go ###
  	##########

 	# TODO: Install go automatically
	
	# go install github.com/iskandervdh/spinup@latest
   	# go install github.com/mailhog/MailHog@latest

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

	apt install -y zsh
	chsh -s $(which zsh)

	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	rm ~/.zshrc.pre-oh-my-zsh

	git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

	rm ~/.zshrc
	curl -fsSL https://raw.githubusercontent.com/iskandervdh/ubuntu-config/main/.zshrc -o ~/.zshrc

	apt install -y fonts-powerline
fi
