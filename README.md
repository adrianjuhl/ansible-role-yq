# Ansible role: yq

Installs [yq](https://github.com/mikefarah/yq), a command-line YAML processor.

See [yq releases](https://github.com/mikefarah/yq/releases) for a list of yq release versoins.

## Requirements

None.

## Role Variables

Role variables and their defaults.

The following role vairables are the ones that most often need a value provided that is different from their default.

See 'defaults/main.yml' for all role variables.

**yq_version**

    adrianjuhl__yq__yq_version: "v4.50.1"

The version of yq to install.

**yq_install_bin_directory**

    adrianjuhl__yq__yq_install_bin_directory: "/usr/local/bin"

The location in which to install yq.

**yq_installation_requires_become**

    adrianjuhl__yq__yq_installation_requires_become: true

Whether or not the installation requires elevated privileges.

The default install bin directory requires elevated privileges.

## Dependencies

None.

## Example Playbook
```
- hosts: "servers"
  roles:
    - role: "adrianjuhl.yq"

or

- hosts: "servers"
  tasks:
    - name: "Install yq"
      ansible.builtin.include_role:
        name: "adrianjuhl.yq"

or (install into the user's ~/.local/bin directory)

- hosts: "servers"
  tasks:
    - name: "Install yq"
      ansible.builtin.include_role:
        name: "adrianjuhl.yq"
      vars:
        adrianjuhl__yq__yqinstall_bin_directory: "{{ ansible_env.HOME }}/.local/bin"
```

## Extras

### Install script

For convenience, a bash script is also supplied that facilitates easy installation of yq on localhost (the script executes ansible-galaxy to install the role and then executes ansible-playbook to run a playbook that includes the yq role).

The script can be run like this:
```
$ git clone git@github.com:adrianjuhl/ansible-role-yq.git
$ cd ansible-role-yq
$ .extras/bin/install_yq.sh
```

## License

MIT

## Author Information

[Adrian Juhl](http://github.com/adrianjuhl)

## Ansible Galaxy adrianjuhl.yq role

[https://galaxy.ansible.com/ui/standalone/roles/adrianjuhl/yq/versions/](https://galaxy.ansible.com/ui/standalone/roles/adrianjuhl/yq/versions/)

## Source Code

[https://github.com/adrianjuhl/ansible-role-yq](https://github.com/adrianjuhl/ansible-role-yq)
