#part3
printf '\033c'
pacman -S lightdm lightdm-gtk-greeter bspwm sxhkd rofi urxvt-unicode picom git
systemctl enable lightdm
mkdir .config/bspwm
mkdir .config/sxhkd
mkdir .config/polybar
cp /usr/share/doc/bspwm/examples/bspwmrc .config/bspwm/
cp /usr/share/doc/bspwm/examples/sxhkdrc .config/sxhkd/

exit
