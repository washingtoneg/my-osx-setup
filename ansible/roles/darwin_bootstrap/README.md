darwin_bootstrap
================

`darwin_bootstrap` is an ansible role that can be utilized to configure a new laptop.

Requirements
------------

No special requirements; note that some tasks in this role require root access, so be sure to to prompt for the user's `become` password.

Role Variables
--------------

Available variables are set with default values (see defaults/main.yml) or are provided by the user at run time.

You will have to have `GITHUB_API_TOKEN` set in your environment. Navigate to your [GitHub settings](https://github.com/settings/tokens/new) to create a new personal access token with the **`admin:public_key`**, **`read:user`**, and **`read:email`**  scopes selected.

Example Playbook
----------------

Here is a simple example of using the role in a playbook:

    - hosts: localhost
      roles:
         - { role: darwin_bootstrap }

License
-------

All rights reserved

Author Information
------------------

[washingtoneg](https://github.com/washingtoneg)
