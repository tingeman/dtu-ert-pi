#!/usr/bin/python3

import sys
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

turn_on_threshold = CONFIG['TERRAMETER']['turn_on_threshold']    # volt

on_time = 30 # seconds

#gpio = Path('/sys/class/gpio/')
#gpio81 = gpio / 'gpio81'
#gpio82 = gpio / 'gpio82'
#
#def open_gpio(gpio_num):
#    this_gpio = gpio / 'gpio{0:d}'.format(gpio_num)
#    if not this_gpio.exists():
#        with (gpio/'export').open(mode='w') as f: 
#            f.write('{0:d}'.format(gpio_num))
#    with (this_gpio/'direction').open(mode='w') as f: 
#        f.write('out')
#
#def set_gpio(gpio_num, value):
#    this_gpio = gpio / 'gpio{0:d}'.format(gpio_num)
#    with (this_gpio/'value').open(mode='w') as f: 
#        f.write('{0:d}'.format(value))
#
#def gpio_on(gpio_num):
#    set_gpio(gpio_num, 1)
#
#def gpio_off(gpio_num):
#    set_gpio(gpio_num, 0)
#
#def get_gpio(gpio_num):
#    this_gpio = gpio / 'gpio{0:d}'.format(gpio_num)
#    with (this_gpio/'value').open(mode='r') as f: 
#        value = int(f.read(1))
#    return value
#
#def toggle_gpios(gpio_a, gpio_b):
#    this_gpio_a = gpio / 'gpio{0:d}'.format(gpio_a)
#    this_gpio_b = gpio / 'gpio{0:d}'.format(gpio_b)
#    val = get_gpio(gpio_a)
#    if val:
#        gpio_off(gpio_a)
#        gpio_on(gpio_b)
#    else:
#        gpio_on(gpio_a)
#        gpio_off(gpio_b)
#    return int(not val)
#
#def set_relay_on():
#    gpio_on(81)
#    gpio_off(82)
#
#def set_relay_off():
#    gpio_off(81)
#    gpio_on(82)

ina_available = CONFIG['INA219']['installed']

if ina_available:
    try:
        ina = INA219(i2c_bus, shunt_resistance)
        ina.configure(ina.RANGE_32V, ina.GAIN_AUTO)
        print('Current draw: {0:.2f} mA'.format(ina.current()))
        print('Input voltage: {0:.2f} V'.format(ina.voltage()))
    except:
        print('INA219 not accessible')
        ina_available
else:
    print('INA219 not installed')
    ina_available = False
    
if not ina_available:
    print('Aborting...')
    sys.exit()

#open_gpio(81)
#open_gpio(82)

if ina.voltage() >= turn_on_threshold:
    gpio_relay.set_relay_on()
    print('Threshold exceeded, relay ON!')
else:
    gpio_relay.set_relay_off()
    print('Threshold NOT exceeded, relay OFF!')

if get_gpio(CONFIG['RELAY_BOARD']['gpio_set']):
    time.sleep(on_time)
    gpio_relay.set_relay_off()

