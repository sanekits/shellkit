#!/bin/bash
# entrypoint.sh for docker-lab

echo hello >&2

[[ $PWD == /workarea ]] || die 99

echo "user: $(id -u)"
git config --global --add safe.directory '*'
make .docker-lab-postcreate || :

exec "$@"
