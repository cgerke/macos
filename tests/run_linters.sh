#!/bin/bash
shellcheck root/etc/rc.installer_cleanup
shellcheck root/private/var/root/bootstrap.sh
shellcheck root/private/var/root/macos.sh
shellcheck scripts/postinstall
shellcheck scripts/preinstall
#bashate root/etc/rc.installer_cleanup
#bashate root/private/var/root/bootstrap.sh
#bashate root/private/var/root/macos.sh
#bashate scripts/postinstall
#bashate scripts/preinstall
