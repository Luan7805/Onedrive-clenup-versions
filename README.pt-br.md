# Limpar versões arquvios onedrive

*Read this in [English](README.md).*

Esse script contorna a limitação do OneDrive for Business, que não permite que reduzir o número de versões para menos de 100.

### Requisitos:
- curl
- jq
- [rclone](https://rclone.org/)

### Como usar

Altere as variáveis abaixo:
```bash
REMOTE="onedrive"
VERSIONS_TO_KEEP=3
```

e execute o script:
```bash
$ ./onedrive-clean-versions.sh pasta-do-onedrive
```

## Agradecimentos
Um agaradecimento a todos os envolvidos na issue [#4106](https://github.com/rclone/rclone/issues/4106) do [rclone](https://rclone.org/), em especial para o [Saoneth](https://github.com/Saoneth) e o [Zvezdin](https://github.com/Zvezdin) que criaram a primeira versão desse script.
