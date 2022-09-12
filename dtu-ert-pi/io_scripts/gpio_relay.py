#!/usr/bin/python3

import sys
from pathlib import Path
import datetime as dt
import logging
import pdb

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
from io_scripts import log_voltage

if CONFIG['general']['gpio_access_mode'].lower() == 'raspberrypi':
    import RPi.GPIO as GPIO
    GPIO.setmode(GPIO.BCM)
else:
    gpio_path = Path('/sys/class/gpio/')

# logging settings
logfile = Path(CONFIG['logging']['logfile'])

logger = logging.getLogger('iot_logger')    # create logger
if not logger.hasHandlers():
    logger.setLevel(logging.DEBUG)
    ch = logging.FileHandler(str(logfile), mode='a', encoding='utf-8')
    ch.setLevel(logging.DEBUG)
    formatter = logging.Formatter('%(asctime)s: %(message)s', datefmt=CONFIG['logging']['datefmt'])
    ch.setFormatter(formatter)   
    logger.addHandler(ch)

echo = True


def log_to_file(message, echo=True):
    logger.info(message)
    if echo:
        outstr = '{0:s}: {1:s}\n'.format(dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S(UTC)'), message)
        print(outstr, end='')

def open_gpio(gpio_num, direction='out'):
    if CONFIG['general']['gpio_access_mode'].lower() == 'raspberrypi':
        pass
    else:
        this_gpio = gpio_path / 'gpio{0:d}'.format(gpio_num)
        if not this_gpio.exists():
            with (gpio_path/'export').open(mode='w') as f: 
                f.write('{0:d}'.format(gpio_num))
        with (this_gpio/'direction').open(mode='w') as f: 
            f.write(direction)
    
def reset_gpio(gpio_num):
    if CONFIG['general']['gpio_access_mode'].lower() == 'raspberrypi':
        GPIO.setup(gpio_num, GPIO.IN)
    else:
        this_gpio = gpio_path / 'gpio{0:d}'.format(gpio_num)
        if this_gpio.exists():
            with (gpio_path/'unexport').open(mode='w') as f: 
                f.write('{0:d}'.format(gpio_num))

def set_gpio(gpio_num, value):
    if CONFIG['general']['gpio_access_mode'].lower() == 'raspberrypi':
        GPIO.setup(gpio_num, GPIO.OUT, initial=value)
    else:
        open_gpio(gpio_num)
        this_gpio = gpio_path / 'gpio{0:d}'.format(gpio_num)
        with (this_gpio/'value').open(mode='w') as f: 
            f.write('{0:d}'.format(value))

def gpio_on(gpio_num):
    set_gpio(gpio_num, 1)

def gpio_off(gpio_num):
    set_gpio(gpio_num, 0)

def get_gpio(gpio_num):
    if CONFIG['general']['gpio_access_mode'].lower() == 'raspberrypi':
        try:
            if GPIO.gpio_function(gpio_num) == GPIO.UNKNOWN:
                GPIO.setup(gpio_num, GPIO.IN)
        except:
            GPIO.setup(gpio_num, GPIO.IN)
        return GPIO.input(gpio_num)
    else:
        open_gpio(gpio_num)
        this_gpio = gpio_path / 'gpio{0:d}'.format(gpio_num)
        with (this_gpio/'value').open(mode='r') as f: 
            value = int(f.read(1))
        return value

def toggle_gpios(gpio_a, gpio_b):
    val = get_gpio(gpio_a)
    if val:
        gpio_off(gpio_a)
        gpio_on(gpio_b)
    else:
        gpio_on(gpio_a)
        gpio_off(gpio_b)
    return int(not val)

def set_relay_on():
    gpio_on(CONFIG['RELAY_BOARD']['gpio_set'])    # previously pin 81
    gpio_off(CONFIG['RELAY_BOARD']['gpio_reset'])    # previously pin 82
    log_voltage.log_voltage('set_relay_on')
    log_to_file('GPIO Relay switched ON')
    
def set_relay_off():
    gpio_off(CONFIG['RELAY_BOARD']['gpio_set'])    # previously pin 81
    gpio_on(CONFIG['RELAY_BOARD']['gpio_reset'])    # previously pin 82
    log_voltage.log_voltage('set_relay_off')
    log_to_file('GPIO Relay switched OFF')

def toggle_relay():
    if CONFIG['general']['gpio_access_mode'].lower() == 'raspberrypi':
        raise ValueError('Toggle functionality does not work in Raspberry Pi mode')
    val = get_gpio(CONFIG['RELAY_BOARD']['gpio_set'])
    if val:
        set_relay_off()
    else:
        set_relay_on()
    return int(not val)


if __name__ == '__main__':
    if len(sys.argv) > 1:
        if sys.argv[1].lower() == 'on':
            set_relay_on()
        elif sys.argv[1].lower() == 'off':
            set_relay_off()
        elif sys.argv[1].lower() == 'toggle':
            toggle_relay()
        else:
            print('Use arguments ON, OFF or TOGGLE, to change relay state.')
    else:
        print('Use arguments ON, OFF or TOGGLE, to change relay state.')
