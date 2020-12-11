#!/bin/bash

echo -n "Please enter the install path for skipper (defaults to $HOME/.skipper): "
read skipperPath
skipperPath=${skipperPath:-$HOME/.skipper}
skipperPath=`readlink -f $skipperPath`

# Make sure the required directories are all set up and populated
[ -e "$skipperPath" ] || mkdir "$skipperPath"
[ -e "$skipperPath/bin" ] || mkdir "$skipperPath/bin"
[ -e "$skipperPath/bin/skipper-run" ] || (
    cat >"$skipperPath/bin/skipper-run" <<EOF
environment="\$SKIPPER_ENV"
cmd=\`echo \$0 | grep -o '[^/]*\$'\`
container=\`grep -Po "^\$cmd/\\\\K.*\\\$" $skipperPath/envs/\$environment/commands | tail -n1\`
singularity exec "$skipperPath/envs/\$environment/containers/\$container" \$cmd \$@
EOF
    chmod 0755 "$skipperPath/bin/skipper-run"
)
[ -e "$skipperPath/envs" ] || mkdir "$skipperPath/envs"
[ -e "$skipperPath/envs/base" ] || mkdir "$skipperPath/envs/base"
[ -e "$skipperPath/envs/base/bin" ] || mkdir "$skipperPath/envs/base/bin"
[ -e "$skipperPath/envs/base/containers" ] || mkdir "$skipperPath/envs/base/containers"
[ -e "$skipperPath/envs/base/commands" ] || touch "$skipperPath/envs/base/commands"
[ -e "$skipperPath/init.sh" ] || (
    cat >"$skipperPath/init.sh" <<EOF
export PATH="$skipperPath/bin:$skipperPath/envs/base/bin:\$PATH"
__skipper_get_env_path() {
    (echo \$PATH | grep -Pio "$skipperPath/envs/[^:]*") || echo "$skipperPath/envs/base/bin"
}

__skipper_get_env_name() {
    (echo \$PATH | grep -Pio "$skipperPath/envs/\\K[^/]*") || echo "base"
}

skipper() {
    cmd=\$1
    case "\$cmd" in
        activate)
            env=\${2:-base}
            if [ -e "$skipperPath/envs/\$env" ]; then
                export PATH=\`echo \$PATH | sed -e "s:\$(__skipper_get_env_path):$skipperPath/envs/\$env/bin:g"\`
                export SKIPPER_ENV=\$env
                hash -r
                echo "Activated environment \$env"
            else
                echo "Could not find skipper environment \$env"
            fi
        ;;

        deactivate)
            env="base"
            oldEnv="\$(__skipper_get_env_name)"
            export PATH=\`echo \$PATH | sed -e "s:\$(__skipper_get_env_path):$skipperPath/envs/\$env/bin:g"\`
            export skipper_ENV=\$env
            hash -r
            echo "Deactivated environment \$oldEnv, returned to base"
        ;;

        list)
            if [ "\$2" = 'containers' ]; then 
                ls "$skipperPath/envs/\$(__skipper_get_env_name)/containers"
            elif [ "\$2" = 'commands' ]; then
                grep -Po '^[^/]*' "$skipperPath/envs/\$(__skipper_get_env_name)/commands" | sort -u | tr '\\n' ' '
                echo
            else
                ls "$skipperPath/envs"
            fi
        ;;

        env)
            __skipper_get_env_name
        ;;

        create)
            env=\$2
            if [ ! -e "$skipperPath/envs/\$env" ]; then
                mkdir "$skipperPath/envs/\$env"
                mkdir "$skipperPath/envs/\$env/bin"
                touch "$skipperPath/envs/\$env/commands"
                mkdir "$skipperPath/envs/\$env/containers"
                skipper activate "\$env"
                echo "Created and activated new environment \$env"
            else
                echo "The skipper environment \$env already exists"
            fi
        ;;

        import)
            container=\$2
            cp -r "\$container" "$skipperPath/envs/\$(__skipper_get_env_name)/containers/"
            echo "Container \$container imported into environment \$(__skipper_get_env_name)"
        ;;

        register)
            container=\$2
            command=\$3
            if [ -e "$skipperPath/envs/\$(__skipper_get_env_name)/containers/\$container" ]; then
                ln -s "$skipperPath/bin/skipper-run" "$skipperPath/envs/\$(__skipper_get_env_name)/bin/\$command"
                echo "\$command/\$container" >> "$skipperPath/envs/\$(__skipper_get_env_name)/commands"
                hash -r
                echo "Registered the command \$command to execute in container \$container"
            else
                echo "Could not find the singularity container \$container"
            fi
        ;;

        help)
            echo "skipper - singularity container management system"
            echo "Available commands:"
            echo "activate [env] - activates the environment [env]"
            echo "create [env] - creates a new environment with name [env]"
            echo "deactivate - returns to the base environment"
            echo "env - prints the current environment"
            echo "help - prints this help message"
            echo "import [container] - imports the singularity [container] into the current environment"
            echo "list - lists all available environments"
            echo "list commands - lists all commands registered in this environments bin"
            echo "list containers - lists all containers that have been imported into the current environment"
            echo "register [container] [command] - sets [command] to be executed on [container] in the current environment"
        ;;

        *)
            echo "Did not recognize command \$command"
        ;;
    esac
}   
EOF
    chmod 0755 "$skipperPath/init.sh"
)

echo "Setup complete. Please add '. $skipperPath/init.sh' to your .bashrc"
echo "To start using skipper now, just run '. $skipperPath/init.sh' in your shell"