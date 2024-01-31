# Ubuntu config

**WIP**

This is a repo containing my postinstall script and config files for a fresh ubuntu installation

## How to install

Ubuntu comes with `wget`, so we can use it to download the `postinstall-script.sh` script and run it immediately:

```sh
wget sh -c "$(wget -O- https://raw.githubusercontent.com/iskandervdh/ubuntu-config/main/postinstall-script.sh)"
```

Or you can download it first to be able to inspect it and then run it:

```sh
wget https://raw.githubusercontent.com/iskandervdh/ubuntu-config/main/postinstall-script.sh
sh install.sh
```
