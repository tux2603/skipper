# skipper

Tool for organizing singularity packages into working environments and integrating them into the shell.

Allows a user to set up multiple development environments, add singularity containers, and then register
any arbitrary commands to be run in a container while that environment is active. Currently, this will only
work in bash, but support for other shells are in progress.

## Commands

| Command name    | Arguments               | Description                                                                                                                                               |
| --------------- | ----------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------- |
| activate        | Environment name        | Activates the environment specified and loads its registered commands onto $PATH                                                                          |
| create          | Environment name        | Creates a new empty environment with the specified name and activates it                                                                                  |
| deactivate      | None                    | Deactivates the current environment and unloads all of it's commands from $PATH, then returns to the base environment                                     |
| env             | None                    | Prints the name of the current active environment                                                                                                         |
| help            | None                    | Prints a basic help message, similar to this table                                                                                                        |
| import          | Path to container       | Imports the specified singularity container into the current environment                                                                                  |
| list            | None                    | Lists all of the available sing environments                                                                                                              |
| list commands   | None                    | Lists all of the commands registered in the current environment                                                                                           |
| list containers | None                    | Lists all of the containers that have been imported into the current environment                                                                          |
| register        | Container name, command | Sets the specified command to be run inside of the specified container. Requires the container to have been already imported into the current environment |
