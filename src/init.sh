export PATH="$SKIPPER_BASE/bin:$SKIPPER_BASE/envs/base/bin:$PATH"

__skipper_get_env_path() {
    (echo $PATH | grep -Pio "$SKIPPER_BASE/envs/[^:]*") || echo "$SKIPPER_BASE/envs/base/bin"
}

__skipper_get_env_name() {
    (echo $PATH | grep -Pio "$SKIPPER_BASE/envs/\\K[^/]*") || echo "base"
}

skipper() {
    cmd=${1:-help}
    case "$cmd" in
        activate)
            env=${2:-base}
            if [ -e "$SKIPPER_BASE/envs/$env" ]; then
                export PATH=`echo $PATH | sed -e "s:$(__skipper_get_env_path):$SKIPPER_BASE/envs/$env/bin:g"`
                export SKIPPER_ENV=$env
                hash -r
                echo "Activated environment $env"
            else
                echo "Could not find skipper environment $env"
            fi
        ;;

        deactivate)
            env="base"
            oldEnv="$(__skipper_get_env_name)"
            export PATH=`echo $PATH | sed -e "s:$(__skipper_get_env_path):$SKIPPER_BASE/envs/$env/bin:g"`
            export skipper_ENV=$env
            hash -r
            echo "Deactivated environment $oldEnv, returned to base"
        ;;

        list)
            if [ "$2" = 'containers' ]; then 
                ls "$SKIPPER_BASE/envs/$(__skipper_get_env_name)/containers"
            elif [ "$2" = 'commands' ]; then
                grep -Po '^[^/]*' "$SKIPPER_BASE/envs/$(__skipper_get_env_name)/commands" | sort -u | tr '\n' ' '
                echo
            else
                ls "$SKIPPER_BASE/envs"
            fi
        ;;

        env)
            __skipper_get_env_name
        ;;

        create)
            env=$2
            if [ ! -e "$SKIPPER_BASE/envs/$env" ]; then
                mkdir "$SKIPPER_BASE/envs/$env"
                mkdir "$SKIPPER_BASE/envs/$env/bin"
                touch "$SKIPPER_BASE/envs/$env/commands"
                mkdir "$SKIPPER_BASE/envs/$env/containers"
                skipper activate "$env"
                echo "Created and activated new environment $env"
            else
                echo "The skipper environment $env already exists"
            fi
        ;;

        import)
            container=$2
            cp -r "$container" "$SKIPPER_BASE/envs/$(__skipper_get_env_name)/containers/"
            echo "Container $container imported into environment $(__skipper_get_env_name)"
        ;;

        register)
            container=$2
            command=$3
            if [ -e "$SKIPPER_BASE/envs/$(__skipper_get_env_name)/containers/$container" ]; then
                ln -s "$SKIPPER_BASE/bin/skipper-run" "$SKIPPER_BASE/envs/$(__skipper_get_env_name)/bin/$command"
                echo "$command/$container" >> "$SKIPPER_BASE/envs/$(__skipper_get_env_name)/commands"
                hash -r
                echo "Registered the command $command to execute in container $container"
            else
                echo "Could not find the singularity container $container"
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
            echo "Did not recognize command $command"
        ;;
    esac
}   