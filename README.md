# Ansible role: yq

Installs [yq](https://github.com/mikefarah/yq), a command-line YAML processor.

## Requirements

None.

## Role Variables

None.

## Dependencies

None.

## Example Playbook
```
- hosts: servers
  roles:
    - { role: adrianjuhl.yq, become: true }

or

- hosts: servers
  tasks:
    - name: Install yq
      ansible.builtin.include_role:
        name: adrianjuhl.yq
        apply:
          become: true

or (install into the user's ~/.local/bin directory)

- hosts: servers
  tasks:
    - name: Install yq
      ansible.builtin.include_role:
        name: adrianjuhl.yq
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
