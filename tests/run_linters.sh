#!/bin/bash
shellcheck root/etc/rc.installer_cleanup
shellcheck root/private/var/root/bootstrap.sh
shellcheck root/private/var/root/macos.sh
shellcheck -x scripts/postinstall
shellcheck -x scripts/preinstall
#bashate root/etc/rc.installer_cleanup
#bashate root/private/var/root/bootstrap.sh
#bashate root/private/var/root/macos.sh
#bashate -x scripts/postinstall
#bashate -x scripts/preinstall 
