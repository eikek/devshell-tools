# devshell tools

This is a collection of tools for creating dev environments with nix
flakes. It doesn't create something new, but relies on NixOS modules
and nixpkgs. The flake provides services that are only a wrapper
around existing ones with an opinionated config towards ease of use in
a dev environment.

## Usage

A template is provided to get started:
```shell
nix flake init -t github:eikek/devshell-tools
```

The flake provides several modules that can be used selectively. There
are two functions that create vm or a container with all modules
included. You could use it like this:

```nix
  inputs.devshell-tools.url = ...
  ...
  nixosConfigurations = {
    dev-vm = devshell-tools.lib.mkVm {
      system = "x86_64-linux";
      modules = [
        {
          services.dev-solr.enable = true;
          services.dev-email.enable = true;
          services.dev-postgres.enable = true;
          services.dev-mariadb.enable = true;
          services.openapi-docs.enable = true;
        }
      ];
    };
    container = devshell-tools.lib.mkContainer {
      system = "x86_64-linux";
      modules = [
        {
          services.dev-solr.enable = true;
          services.dev-email.enable = true;
          services.dev-postgres.enable = true;
          services.dev-mariadb.enable = true;
          services.openapi-docs.enable = true;
        }
      ];
    };
  }
```

The vm has a root account with password `root`. Additionally, a
passwordless ssh key is configured.

In your module you can then enable and configure the provided modules.

The vm adds port-forwarding to the services by default. This can be
changed in your module using the supplied shortcuts:

```nix
port-forward.ssh = 10022;
port-forward.dev-postgres = 6543;
port-forward.dev-smtp = 1587;
port-forward.dev-imap = 1143;
port-forward.dev-webmail = 8080;
…
```

With this, it is possible to ssh into the vm from port `10022` on the
host for example. Of course, the standard
`virtualisation.forwardPorts` can be used as well.

## Content

### Packages

#### solr

Nixpkgs dropped solr. So a simple package is included here.

#### swagger-ui

Packages the swagger-ui npm package to render openAPI specs in the
browser. It is used by the `openapi-docs` module.

#### vm scripts

A collection of small scripts to manage development vms that are
defined as `nixosConfigurations` in your flake. They are just some
convenience shortcuts to a bit longer nix commands.

For example, `vm-build` runs `nix build
".#nixosConfigurations.$name.config.system.build.vm"` where `$name` is
the value of `DEV_VM` environment variable, or the default `dev-vm`.
This name must have a corresponding `nixosConfiguration` to build.

The vm-scripts all start with `vm-` for easier lookup. They are
provided as `vm-scripts` attribute set in `legacyPackages` so they can
be installed all at once.

Example use:
```nix
inputs.devshell-tools.url = …

devShells.default = {
  buildInputs = builtins.attrValues devshell-tools.legacyPackages.${system}.vm-scripts;
};
```

#### cnt scripts

A collection of small scripts to manage dev containers that are
defined as `nixosConfigurations` in your flake.

For example, `cnt-recreate` deletes an existing container, creates it
anew and starts it. The container name is taken from the
`DEV_CONTAINER` environment variable or defaults to `dev-cnt`. If no
container name is given it uses either `dev-cnt` or `container` if
`dev-cnt` is not defined in `nixosConfigurations`.

The cnt-scripts all start with `cnt-` for easier lookup. They are
provided as `cnt-scripts` attribute set in `legacyPackages` so they
can be installed all at once.

Example use:
```nix
inputs.devshell-tools.url = …

devShells.default = {
  buildInputs = builtins.attrValues devshell-tools.legacyPackages.${system}.cnt-scripts;
};
```

### Lib

The `lib` output has a few function that might be interesting to use
in devshells.

- `installScript`: tbh, I'm probably missing something but I couldn't
  find it. The function takes a source script as input, makes it
  executable and puts it into the store behind a `bin/` path so it
  will be in your environment. It is only a thin wrapper around
  `concatTextFile`. I found it useful when extracting longer scripts
  into their own files.
- `mkVm` and `mkContainer`: Given a list of additional modules (and
  `system`…), it creates a NixOS container or vm that has all packages
  and modules of this flake included.

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

Roundcube is configured inside nginx to access the mails of all users.
It connects to the internal dovecot and exim services. It has been
patched to allow non-standard email addresses, so it can send to
`myuser@localhost` for example and it is then possible to test bad
input more easily.

#### redis

Sets up a single redis instance with global access.

#### minio

Sets up minio with the defaults, root user "minioadmin" and same
password.

#### OpenAPI Docs

Given an URL to a open api spec, sets up nginx to serve the rendered
documentation page.
