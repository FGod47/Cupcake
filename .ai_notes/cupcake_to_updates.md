Here are the best UX features and functional capabilities from Windows that would be awesome
  additions to adapt into Cupcake Shell:
  ──────
  ### 1. 📶 Wi-Fi Features to Adapt from Windows
  #### 1. "Connect Automatically" Toggle per Network

  • Windows UX: Clicking a Wi-Fi network shows a [x] Connect automatically checkbox before entering
  the password.
  • Why Adapt It: Gives users control over which networks auto-join when they enter a cafe, office,
  or home.
  • Linux Implementation:
    # Enable auto-connect
    nmcli connection modify "SSID_NAME" connection.autoconnect yes
    # Disable auto-connect
    nmcli connection modify "SSID_NAME" connection.autoconnect no


  #### 2. Connect to Hidden Network Modal

  • Windows UX: Displays "Hidden Network" at the bottom of the scanned list, prompting for SSID,
  Security Type (WPA2/WPA3), and Password.
  • Linux Implementation: In Cupcake's SettingsPageNetwork.qml, add a "Connect to Hidden Network"
  button:
    nmcli dev wifi connect "Hidden_SSID" password "YourPassword" hidden yes


  #### 3. Hotspot Connected Devices Counter

  • Windows UX: When Mobile Hotspot is turned on, Windows displays Connected devices: 2/8 and lists
  device names/IPs.
  • Linux Implementation: Parse active DHCP leases or ip neighbor:
    cat /var/lib/misc/dnsmasq.leases | awk '{print $3, $4}'


  #### 4. Wi-Fi QR Code Share

  • Windows UX: Windows 11 lets you generate a QR code for your current Wi-Fi network so phones can
  scan and connect instantly.
  • Linux Implementation: Generate a QR code in terminal/QML using qrencode:
    qrencode -t UTF8 "WIFI:S:MySSID;T:WPA;P:MyPassword;;"

  ──────
  ### 2. 🎧 Bluetooth Features to Adapt from Windows

  #### 1. Bluetooth Device Battery Percentage Badges

  • Windows UX: Quick Settings displays battery levels next to headphones/mice (e.g. Sony WH-1000XM4
  · 80%).
  • Why Adapt It: Essential for wireless audio and peripheral management.
  • Linux Implementation: BlueZ exposes battery levels via D-Bus (org.bluez.Battery1 or UPower /
  PipeWire). In Quickshell.Bluetooth, read modelData.battery or modelData.batteryPercentage and show
  a battery pill badge next to the device icon.

  #### 2. Audio Output Sink Quick-Switcher

  • Windows UX: Clicking the Volume icon lets you switch audio output (e.g., from Laptop Speakers to
  Bluetooth Headphones) right from the quick panel.
  • Linux Implementation: Integrate wpctl (WirePlumber / PipeWire) with Cupcake's Bluetooth page or
  Control Center:
    # List sinks
    wpctl status
    # Switch default audio output sink
    wpctl set-default <SINK_ID>


  #### 3. Clear Distinction Between "Disconnect" and "Forget / Unpair"
  • Windows UX: Primary button is Disconnect (keeps pairing info), while a sub-menu or right-click
  option is Remove Device (unpair).
  • Linux Implementation: In SettingsPageBluetooth.qml:
      • Disconnect: modelData.disconnect()
      • Remove/Unpair: modelData.forget() or bluetoothctl remove <MAC>
  #### 4. Swift Pair Toast Notifications
  • Windows UX: When a Bluetooth headphone is put in pairing mode near the PC, a popup toast
  notification appears saying "New device found: Connect?".
  • Linux Implementation: Listen to BlueZ discovery events and send a desktop notification via
  swaync / Cupcake NotificationIslandOverlay.qml.
  ──────
  ### 💡 Recommended Next Upgrades for Cupcake Shell:

  1. 🔋 Bluetooth Battery Badges in SettingsPageBluetooth.qml
  2. 🔊 WirePlumber Audio Sink Switcher in DropdownHardware.qml / ControlCenterSolid.qml
  3. 🔗 Wi-Fi Auto-Connect Toggles in SettingsPageNetwork.qml

────────────────────────────────────────────────────────────
> add this to ai notes  neet to impliment section so when i switch again on linux i will impliment
  these
