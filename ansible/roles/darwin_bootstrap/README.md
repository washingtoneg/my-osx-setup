darwin_bootstrap
================

`darwin_bootstrap` is an ansible role that can be utilized to configure new laptops for Compass Engineers.

Requirements
------------

No special requirements; note that some tasks in this role require root access, so be sure to to prompt for the user's `become` password.

Role Variables
--------------

Available variables are set with default values (see defaults/main.yml) or are provided by the user at run time.

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
