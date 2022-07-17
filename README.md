# Onedrive clenup versions

*Leia este guia em [Português](README.pt-br.md).*

This script workaround a limitation of OneDrive for Business, which doesn't allow you to reduce the number of versions to less than 100.

### Requirements:
- curl
- jq
- [rclone](https://rclone.org/)

### How to use

Set the variables below:
```bash
REMOTE="onedrive"
VERSIONS_TO_KEEP=3
```

and execute the script:
```bash
$ ./onedrive-clean-versions.sh onedrive-folder
```

## Thanks
Thanks to everyone involved in issue [#4106](https://github.com/rclone/rclone/issues/4106) of [rclone](https://rclone.org/), especially for [Saoneth](https://github.com/Saoneth) and [Zvezdin](https://github.com/Zvezdin) who created the first version of this script.
