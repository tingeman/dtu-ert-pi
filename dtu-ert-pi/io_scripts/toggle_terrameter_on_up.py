#!/usr/bin/python3

import time
import datetime as dt
import subprocess
import logging
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
from io_scripts import log_voltage
from io_scripts.ping_alive_loop import alive_loop


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


# relay configuration parameters
i2c_bus = CONFIG['INA219']['i2c_bus']
shunt_resistance = CONFIG['INA219']['shunt_resistance']
gpio_ina_vcc = CONFIG['INA219']['gpio_vcc']

# TERRAMETER settings
turn_on_threshold = turn_on_threshold = CONFIG['TERRAMETER']['turn_on_threshold']
ping_timeout = CONFIG['TERRAMETER']['alive_ping_timeout']
BOOT_DELAY = CONFIG['TERRAMETER']['BOOT_DELAY']

# SSH settings
terrameter_ip = CONFIG['TERRAMETER']['ip']
port = CONFIG['TERRAMETER']['port']
username = CONFIG['TERRAMETER']['username']
password = CONFIG['TERRAMETER']['password']


# relay configuration parameters
off_duration = 30         # sec
timeout = 300             # sec



# instantiate voltage sensor
ina_available = CONFIG['INA219']['installed']

if CONFIG['INA219']['installed']:
    try:
        gpio_relay.gpio_on(gpio_ina_vcc)
        time.sleep(0.2)
        ina = INA219(i2c_bus, shunt_resistance)
        ina.configure(ina.RANGE_32V, ina.GAIN_AUTO)
    except Exception as e:
        print('Problem configuring INA219 device. Exception caught: {0}'.format(repr(e)))
        ina_available = False


def log_to_file(message, echo=True):
    logger.info(message)
    if echo:
        outstr = '{0:s}: {1:s}\n'.format(dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S(UTC)'), message)
        print(outstr, end='')


def wait_host_up(hostname, timeout=300, interval=5):
    tic = time.perf_counter()
    while True:
        result = subprocess.run(["ping", "-c", "1", hostname], capture_output=True)
        try:
            print(result.stdout.decode().split('\n')[1])
        except:
            pass
            
        if result.returncode == 0:
            return True

        toc = time.perf_counter()
        if toc-tic >= timeout:
            return False

        time.sleep(interval)
        
        
log_to_file('====== Terrameter power on sequence ======')
if ina_available:
    log_to_file('Supply voltage: {0:.2f}V'.format(ina.voltage()))
else:
    log_to_file('Supply voltage: Not available')
    
log_to_file('Power on Terrameter (relay set to on)')
gpio_relay.set_relay_on()

log_to_file('Waiting for Terrameter ping response (max {0:.0f} sec)'.format(timeout))
result = wait_host_up(terrameter_ip, timeout=timeout)

if result:
    log_to_file('Ping reply received, Terrameter is running')
else:
    log_to_file('Terrameter was not reachable within {0:.0f} sec of reboot!'.format(timeout))






