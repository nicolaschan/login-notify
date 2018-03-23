#!/bin/bash

INSTALL_PREFIX="/etc/ssh/login-notify"

echo "Cloning git repository"
git clone https://github.com/nicolaschan/login-notify.git $INSTALL_PREFIX

echo "Appending line to /etc/pam.d/sshd"
echo "session optional pam_exec.so seteuid $INSTALL_PREFIX/login-notify.sh # Added by login-notify install script" >> /etc/pam.d/sshd
nano "$INSTALL_PREFIX/config.sh"

echo "Make sure you have set your configuration in $INSTALL_PREFIX/config.sh"
echo "More info: https://github.com/nicolaschan/login-notify/blob/master/README.md"
