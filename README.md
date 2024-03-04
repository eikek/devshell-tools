# devshell tools

This is a collection of tools I tend to use more often when creating
dev environments with nix flakes.

## Content

### Packages

#### solr

Nixpkgs dropped solr. So a simple packages is included here.


### Modules

#### solr

There is a very simple module that allows to run solr on systemd. It
allows only a few configurations, but should be enough for
development.


#### postgresql

Enables PostgreSQL with settings to be able to connect to it from
anywhere. It creates a user `dev` with password `dev`.


#### mariadb

Enables MariaDB with settings to be able to connect to it easily. It
creates a user `dev` with password `dev`.


#### email

The email modules configures a complete email setup: exim for smtp,
dovecot2 for imap and roundcube for webmail.

The services are configured to allow anyone to login while the
password is the same as the user name.

Users are created on demand in dovecot. So in order to be able to send
mail to a user, you need to login once so dovecot can create the user
directory.

Roundcube is configure inside nginx to access the mails of all users.
It has been patched to allow non-standard email addresses (tlds only),
so it can send to `myuser@localhost` for example.
