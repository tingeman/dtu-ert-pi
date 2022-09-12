#!/usr/bin/python3

import sys
import subprocess
import logging
import time
import datetime as dt
from pathlib import Path
import traceback
import paramiko

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

if CONFIG['INA219']['installed']:
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

# TERRAMETER settings
turn_on_threshold = turn_on_threshold = CONFIG['TERRAMETER']['turn_on_threshold']
ping_timeout = CONFIG['TERRAMETER']['alive_ping_timeout']
BOOT_DELAY = CONFIG['TERRAMETER']['BOOT_DELAY']
terrameter_ip = CONFIG['TERRAMETER']['ip']
port = CONFIG['TERRAMETER']['port']
username = CONFIG['TERRAMETER']['username']
password = CONFIG['TERRAMETER']['password']


# flag files
alive_stop_file = Path(CONFIG['TERRAMETER']['alive_stop_file'])
MEASURECOMPLETE_file = Path(CONFIG['TERRAMETER']['MEASURECOMPLETE_file'])
stop_measure_wait_file = Path(CONFIG['TERRAMETER']['stop_measure_wait_file'])
measure_wait_interval = CONFIG['TERRAMETER']['measure_wait_interval'] # 1 minut interval to check if measurements completed.


def log_to_file(message, echo=True):
    logger.info(message)
    if echo:
        outstr = '{0:s}: {1:s}\n'.format(dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S(UTC)'), message)
        print(outstr, end='')

    
def check_measure_complete_loop(hostname, max_miss=6, interval=300, timeout=None):
       
    log_to_file('To break measure wait loop (checked every {0:.0f} s): touch {1}'.format(interval, stop_measure_wait_file), echo=echo)
    
    tic = time.perf_counter()
    miss_count = 0

    while not MEASURECOMPLETE_file.exists():
        
        result = subprocess.run(["ping", "-c", "1", hostname], capture_output=True)
        try:
            print(result.stdout.decode().split('\n')[1])
        except:
            pass
        
        if result.returncode == 1:
            # Failure, no ping reply received
            log_to_file('Ups, no reply on ping!', echo=echo)
            miss_count += 1
        else:
            # success, a ping reply was received
            miss_count = 0

        if miss_count >= max_miss:
            log_to_file('Reached max_miss count ({0:.0f} x {1:.0f} s)'.format(max_miss, interval), echo=echo)
            return 'MAXMISS'

        toc = time.perf_counter()
        if (timeout is not None) and (toc-tic >= timeout):
            # We reached timeout...
            if miss_count == 0:
                # We are still recieving pings, success!
                log_to_file('Reached timeout of {0:.0f} sec, host is still replying!'.format(timeout), echo=echo)
            else:
                # We just lost connection, failure!
                log_to_file('Reached timeout of {0:.0f} sec, no reply on the last {1:.0f} pings!'.format(timeout, miss_coung), echo=echo)
            return 'TIMEOUT'
        
        if stop_measure_wait_file.exists():
            log_to_file('Stop file exists, breaking measure wait loop', echo=echo)
            log_to_file('Removing stop file. To recreate: touch {0}'.format(stop_measure_wait_file), echo=echo)
            stop_measure_wait_file.unlink()
            return 'STOPFILE'
        
        time.sleep(interval)

    log_to_file('MEASURECOMPLETE file exists, breaking measure wait loop', echo=echo)
    return 'MEASURECOMPLETE'
    


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


def wake_and_run(cmd_file, boot_delay=None, dryrun=False, power_off=True):
    if (cmd_file is None):
        cmd_file = 'NO_COMMAND'

    if boot_delay is None:
        boot_delay = BOOT_DELAY

    log_to_file('====== Terrameter wake and run: {0} ======'.format(cmd_file), echo=echo)

    gpio_relay.open_gpio(81)
    gpio_relay.open_gpio(82)

    ina_available = CONFIG['INA219']['installed']
    if ina_available:
        try:
            ina = INA219(i2c_bus, shunt_resistance)
            ina.configure(ina.RANGE_32V, ina.GAIN_AUTO) 
        except Exception as e:
            log_to_file('Problem configuring INA219 device. Exception caught: {0}'.format(repr(e)))
            ina_available = False
    else:
        log_to_file('INA219 device not installed')

    if ina_available:
        supply_voltage = ina.voltage()
        log_to_file('Supply voltage: {0:.2f} V'.format(supply_voltage), echo=echo)

        if  supply_voltage < turn_on_threshold:
            log_to_file("Threshold {0:.1f}V NOT exceeded, No change to relay state... aborting.".format(turn_on_threshold), echo=echo)
            sys.exit()

        log_to_file('Threshold {0:.1f}V exceeded, set relay state to ON!'.format(turn_on_threshold))
        gpio_relay.set_relay_on()
    else:
        log_to_file('Supply voltage: Not available', echo=echo)
        log_to_file('Attempting terrameter boot anyway!', echo=echo)
        gpio_relay.set_relay_on()

    log_to_file('Waiting for Terrameter ping response (max {0:.0f} sec)'.format(ping_timeout), echo=echo)
    if not wait_host_up(terrameter_ip, timeout=ping_timeout):
        log_to_file('Terrameter was not reachable within {0:.0f} sec of reboot! Aborting.'.format(ping_timeout))
        log_to_file('Turning off power to Terrameter', echo=echo)
        log_voltage.log_voltage('no_ping_response')
        gpio_relay.set_relay_off()
        sys.exit()

    log_to_file('Ping reply received, Terrameter is running', echo=echo)
    log_to_file('Waiting {0:.0f} sec for boot sequence to complete'.format(boot_delay), echo=echo)
    time.sleep(boot_delay)

    if MEASURECOMPLETE_file.exists():
        # remove the MEASURECOMPLETE file if it exists
        MEASURECOMPLETE_file.unlink()

    if stop_measure_wait_file.exists():
        # remove the stop_measure_wait_file if it exists
        stop_measure_wait_file.unlink()

    if (cmd_file != 'NO_COMMAND'):
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(terrameter_ip, port, username, password)

        command = "nohup /home/root/GO {0:s} >> /home/root/logfile &".format(cmd_file)

        log_voltage.log_voltage('start_ls_measure')
        log_to_file('SSH command to Terrameter: {0}'.format(command), echo=echo)
        
        if dryrun:
            log_to_file('DRYRUN no command sent to Terrameter!'.format(command), echo=echo)
            MEASURECOMPLETE_file.touch()   # Added 2022-08-03 to make the dry run stop automatically
        else:
            stdin, stdout, stderr = ssh.exec_command(command)
            lines = stdout.readlines()
            print(lines)
        
        ssh.close()
    else:
        log_to_file('No command sent to Terrameter', echo=echo)
            
    try:
        result = check_measure_complete_loop(terrameter_ip, max_miss=30, interval=measure_wait_interval, timeout=4*3600)
    except Exception as err:
        log_to_file('Unexpected error: {0}'.format(err), echo=echo)
        exc_info = sys.exc_info()
        traceback.print_exception(*exc_info)
        result = 'EXCEPTION'
        
    if result == 'MEASURECOMPLETE':
        MEASURECOMPLETE_file.unlink()
        log_to_file('Measurements complete.')
        log_voltage.log_voltage('measure_complete')
        
        if power_off:
            if stop_measure_wait_file.exists():
                log_to_file('Stop file exists, aborting Terrameter power off', echo=echo)
                stop_measure_wait_file.unlink()
            else:
                log_to_file('Turning off Terrameter in 5 minutes', echo=echo)
                time.sleep(5*60)
                if stop_measure_wait_file.exists():
                    log_to_file('Stop file exists, aborting Terrameter power off', echo=echo)
                    stop_measure_wait_file.unlink()
                else:
                    log_to_file('Turning off Terrameter', echo=echo)
                    gpio_relay.set_relay_off()
        else:
            #log_to_file('Power off prohibited. Leaving Terrameter on.', echo=echo)
            pass
            
    elif result == 'MAXMISS':
        log_to_file('We lost connection to the Terrameter for {0:.0f} min.'.format(max_miss*measure_wait_interval), echo=echo)
        if power_off:
            log_to_file('Turning off Terrameter', echo=echo)
            log_voltage.log_voltage('max_miss')
            gpio_relay.set_relay_off()
        else:
            # log_to_file('Power off prohibited.. Leaving Terrameter on.', echo=echo)
            pass
            
    elif result == 'TIMEOUT':
        log_to_file('We reached timeout, abort measurements.', echo=echo)
        if power_off:
            log_to_file('Turning off Terrameter', echo=echo)
            log_voltage.log_voltage('timeout')
            gpio_relay.set_relay_off()
        else:
            # log_to_file('Power off prohibited.. Leaving Terrameter on.', echo=echo)
            pass
    elif result == 'STOPFILE':
        log_to_file('STOPFILE encountered, exiting but leaving Terrameter power on!', echo=echo)
        log_voltage.log_voltage('stopfile')
    elif result == 'EXCEPTION':
        log_to_file('EXCEPTION encountered, exiting but leaving Terrameter power on!', echo=echo)
    else:
        log_to_file('Cause for loop-exit: {0}   (No change to relay state)'.format(result), echo=echo)
    
    return result
        
if __name__ == '__main__':
        
    if len(sys.argv) > 1:
        if len(sys.argv) > 2:
            wake_and_run(int(sys.argv[1]), boot_delay=int(sys.argv[2]))
        else:
            wake_and_run(int(sys.argv[1]))
    else:
        raise ValueError('User must provide at least a commandfile name! (and optionally a boot delay)')

        

    
    



