#! /bin/bash

function install-gitlab {
	# Update repositary
	apt-get update

	# Install required dependencies
	echo postfix postfix/mailname string gitlab.nctucs.net | debconf-set-selections
	echo postfix postfix/main_mailer_type select Internet Site | debconf-set-selections
	apt-get install -y curl openssh-server ca-certificates postfix

	# Execute installation script & install
	curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | bash
	apt-get install -y gitlab-ce
	gitlab-ctl reconfigure
}

function set-gitlab-password {
	gitlab-rails console production <<EOF
	user = User.where(id: 1).first
	user.password = '$1'
	user.password_confirmation = '$1'
	user.save!
EOF
}

install-gitlab
set-gitlab-password 'gitlab.nctucs.net'
