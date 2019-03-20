ansible_setup
=============

`ansible_setup` is an ansible role that can be utilized to add some light-weight configuration needed by ansible to the user's filesystem.

Requirements
------------

No special requirements; note that some tasks in this role require root access, so be sure to to prompt for the user's `become` password.

Role Variables
--------------

Available variables are set with default values (see defaults/main.yml) or are provided by the user at run time. You must provide the path to your your local ansible config file in your playbook:

```
ansible_config_path: "REQUIRED"
```

Example Playbook
----------------

Here is a simple example of using the role in a playbook:

    - hosts: localhost
      roles:
         - { role: ansible_setup }

License
-------

All rights reserved

Author Information
------------------

[washingtoneg](https://github.com/washingtoneg)
