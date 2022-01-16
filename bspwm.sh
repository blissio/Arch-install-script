#part3
printf '\033c'
pacman -S bspwm sxhkd urxvt-unicode picom git xorg-xinit xorg
touch .xinitrc
touch "exec dwm" >> /.xinitrc
mkdir .config
mkdir .config/bspwm
mkdir .config/sxhkd
cp /usr/share/doc/bspwm/examples/bspwmrc .config/bspwm/
cp /usr/share/doc/bspwm/examples/sxhkdrc .config/sxhkd/
git clone https://github.com/RealBlissIO/Dotfiles
cp Dotfiles/urxvt .config/
cp Dotfiles/.vimrc .
cp Dotfiles/.Xresources .

exit
