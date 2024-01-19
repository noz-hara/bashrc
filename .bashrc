# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi

unset rc
function cd_module() {
	local git_dir="$(git rev-parse --show-toplevel)"

	local module_dir="$(
		git -C "${git_dir}" ls-files -- \
			':!:**/src/**' \
			\
			'*.bnd' \
			'*build.xml' \
			'*pom.xml' |

			#
			# Get the directory name with sed instead of dirname because it is much faster
			#

			sed -E \
				-e 's,[^/]*$,,g' \
				\
				-e 's,/$,,g' \
				-e '/^$/d' |

			#
			# Remove duplicates because some modules have more than one *.bnd file
			#

			uniq |

			#
			# Pass the results to fzf
			#
			fzf \
				--exit-0 \
				--no-multi \
				--query "$*" \
				--select-1 \
			;
	)"

	if [ -n "${module_dir}" ]
	then
		cd "${git_dir}/${module_dir}" || return 1
	fi
}

function customize_aliases {
	alias ac="ant compile"
	alias acc="ant clean compile"
	alias ad="ant deploy"
	alias af="ant format-source"
	alias afcb="ant format-source-current-branch"

	alias cdm="cd_module"
	alias cdt="cd ~/dev/projects/liferay-portal"

	alias d="docker"
	alias dmysqlclient="docker exec -it galatians-mysql mysql -utest -ptest"
	alias dmysqlserver="docker run --name galatians-mysql --rm -d -e MYSQL_ALLOW_EMPTY_PASSWORD=yes -e MYSQL_DATABASE=lportal -e MYSQL_PASSWORD=test -e MYSQL_USER=test -p 3306:3306 mysql:8 --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci"
	alias dpsqlclient="docker exec -it galatians-psql psql -U postgres"
	alias dpsqlserver="docker run --name galatians-psql --rm -d -e POSTGRES_PASSWORD=test -p 5432:5432 postgres:13"

	alias g="git"
	alias gfpr="git_fetch_pr ${1}"
	alias gg="git_grep"
	alias gi="gpr info"
	alias gpr="~/dev/projects/git-tools/git-pull-request/git-pull-request.sh"

	alias java6="switch_to_java_6"
	alias java7="switch_to_java_7"
	alias java8="switch_to_java_8"
	alias java11="switch_to_java_11"
	alias java17="switch_to_java_17"

	alias la="ls -la --group-directories-first"
	alias la2="ls --full-time"
	alias more="more -e"

	alias osub="/opt/sublime_text/sublime_text ${@}"
	alias osubg="open_sublime_git ${@}"
}

function customize_path {
	export ANT_HOME="/opt/java/ant"
	export ANT_OPTS="-Xmx6144m"

	export DOCKER_HOST=unix:///run/user/$(id -u me)/docker.sock

	export GRADLE_OPTS=${ANT_OPTS}

	if [ -z ${JAVA_HOME+x} ]
	then
		export JAVA_HOME="/opt/java/jdk"
	fi

	export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/local/apr/lib"

	export LINUX_WITH_BTRFS=true

	export NPM_CONFIG_PREFIX=~/.npm-global

	export PATH="${ANT_HOME}/bin:${JAVA_HOME}/bin:${NPM_CONFIG_PREFIX}/bin:/opt/java/maven/bin:~/jpm/bin:~/test:${PATH}"
}

function customize_prompt {
	PS1="\[\e]0;\w\a\]\n\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\] \$(parse_git_current_branch_with_parentheses)\n\$ "

	#
	# https://forums.fedoraforum.org/showthread.php?326174-stop-konsole-highlighting-pasted-text
	# https://newbedev.com/remote-ssh-commands-bash-bind-warning-line-editing-not-enabled
	#

	#if [ -t 1 ]
	#then
	#	bind "set enable-bracketed-paste off"
	#fi
}

function disable_history {
	unset HISTFILE
}

function execute_gradlew {
	if [ -e gradlew ]
	then
		./gradlew ${@}
	elif [ -e ../gradlew ]
	then
		../gradlew ${@}
	elif [ -e ../../gradlew ]
	then
		../../gradlew ${@}
	elif [ -e ../../../gradlew ]
	then
		../../../gradlew ${@}
	elif [ -e ../../../../gradlew ]
	then
		../../../../gradlew ${@}
	elif [ -e ../../../../../gradlew ]
	then
		../../../../../gradlew ${@}
	elif [ -e ../../../../../../gradlew ]
	then
		../../../../../../gradlew ${@}
	elif [ -e ../../../../../../../gradlew ]
	then
		../../../../../../../gradlew ${@}
	elif [ -e ../../../../../../../../gradlew ]
	then
		../../../../../../../../gradlew ${@}
	elif [ -e ../../../../../../../../../gradlew ]
	then
		../../../../../../../../../gradlew ${@}
	else
		echo "Unable to find locate Gradle wrapper."
	fi
}

function git_fetch_pr {
	if [[ "${1}" != */github\.com/* ]] ||
	   [[ "${1}" != */pull/* ]]
	then
		echo "URL ${1} does not point to a GitHub pull request."
	else
		IFS='/' read -r -a github_pr_parts <<< "${1}"

		git fetch --no-tags git@github.com:${github_pr_parts[3]}/${github_pr_parts[4]}.git pull/${github_pr_parts[6]}/head:pr-${github_pr_parts[6]}
	fi
}

function git_grep {
	if [ ${#} -eq 1 ]
	then
		git --no-pager grep --files-with-matches "${1}"
	elif [ ${#} -eq 2 ]
	then
		git --no-pager grep --files-with-matches "${1}" -- "${2}"
	elif [ ${#} -eq 3 ]
	then
		git --no-pager grep --files-with-matches "${1}" -- "${2}" "${3}"
	elif [ ${#} -eq 4 ]
	then
		git --no-pager grep --files-with-matches "${1}" -- "${2}" "${3}" "${4}"
	fi
}

function gw {
	execute_gradlew "${@//\//:}" --daemon
}

function include_custom_bashrc {
	if [ -e ~/.bashrc.custom ]
	then
		. ~/.bashrc.custom
	fi
}

#
# Usage:
#
#    osubg
#    osubg <hash1>
#    osubg <hash1> <hash2>
#

function open_sublime_git {
	local hash1=${1}

	if [ -z ${hash1} ]
	then
		hash1="$(git branch --show-current)"
	fi

	local repository_dir="$(git rev-parse --show-toplevel)"

	local branch=$(git config --get git-pull-request.${repository_dir}.update-branch)

	if [ -z ${branch} ]
	then
		branch="master"
	fi

	local hash2=${2}

	if [ -z ${hash2} ]
	then
		hash2=${branch}
	fi

	local hash_range="${hash2}..${hash1}"

	echo ""
	echo "Opening files in the range ${hash_range}."

	for file in $(git diff ${hash_range} --name-only | head -n 100)
	do
		/opt/sublime_text/sublime_text "${repository_dir}/${file}" 2>/dev/null || printf "\nUnable to open ${file}."
	done
}

function parse_git_branch {
	GIT_DIR_NAME=$(git rev-parse --show-toplevel)

	GIT_DIR_NAME=${GIT_DIR_NAME##*/}

	if [[ "${GIT_DIR_NAME}" =~ -ee-[0-9][^\-]*$ ]]
	then
		echo "ee-${GIT_DIR_NAME##*-ee-}"
	elif [[ "${GIT_DIR_NAME}" =~ -[0-9][^\-]*$ ]]
	then
		echo "${GIT_DIR_NAME##*-}"
	elif [[ "${GIT_DIR_NAME}" =~ com-liferay-osb-asah-private$ ]]
	then
		echo "7.0.x"
	elif [[ "${GIT_DIR_NAME}" =~ -private$ ]]
	then
		echo "${GIT_DIR_NAME}" | sed 's/.*-\([^\-]*\)-private$/\1-private/'
	else
		echo "master"
	fi
}

function parse_git_current_branch {
	git rev-parse --abbrev-ref HEAD 2>/dev/null
}

function parse_git_current_branch_with_parentheses {
	parse_git_current_branch | sed 's/.*/(&)/'
}

function print_liferay_motd {
	if [ -e /tmp/liferay-motd ]
	then
		cat /tmp/liferay-motd
	fi
}

function switch_to_java_6 {
	export JAVA_HOME="/opt/java/jdk6"

	export PATH="${JAVA_HOME}/bin:${PATH}"
}

function switch_to_java_7 {
	export JAVA_HOME="/opt/java/jdk7"

	export PATH="${JAVA_HOME}/bin:${PATH}"
}

function switch_to_java_8 {
	export JAVA_HOME="/opt/java/jdk8"

	export PATH="${JAVA_HOME}/bin:${PATH}"
}

function switch_to_java_11 {
	export JAVA_HOME="/opt/java/jdk11"

	export PATH="${JAVA_HOME}/bin:${PATH}"
}

function switch_to_java_17 {
	export JAVA_HOME="/opt/java/jdk17"

	export PATH="${JAVA_HOME}/bin:${PATH}"
}

customize_aliases
customize_path
customize_prompt
disable_history

include_custom_bashrc

print_liferay_motdeval "$(~/.local/bin/mise activate bash)"
eval "$(~/.local/bin/mise activate bash)"
