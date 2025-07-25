#!/usr/bin/env bash

# Current Theme
dir="$HOME/.config/rofi/powermenu/"
theme='style'

# CMDs
uptime="`uptime -p | sed -e 's/up //g'`"
host=`hostname`

# Options ( only icons)
hibernate=''
# shutdown=''
# reboot=''
# suspend=''
# logout=''
# yes=' Yes'
# no=' No'

# Options (with icons)
hibernate=' hibernate'
shutdown='  Shutdown'
reboot=' Reboot'
suspend=' Suspend'
logout='  Logout'
yes=' Yes'
no=' No'

# Options (no icons)
# hibernate='Hibernate'
# shutdown='Shutdown'
# reboot='Reboot'
# suspend='Suspend'
# logout='Logout'
# lock='Lock'
# yes='yes'
# no='no'

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-p "$host" \
		-mesg "Uptime: $uptime" \
		-theme ${dir}/${theme}.rasi
}

# Confirmation CMD
confirm_cmd() {
	rofi -markup-rows -dmenu \
		-p 'Confirmation' \
		-mesg 'Are you Sure?' \
		-theme ${dir}/confirmation.rasi
}

# Ask for confirmation
confirm_exit() {
	echo -e "<span foreground='#a6e3a1'>$yes</span>\n<span foreground='#f38ba8'>$no</span>" | confirm_cmd
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$shutdown\n$reboot\n$suspend\n$hibernate\n$logout" | rofi_cmd
}

# Execute Command
run_cmd() {
	selected="$(confirm_exit)"
	echo "$selected"
	if [[ "$selected" =~ "$yes" ]]; then
		if [[ $1 == '--shutdown' ]]; then
			systemctl poweroff
		elif [[ $1 == '--reboot' ]]; then
			systemctl reboot
		elif [[ $1 == '--hibernate' ]]; then
			systemctl suspend
		elif [[ $1 == '--suspend' ]]; then
			mpc -q pause
			amixer set Master mute
			systemctl suspend
		elif [[ $1 == '--logout' ]]; then
      hyprctl dispatch exit
  	fi
	else
		exit 0
	fi
}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
    $shutdown)
		run_cmd --shutdown
        ;;
    $reboot)
		run_cmd --reboot
        ;;
    $hibernate)
		run_cmd --hibernate
        ;;
    $lock)
		if [[ -x '/usr/bin/betterlockscreen' ]]; then
			betterlockscreen -l
		elif [[ -x '/usr/bin/i3lock' ]]; then
			i3lock
		fi
        ;;
    $suspend)
		run_cmd --suspend
        ;;
    $logout)
		run_cmd --logout
        ;;
esac
