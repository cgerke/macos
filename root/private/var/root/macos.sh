#!/usr/bin/env bash
# https://github.com/cgerke

# Cleanup
clean_exit(){
  rm -f \
    "$named_pipe" \
    '/Library/LaunchDaemons/com.cgerke.macos-gui.plist' \
    '/Library/LaunchDaemons/com.cgerke.macos.plist' \
    '/tmp/root' \
    '/tmp/scripts' \
    '/tmp/make.sh' \
    '/tmp/makefile' \
    '/Users/Shared/.com.cgerke.macos' &
  launchctl remove com.cgerke.macos-gui &
  launchctl remove com.cgerke.macos
  exit
}

# Cleanup
trap clean_exit EXIT INT TERM

# Cocoadialog
sleep 8 # give the gui some time...
named_pipe=/tmp/hpipe
mkfifo $named_pipe

/Applications/CocoaDialog.app/Contents/MacOS/CocoaDialog \
  progressbar --title 'macOS' --text "Setup..." \
  --percent 0 --stoppable  < $named_pipe &

# associate file descriptor 3 with a named pipe and
# do all of your work inside here
exec 3<> $named_pipe

echo "xcode installing CommandLineTools..." >&3
if ! xcode-select -p | grep '/Library/Developer/CommandLineTools'
then
  _ondemand='/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress'
  softwareupdate -l | tee ${_ondemand}
  xcode_cli=$(cat < "${_ondemand}" | grep "\*.*Command Line" |
   head -n 1 |
   awk -F"*" '{print $2}' |
   sed -e 's/^ *//' |
   tr -d '\n')
  softwareupdate -i "${xcode_cli}" --verbose; rm -f ${_ondemand}
fi

# Time syncronisation - directory/domain services, chef, ssl etc
echo "time configuring NTP..." >&3
systemsetup -setusingnetworktime "on"
systemsetup -setnetworktimeserver "time.asia.apple.com"
ntpdate -vu time.asia.apple.com

# Device management profiles
# /private/var/db/ConfigurationProfiles/Setup are run alphabetically
# /private/var/db/ConfigurationProfiles/Setup some fail on first boot
# give network interface time to intialise for first boot prior to
# importing a wifi configuration profile to avoid failures if you
# are running this early (I'm waiting for GUI and cocoa so...)
# sleep 10;
echo "hardware installing profiles..." >&3
networksetup -detectnewhardware

echo "profiles Profiles" >&3
for mobile_config in ~/*.mobileconfig
do
  echo "profiles ${mobile_config}" >&3
  sudo profiles -I -F "${mobile_config}" -f -v
done

echo "ard configuring Remote Management..." >&3
/System/Library/CoreServices/RemoteManagement/ARDAgent.app\
/Contents/Resources/kickstart \
  -activate -configure \
  -allowAccessFor -allUsers -access -on -privs -all \
  -clientopts -setvnclegacy -vnclegacy yes \
  -restart -agent

echo "ssh configuring Remote Login..." >&3
systemsetup -setremotelogin on

echo "postfix configuring Postfix..." >&3
cp "/etc/postfix/main.cf"{,.orig}
sed '/MANAGED_MAC_START/,/MANAGED_MAC_END/d' /etc/postfix/main.cf > /tmp/main.cf
tee -a /tmp/main.cf <<<"# MANAGED_MAC_START
relayhost=[smtp.gmail.com]:587
smtp_sasl_auth_enable=yes
smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options=noanonymous
smtp_sasl_mechanism_filter=login
smtp_use_tls=yes
smtp_tls_security_level=encrypt
tls_random_source=dev:/dev/urandom
# MANAGED_MAC_END"
cat /tmp/main.cf
cp -f /tmp/main.cf /etc/postfix/main.cf

# gitignored
echo "sasl configuring SASL..." >&3
chmod 600 "/etc/postfix/sasl_passwd"
chown root:wheel "/etc/postfix/sasl_passwd"
postmap /etc/postfix/sasl_passwd
postfix start

# gitignored
echo "ssh configuring SSHRC..." >&3
chmod 600 /etc/ssh/sshrc
chown root:wheel /etc/ssh/sshrc

# Uncomment this for old images in the field
# echo "url Bootstrap" >&3
# curl -#L https://github.com/cgerke/macos/tarball/master |
#   tar xz --strip 1 -C /tmp/ && \
#   /tmp/root/private/var/root/bootstrap.sh > /tmp/bootstrap.txt

# turn off the progress bar by closing file descriptor 3
exec 3>&-

# notify once background jobs complete
wait && clean_exit

# Failed?
product_version=$(sw_vers -productVersion)
build_version=$(sw_vers -buildVersion)
serial_number=$(ioreg -l |
  grep IOPlatformSerialNumber |
  awk '{print $4}' |
  cut -d \" -f 2)
mac_address0=$(networksetup -getMACADDRESS en0 |
  awk '{print $3}' |
  sed s/://g)
mac_address1=$(networksetup -getMACADDRESS en1 |
  awk '{print $3}' |
  sed s/://g)
system_uuid=$(system_profiler SPHardwareDataType |
  grep "UUID" | awk '{print $3}')
email_body="\n${1}"
email_body+="\nHostname: $(hostname)"
email_body+="\nSerial: ${serial_number}"
email_body+="\nMAC Address en0: ${mac_address0}"
email_body+="\nMAC Address en1: ${mac_address1}"
email_body+="\nUUID: ${system_uuid}"
email_body+="\nBuild: ${product_version} ${build_version}"
printf "POSTBOOT FAIL%s\n${email_body}\n" | \
mail -s "🚫 $(hostname)" "chris.gerke@gmail.com"

exit
