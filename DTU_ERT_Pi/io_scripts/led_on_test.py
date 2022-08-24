#!/usr/bin/python3

import time
from pathlib import Path

# All scripts/modules must have the following construct as the
# first custom import, after importing all installed packages.
# It will add to sys.path the path to the top-level folder (DTU_ERT_pi)
# and allow absolute imports of/from modules in all submodules and packages.
# And it will import the CONFIG dictionarry with settings from 
# DTU_ERT_py.python_config.yml.
try:
    # this is needed when file is imported as a 
    # module from another file/script/module
    from .config import CONFIG
except ImportError:
    # this is needed when file is run as a script
    from config import CONFIG

# Use hereafter absolute imports, based on top level folder (DTU_ERT_pi)
from io_scripts.ina219 import INA219
from io_scripts import gpio_relay


# log voltage settings
i2c_bus = CONFIG['INA219']['i2c_bus']
shunt_resistance = CONFIG['INA219']['shunt_resistance']

#turn_on_threshold = CONFIG['TERRAMETER']['turn_on_threshold']    # volt
turn_on_threshold = 8    # volt

ina_available = True

try:
    ina = INA219(i2c_bus, shunt_resistance)
    ina.configure(ina.RANGE_32V, ina.GAIN_AUTO)
except Exception as e:
    print('Problem configuring INA219 device. Exception caught: {0}'.format(repr(e)))
    ina_available = False

if ina_available:
    print('Current draw: {0:.2f} mA'.format(ina.current()))
    print('Input voltage: {0:.2f} V'.format(ina.voltage()))

    if ina.voltage() >= turn_on_threshold:
        gpio_relay.set_relay_on()
        print('Threshold exceeded, relay ON!')
    else:
        gpio_relay.set_relay_off()
        print('Threshold NOT exceeded, relay OFF!')
else:
    gpio_relay.set_relay_on()
    print('Voltage unavailable, setting relay ON anyway!')

