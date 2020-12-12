VERSION = 0.0.1-BETA

all: skipper-install.sh

skipper-install.sh: src/init.sh src/skipper-run
	echo 'echo -n "Please enter the install path for skipper (defaults to $$HOME/.skipper): "' >skipper-install.sh
	echo 'read skipperPath' >>skipper-install.sh
	echo 'skipperPath=$${skipperPath:-$$HOME/.skipper}' >>skipper-install.sh
	echo 'skipperPath=`readlink -f $$skipperPath`' >>skipper-install.sh
	echo '' >>skipper-install.sh
	echo '[ -e "$$skipperPath" ] || mkdir "$$skipperPath"' >>skipper-install.sh
	echo '[ -e "$$skipperPath/bin" ] || mkdir "$$skipperPath/bin"' >>skipper-install.sh
	echo '[ -e "$$skipperPath/envs" ] || mkdir "$$skipperPath/envs"' >>skipper-install.sh
	echo '[ -e "$$skipperPath/envs/base" ] || mkdir "$$skipperPath/envs/base"' >>skipper-install.sh
	echo '[ -e "$$skipperPath/envs/base/bin" ] || mkdir "$$skipperPath/envs/base/bin"' >>skipper-install.sh
	echo '[ -e "$$skipperPath/envs/base/containers" ] || mkdir "$$skipperPath/envs/base/containers"' >>skipper-install.sh
	echo '[ -e "$$skipperPath/envs/base/commands" ] || touch "$$skipperPath/envs/base/commands"' >>skipper-install.sh
	echo 'cat >"$$skipperPath/bin/skipper-run" <<'"'"'EOF'"'"'' >>skipper-install.sh
	cat src/skipper-run >>skipper-install.sh
	echo '\nEOF' >>skipper-install.sh
	echo 'chmod 0755 $$skipperPath/bin/skipper-run'
	echo '' >>skipper-install.sh
	echo 'echo "export SKIPPER_BASE=$$skipperPath" >$$skipperPath/init.sh' >>skipper-install.sh
	echo 'cat >>"$$skipperPath/init.sh" <<'"'"'EOF'"'"'' >>skipper-install.sh
	cat src/init.sh >>skipper-install.sh
	echo '\nEOF' >>skipper-install.sh
	echo 'chmod 0755 $$skipperPath/init.sh' >>skipper-install.sh
	echo 'echo "Setup complete. Please add '"'"'. $$skipperPath/init.sh'"'"' to your .bashrc"' >>skipper-install.sh
	echo 'echo "To start using skipper now, just run '"'"'. $$skipperPath/init.sh'"'"' in your shell"' >>skipper-install.sh
	chmod 0755 skipper-install.sh
	cp skipper-install.sh skipper-install-$(VERSION).sh
	chmod 0755 skipper-install-$(VERSION).sh

