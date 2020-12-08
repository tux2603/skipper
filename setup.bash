#!/bin/bash

echo -n "Please enter the install path for sing (defaults to $HOME/.sing): "
read singPath
singPath=${singPath:-$HOME/.sing}
singPath=`readlink -f $singPath`

# Make sure the required directories are all set up and populated
[ -e "$singPath" ] || mkdir "$singPath"
[ -e "$singPath/bin" ] || mkdir "$singPath/bin"
[ -e "$singPath/bin/sing-run" ] || (
    cat >"$singPath/bin/sing-run" <<EOF
environment="\$SING_ENV"
cmd=\`echo \$0 | grep -o '[^/]*\$'\`
container=\`grep -Po "^\$cmd/\\\\K.*\\\$" $singPath/envs/\$environment/commands | tail -n1\`
singularity exec "$singPath/envs/\$environment/containers/\$container" \$cmd \$@
EOF
    chmod 0755 "$singPath/bin/sing-run"
)
[ -e "$singPath/envs" ] || mkdir "$singPath/envs"
[ -e "$singPath/envs/base" ] || mkdir "$singPath/envs/base"
[ -e "$singPath/envs/base/bin" ] || mkdir "$singPath/envs/base/bin"
[ -e "$singPath/envs/base/containers" ] || mkdir "$singPath/envs/base/containers"
[ -e "$singPath/envs/base/commands" ] || touch "$singPath/envs/base/commands"
[ -e "$singPath/init.sh" ] || (
    cat >"$singPath/init.sh" <<EOF
export PATH="$singPath/bin:$singPath/envs/base/bin:\$PATH"
__sing_get_env_path() {
    (echo \$PATH | grep -Pio "$singPath/envs/[^:]*") || echo "$singPath/envs/base/bin"
}

__sing_get_env_name() {
    (echo \$PATH | grep -Pio "$singPath/envs/\\K[^/]*") || echo "base"
}

sing() {
    cmd=\$1
    case "\$cmd" in
        activate)
            env=\${2:-base}
            if [ -e "$singPath/envs/\$env" ]; then
                export PATH=\`echo \$PATH | sed -e "s:\$(__sing_get_env_path):$singPath/envs/\$env/bin:g"\`
                export SING_ENV=\$env
                hash -r
                echo "Activated environment \$env"
            else
                echo "Could not find sing environment \$env"
            fi
        ;;

        deactivate)
            env="base"
            oldEnv="$(__sing_get_env_name)"
            export PATH=\`echo \$PATH | sed -e "s:\$(__sing_get_env_path):$singPath/envs/\$env/bin:g"\`
            export SING_ENV=\$env
            hash -r
            echo "Deactivated environment \$oldEnv, returned to base"
        ;;

        list)
            if [ "\$2" = 'containers' ]; then 
                ls "$singPath/envs/\$(__sing_get_env_name)/containers"
            elif [ "\$2" = 'commands' ]; then
                grep -Po '^[^/]*' "$singPath/envs/\$(__sing_get_env_name)/commands" | sort -u | tr '\\n' ' '
                echo
            else
                ls "$singPath/envs"
            fi
        ;;

        env)
            __sing_get_env_name
        ;;

        create)
            env=\$2
            if [ ! -e "$singPath/envs/\$env" ]; then
                mkdir "$singPath/envs/\$env"
                mkdir "$singPath/envs/\$env/bin"
                touch "$singPath/envs/\$env/commands"
                mkdir "$singPath/envs/\$env/containers"
                sing activate "\$env"
                echo "Created and activated new environment \$env"
            else
                echo "The sing environment \$env already exists"
            fi
        ;;

        import)
            container=\$2
            cp -r "\$container" "$singPath/envs/\$(__sing_get_env_name)/containers/"
            echo "Container \$container imported into environment \$(__sing_get_env_name)"
        ;;

        register)
            container=\$2
            command=\$3
            if [ -e "$singPath/envs/\$(__sing_get_env_name)/containers/\$container" ]; then
                ln -s "$singPath/bin/sing-run" "$singPath/envs/\$(__sing_get_env_name)/bin/\$command"
                echo "\$command/\$container" >> "$singPath/envs/\$(__sing_get_env_name)/commands"
                hash -r
                echo "Registered the command \$command to execute in container \$container"
            else
                echo "Could not find the singularity container \$container"
            fi
        ;;

        help)
            echo "sing - singularity container management system"
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
    chmod 0755 "$singPath/init.sh"
)

echo "Setup complete. Please add '. $singPath/init.sh' to your .bashrc"
echo "To start using sing now, just run '. $singPath/init.sh' in your shell"