# ──────────────── Current Theme ────────────────
dir="$HOME/.config/rofi/powermenu/"
theme='style'

# ──────────────── System Info ────────────────
uptime="`uptime -p | sed -e 's/up //g'`"
host=`hostname`

# ──────────────── Menu Options (Icons Only) ────────────────
hibernate=''
shutdown=''
reboot=''
suspend=''
logout=''
yes=' Yes'
no=' No'

# ──────────────── Menu Variants (commented out) ────────────────
# With icons and labels
# hibernate=' Hibernate'
# shutdown='  Shutdown'
# reboot=' Reboot'
# suspend=' Suspend'
# logout='  Logout'
# yes=' Yes'
# no=' No'

# No icons
# hibernate='Hibernate'
# shutdown='Shutdown'
# reboot='Reboot'
# suspend='Suspend'
# logout='Logout'
# yes='yes'
# no='no'

# ──────────────── Rofi Launchers ────────────────
rofi_cmd() {
	rofi -dmenu \
		-p "$host" \
		-mesg "Uptime: $uptime" \
		-theme ${dir}/${theme}.rasi
}

confirm_cmd() {
	rofi -markup-rows -dmenu \
		-p 'Confirmation' \
		-mesg 'Are you Sure?' \
		-theme ${dir}/confirmation.rasi
}

# ──────────────── Confirmation Prompt ────────────────
confirm_exit() {
	echo -e "<span foreground='#a6e3a1'>$yes</span>\n<span foreground='#f38ba8'>$no</span>" | confirm_cmd
}

# ──────────────── Display Rofi Power Menu ────────────────
run_rofi() {
	echo -e "$shutdown\n$reboot\n$suspend\n$hibernate\n$logout" | rofi_cmd
}

# ──────────────── Execute Selected Action ────────────────
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

# ──────────────── Action Dispatcher ────────────────
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
