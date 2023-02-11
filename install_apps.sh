#!/bin/bash

name=$(cat /tmp/user_name)

apps_path="/tmp/apps.csv"
curl https://raw.githubcontent.com/Grimcrow\
	/arch_installer/master/apps.csv > $apps_path

dialog --title "Welcome!" \
	--msgbox "Welcome to the installation script for your apps and dotfiles!" \
	10 60

apps=("essential" "Essentials" on 
	  "network" "Network" on 
	  "tools" "Nice tools to have (highly recommended)" on 
	  "tmux" "Tmux" on 
	  "notifier" "Notification tools" on 
	  "git" "Git & git tools" on 
	  "i3" "i3 wm" on 
	  "zsh" "The Z-Shell (zsh)" on 
	  "neovim" "Neovim" on 
	  "urxvt" "URxvt" on 
	  "firefox" "Firefox (browser)" off)

dialog --checklist \
	"You can now choose what group of application you want to install. \n\n\
	You can select an option with SPACE and accept your choices with ENTER." \
	0 0 0 \
	"${apps[@]}" 2> app_choices

choices=$(cat app_choices) && rm app_choices

selection="^$(echo $choices | sed -e 's/ /,|^/g'),"
lines=$(grep -E "$selection" "$apps_path")
count=$(echo "$lines" | wc -l)
packages=$(echo "$lines" | awk -F, {'print $2'})

echo "$selection" "$lines" "$count" >> "/tmp/packages"

pacman -Syu --noconfirm

rm -f /tmp/aur_queue

dialog --title "Let's go!" --msgbox \
	"The system will now install everything you need.\n\n\
	It will take some time. \n\n" \
	13 60

c=0
echo "$packages" | while read -r package; do
	c=$(( "$c" + 1 ))

	dialog --title "Arch Linux Installation" --infobox \
		"Downloading and installing program $c out of $count: $package..." \
		8 70

	((pacman --noconfirm --needed -S "$package" > /tmp/arch_install 2>&1) \
	|| echo "$package" >> /tmp/aur_queue) \
	|| echo "$package" >> /tmp/arch_install_failed

	if [ "$package" = "zsh" ]; then
		# Set Zsh as default terminal for our user
		chsh -s "$(which zsh)" "$name"
	fi

	if [ "$package" = "networkmanager" ]; then
		# Enable the service NetworkManager for systemd.  
		systemctl enable NetworkManager.service
	fi
done

echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

curl https://raw.githubusercontent.com/Grimcrow\
	/arch_installer/master/install_user.sh > /tmp/install_user.sh

# Switch user and run the final script
sudo -u "$name" sh /tmp/install_user.sh

