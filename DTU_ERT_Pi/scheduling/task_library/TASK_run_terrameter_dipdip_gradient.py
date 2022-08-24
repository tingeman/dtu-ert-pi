#!/usr/bin/python3

import sys
import time

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
from io_scripts import gpio_relay

@add_task
def run_terrameter_dipdip_gradient(*args, boot_delay=None, **kwargs):
    power_off = True
    cmd_file = 'command_2x32_dipdip_ecr_1sec_no_upload'
    cmd_file2 = 'command_2x32_gradient_ecr_1sec'

    terrameter.wake_and_run(cmd_file, boot_delay=boot_delay, power_off=power_off)

    time.sleep(3*60)
    terrameter.log_to_file('Powering off Terrameter', echo=True)
    gpio_relay.set_relay_off()

    terrameter.log_to_file('Waiting 3 min before next launch sequence', echo=True)
    time.sleep(3*60)

    if 'boot_delay2' in kwargs:
        terrameter.wake_and_run(cmd_file2, boot_delay=boot_delay, boot_delay2=kwargs['boot_delay2'], power_off=power_off)
    else:
        terrameter.wake_and_run(cmd_file2, power_off=power_off)


if __name__ == '__main__':
    if len(sys.argv) >= 3:
        # If a second input argument is present, it is boot_delay for the second run
        # First input argument is boot_delay for the first boot-up
        run_terrameter_dipdip_gradient(boot_delay=int(sys.argv[1]), boot_delay2=int(sys.argv[2]))
    elif len(sys.argv) >= 2:
        run_terrameter_dipdip_gradient(boot_delay=int(sys.argv[1]))
    else:
        run_terrameter_dipdip_gradient()