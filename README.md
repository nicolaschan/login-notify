# SSH Login Notify
Get notified of SSH logins

## Features
- Send emails with the [Mailgun API](https://documentation.mailgun.com/en/latest/quickstart-sending.html#send-with-smtp-or-api)
- IP range whitelisting

## Usage
Set the following configuration variables at the top of the script:

```bash
API_KEY="<Mailgun API Key>"
MAILGUN_URL="https://api.mailgun.net/v3/<Mailgun Domain>.mailgun.org/messages"
RECIPIENTS="Foo Bar <foo@example.com>, Baz Bar <baz@example.com>" # For multiple, comma separate
FROM="SSH Alert <sshd@mycomputer.example.com>"
```

You can whitelist certain IP addresses if you are not concerned about logins from those IPs. Add each IP address on each line of `ip-whitelist.txt`, which should be in the same directory as `login-notify.sh`. You can also specify IP ranges using [CIDR notation](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing#CIDR_notation), such as `192.168.0.0/24`.

```txt
127.0.0.1
```

As per [(1)](https://askubuntu.com/a/448602), have the script run when an SSH login occurs by adding it to `/etc/pam.d/sshd`:

```bash
session optional pam_exec.so seteuid /path/to/login-notify.sh
```

## Reference
1. [https://askubuntu.com/a/448602](https://askubuntu.com/a/448602)
