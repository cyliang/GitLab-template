#! /bin/bash

function get-registration-token {
	# Directly add code into GitLab to write the registration token into some file.
	# A FIFO (named pipe) is used here to make this shell script blocked for waiting
	# the starting process of GitLab to finish.
	# The FIFO is write-only for security concern, and is deleted after receiving the token.

	SED_CMD='5a \
  open("/opt/gitlab/REGISTRATION_TOKEN", "w") { |f| \
    f.puts REGISTRATION_TOKEN \
  } \
	'
	sed -e "$SED_CMD" -i~ /opt/gitlab/embedded/service/gitlab-rails/config/initializers/4_ci_app.rb

	mkfifo /opt/gitlab/REGISTRATION_TOKEN
	chmod 222 /opt/gitlab/REGISTRATION_TOKEN

	gitlab-ctl restart

	cat /opt/gitlab/REGISTRATION_TOKEN > /dev/null
	REGISTRATION_TOKEN=`cat /opt/gitlab/REGISTRATION_TOKEN`
	mv -f /opt/gitlab/embedded/service/gitlab-rails/config/initializers/4_ci_app.rb~ /opt/gitlab/embedded/service/gitlab-rails/config/initializers/4_ci_app.rb
	rm -f /opt/gitlab/REGISTRATION_TOKEN
}

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
}

function config-gitlab {
	curl -o /etc/gitlab/gitlab.rb https://raw.githubusercontent.com/cyliang/GitLab-template/master/gitlab.rb
	sed -e "6s#GITLAB_EXTERNAL_URL#$1#g" -i /etc/gitlab/gitlab.rb

	gitlab-ctl reconfigure
}

function set-gitlab-password {
	# Change the password of root and cancel the expiration of the password to
	# make the GitLab instance available immediately.

	gitlab-rails console production <<EOF
	user = User.where(id: 1).first
	user.password = '$1'
	user.password_confirmation = '$1'
	user.password_expires_at = nil
	user.save!
EOF
}

install-gitlab
config-gitlab "http://$INSTANCE_FLOATING_IP/"
get-registration-token
set-gitlab-password '$GITLAB_ROOT_PASSWORD'
wc_notify --data-binary "{\"data\": \"$REGISTRATION_TOKEN\", \"id\": \"registration token\"}"
