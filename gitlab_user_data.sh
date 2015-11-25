#! /bin/bash

apt-get update
echo postfix postfix/mailname string gitlab.nctucs.net | debconf-set-selections
echo postfix postfix/main_mailer_type select Internet Site | debconf-set-selections
apt-get install -y curl openssh-server ca-certificates postfix
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | bash
apt-get install -y gitlab-ce
gitlab-ctl reconfigure