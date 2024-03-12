# /mnt folder

This folder stores the configuration files located in the /mnt folder in the remote servers, in order to perform a fresh installations without backup you need to copy those files and edit the following configurations:

- add email and api key to traefik.yml file
- add mongodb connection string to mgob config file (not able to use secrets here)
- replace mongodb-keyfile with the right mongodb secrets string
