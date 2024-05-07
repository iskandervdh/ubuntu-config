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

	#####################
	### General Setup ###
	#####################

	### TODO
	# # Generate SSH keys
	# echo "Generating SSH keys"
	# ssh-keygen -t ed25519

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

	###############
	### Node js ###
	###############

	echo "Installing nodejs..."
	curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
	apt install -y nodejs

	# Install npm-check-updates and pnpm as global nodejs packages
	npm install -g npm-check-updates
	npm install -g pnpm
fi
