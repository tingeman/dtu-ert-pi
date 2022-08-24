#!/usr/bin/python3

import time
import sys
import logging
import time
from pathlib import Path
import subprocess

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

from io_scripts import get_UI



if CONFIG['general']['hardware'].lower() == 'raspberrypi':
    try:
        from vcgencmd import Vcgencmd
        vcgm = Vcgencmd()
    except:
        pass
 
    
# logging settings
logfile = Path(CONFIG['logging']['voltage_logger'])

logger = logging.getLogger('voltage_logger')    # create logger
if not logger.hasHandlers():
    logger.setLevel(logging.DEBUG)
    ch = logging.FileHandler(str(logfile), mode='a', encoding='utf-8')
    ch.setLevel(logging.DEBUG)
    formatter = logging.Formatter('%(asctime)s; %(message)s', datefmt=CONFIG['logging']['datefmt'])
    ch.setFormatter(formatter)   
    logger.addHandler(ch)

# ping settings
terrameter_ip = CONFIG['TERRAMETER']['ip']


def ping_terrameter(hostname):
    return subprocess.run(["ping", "-c", "1", hostname], capture_output=True)


def get_cpu_temp():
    if CONFIG['general']['hardware'].lower() == 'raspberrypi':
        n_measures = 5
        total_cpu_temp = 0
        
        for n in range (n_measures):
            total_cpu_temp += vcgm.measure_temp()
            time.sleep(0.1)
        
        # calculate average of numbers
        return total_cpu_temp / n_measures
    elif CONFIG['general']['hardware'].lower() == 'iot-gate-imx7':
        cpu_temp_path = Path('/sys/class/thermal/thermal_zone0/temp')
        with cpu_temp_path.open(mode='r') as f: 
            cpu_temp_str = f.read()
        return float(cpu_temp_str.strip())/1000
    else:
        return -99.0

        
def log_voltage(message):
    bat_volt = get_UI.get_input_voltage()

    try:
        bat_volt = get_UI.get_input_voltage()
    except Exception as e:
        bat_volt = -99.
        print('Voltage measurement error: {0}'.format(repr(e)))

    try:
        cpu_temp = get_cpu_temp()
    except Exception as e:
        cpu_temp = -99.
        print('CPU temp error: {0}'.format(repr(e)))
    
    ping_result = ping_terrameter(terrameter_ip)

    # 'application' code
    outstr = '{0:.2f}; V; {1:.2f}; C; {2:.0f}; {3:s};'.format(bat_volt, cpu_temp, ping_result.returncode, message)
    logger.info(outstr)
    print(outstr)

if __name__ == '__main__':
    if len(sys.argv) > 1:
        message = sys.argv[1]
    else:
        message = ""

    log_voltage(message)
    
