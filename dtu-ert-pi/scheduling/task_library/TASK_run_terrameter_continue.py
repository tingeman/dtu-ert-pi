#!/usr/bin/python3

import sys

# All TASK scripts/modules must have the following construct as the
# first custom import, after importing all installed packages.
# It will import the add_task decorator, needed to register the task
# in the task_library
# It will also add to sys.path the path to the top-level folder (DTU_ERT_pi)
# and allow absolute imports of/from modules in all submodules and packages.
# And it will import the CONFIG dictionarry with settings from 
# DTU_ERT_py.python_config.yml.
try:
    # this is needed when file is imported as a 
    # module from another file/script/module
    from .base_task import add_task, CONFIG
except ImportError:
    # this is needed when file is run as a script
    from base_task import add_task, CONFIG

# Use hereafter absolute imports, based on top level folder (DTU_ERT_pi)
from io_scripts import run_terrameter_go_script as terrameter

@add_task
def run_terrameter_continue(*args, boot_delay=None, **kwargs):
    cmd_file = 'command_continue'    

    terrameter.wake_and_run(cmd_file, boot_delay=boot_delay)


if __name__ == '__main__':
    if len(sys.argv) > 1:
        run_terrameter_continue(boot_delay=int(sys.argv[1]))
    else:
        run_terrameter_continue()


