#part3
printf '\033c'
pacman -S xorg-xinit xorg git
touch .xinitrc
touch "exec dwm" >> /.xinitrc
cd /usr/src
git clone git://git.suckless.org/dwm
git clone git://git.suckless.org/st
git clone git://git.suckless.org/dmenu
cd dwm
sudo make clean install
cd ..
cd st
sudo make clean install
cd ..
cd dmenu
sudo make clean install
cd

exit
