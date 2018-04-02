# SSH Login Notify
Get notified of SSH logins

## Features
- Send emails with the [Mailgun API](https://documentation.mailgun.com/en/latest/quickstart-sending.html#send-with-smtp-or-api)
- IP range whitelisting

## Usage
Set the following configuration variables in `config.sh`, which should be in the same directory as `login-notify.sh`:

```bash
API_KEY="<Mailgun API Key>"
MAILGUN_URL="https://api.mailgun.net/v3/<Mailgun Domain>.mailgun.org/messages"
RECIPIENTS="Foo Bar <foo@example.com>, Baz Bar <baz@example.com>" # For multiple, comma separate
FROM="SSH Alert <sshd@mycomputer.example.com>"
```

You can whitelist certain IP addresses if you are not concerned about logins from those IPs. Currently, only IPv4 is supported. Add each IP address on each line of `ip-whitelist.txt`, which should be in the same directory as `login-notify.sh`. You can also specify IP ranges using [CIDR notation](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing#CIDR_notation), such as `192.168.0.0/24`.

```txt
127.0.0.1
```

As per [(1)](https://askubuntu.com/a/448602), have the script run when an SSH login occurs by adding it to `/etc/pam.d/sshd`:

```bash
session optional pam_exec.so seteuid /path/to/login-notify.sh
```

## Installation Script
For convenience, an installation script is provided. It is recommended to install manually because the installation script might not work on all computers/operating systems. The installation script will install the repository in `/etc/ssh/login-notify` and will add the required line to `/etc/pam.d/sshd`.

For security, always inspect foreign scripts before running them on your computer (especially with sudo access).

```bash
curl -O https://raw.githubusercontent.com/nicolaschan/login-notify/master/install.sh
chmod +x install.sh
# Inspect the script for security
sudo ./install.sh 
```

## Supported Platforms
This program has been tested on the following platforms:
- Linux Mint 18.3 Sylvia
- Ubuntu 17.10

## Reference
1. [https://askubuntu.com/a/448602](https://askubuntu.com/a/448602)
