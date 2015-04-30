#!/usr/bin/env bash

# DOWNLOADED FROM: https://raw.github.com/progrium/dokku/v0.3.17/bootstrap.sh

# A script to bootstrap dokku.
# It expects to be run on Ubuntu 14.04 via 'sudo'
# It checks out the dokku source code from Github into ~/dokku and then runs 'make install' from dokku source.

set -eo pipefail
export DEBIAN_FRONTEND=noninteractive
export DOKKU_REPO=${DOKKU_REPO:-"https://github.com/progrium/dokku.git"}

if ! command -v apt-get &>/dev/null
then
  echo "This installation script requires apt-get. For manual installation instructions, consult http://progrium.viewdocs.io/dokku/advanced-installation ."
  exit 1
fi

apt-get update
apt-get install -qq -y git make curl software-properties-common man-db help2man

[[ $(lsb_release -sr) == "12.04" ]] && apt-get install -qq -y python-software-properties

cd ~
test -d dokku || git clone $DOKKU_REPO
cd dokku
git fetch origin

if [[ -n $DOKKU_BRANCH ]]; then
  git checkout origin/$DOKKU_BRANCH
elif [[ -n $DOKKU_TAG ]]; then
  git checkout $DOKKU_TAG
fi

make install

echo
echo "Almost done! For next steps on configuration:"
echo "  http://progrium.viewdocs.io/dokku/advanced-installation#user-content-configuring"

