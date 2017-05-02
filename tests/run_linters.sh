#!/bin/bash
shellcheck root/etc/rc.installer_cleanup
shellcheck root/private/var/root/bootstrap.sh
shellcheck root/private/var/root/macos.sh
shellcheck -x scripts/postinstall
shellcheck -x scripts/preinstall
