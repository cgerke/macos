#!/usr/bin/env bash
# https://github.com/cgerke

_version=$(sw_vers -productVersion)
_build=$(sw_vers -buildVersion)
_year=$(date +"%Y")
_month=$(date +"%m")
_day=$(date +"%d")

case $_version in
  10.12*)
    _app="Install macOS Sierra.app"
  ;;
  10.11*)
    _app="Install OS X El Capitan.app"
  ;;
  10.10*)
    _app="Install OS X Yosemite.app"
  ;;
  10.9*)
    _app="Install OS X Mavericks.app"
  ;;
esac

create_adtmpl() {
  # $1 /tmp/base.adtmpl or /tmp/custom.adtmpl
  # $2 ~/Desktop/base-${_version}-${_build}.hfs.dmg or
  #   ~/Desktop/custom-${_version}-${_build}.hfs.dmg
  # $3 /Applications/${_app} or
  #   ~/Desktop/base-${_version}-${_build}.hfs.dmg
  # $4 true/false
  # $5 ~/Desktop/macos.pkg
  _packages="/"
  if [ ! -z "$5" ]; then
    _packages=">
      <string>$5</string>
      </array"
  fi

  cat <<-EOF >"$1"
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
      "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>AdditionalPackages</key>
      <array${_packages}>
      <key>ApplyUpdates</key>
      <$4/>
      <key>OutputPath</key>
      <string>$2</string>
      <key>SourcePath</key>
      <string>$3</string>
      <key>TemplateFormat</key>
      <string>1.0</string>
      <key>VolumeName</key>
      <string>Macintosh HD</string>
      <key>VolumeSize</key>
      <integer>15</integer>
    </dict>
    </plist>
EOF
}

create_adtmpl \
  "/tmp/base.adtmpl" \
  "$HOME/base-${_version}-${_build}.hfs.dmg" \
  "/Applications/${_app}" \
  "true"

create_adtmpl \
  "/tmp/custom.adtmpl" \
  "$HOME/custom-${_version}-${_build}.hfs.dmg" \
  "$HOME/base-${_version}-${_build}.hfs.dmg" \
  "true" \
  "/tmp/macos.pkg"

# Sudo password for expect
echo "Admin password: "
read -r -s -e _password

# Always update
rm -f ~/Library/Logs/AutoDMG/*
/Applications/AutoDMG.app/Contents/MacOS/AutoDMG update
/Applications/AutoDMG.app/Contents/MacOS/AutoDMG download "${_version} ${_build}"

# BASE only if one doesn't exist
[ ! -f ~/Desktop/base-"${_version}"-"${_build}".hfs.dmg ] && expect <<EOF
  set timeout -1
  spawn /Applications/AutoDMG.app/Contents/MacOS/AutoDMG \
    --verbose --log-level 7 \
    --logfile - \
    build /tmp/base.adtmpl
  expect "Password for *"
  send "$_password\r"
  send "exit\r"
  expect eof
EOF

# Build custom AutoDMG
expect <<EOF
  set timeout -1
  spawn /Applications/AutoDMG.app/Contents/MacOS/AutoDMG \
    --verbose --log-level 7 \
    --logfile - \
    build --force /tmp/custom.adtmpl
  expect "Password for *"
  send "$_password\r"
  send "exit\r"
  expect eof
EOF

# VMWare clean
expect <<EOF
  set timeout -1
  spawn sudo rm -Rf ~/Documents/Virtual\ Machines.localized/macos-vm.vmwarevm
  expect "Password:"
  send "$_password\r"
  send "exit\r"
  expect eof
EOF

# VMWare guest
expect <<EOF
  set timeout -1
  spawn sudo vfuse \
    -i ~/Desktop/custom-${_version}-${_build}.hfs.dmg \
    -o ~/Documents/Virtual\ Machines.localized
  expect "Password:"
  send "$_password\r"
  send "exit\r"
  expect eof
EOF

# Snapshot
vmrun -T ws snapshot \
  ~/Documents/Virtual\ Machines.localized/macos-vm.vmwarevm Initial

# Notify
[ ! -f ~/Documents/Virtual\ Machines.localized/macos-vm.vmwarevm ] && \
  cat < ~/Library/Logs/AutoDMG/AutoDMG-"${_year}"-"${_month}"-"${_day}".log |
  mail -s "build $(hostname)" "chris.gerke@gmail.com"

exit 0
