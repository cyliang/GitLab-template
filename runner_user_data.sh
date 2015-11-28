#! /bin/bash

function install-runner {
	curl -sSL https://get.docker.com/ | sh
	curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-ci-multi-runner/script.deb.sh | bash
	apt-get install -y gitlab-ci-multi-runner
}

function register-runner {
	gitlab-ci-multi-runner register \
		--non-interactive \
		--url "http://$1/ci/" \
		--registration-token "$2" \
		--description 'The shared-runner for all users.' \
		--executor 'docker' \
		--docker-image ruby:2.1
}

install-runner
register-runner $GITLAB_IP $REGISTRATION_TOKEN
