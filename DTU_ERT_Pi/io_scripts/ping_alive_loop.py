#!/usr/bin/python3

import sys
import subprocess
import logging
import time
import datetime as dt
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

# ping settings
terrameter_ip = CONFIG['TERRAMETER']['ip']
ping_timeout = CONFIG['TERRAMETER']['alive_ping_timeout']
alive_stop_file = Path(CONFIG['TERRAMETER']['alive_stop_file'])


def log_to_file(message, echo=True):
    logger.info(message)
    if echo:
        outstr = '{0:s}: {1:s}\n'.format(dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S(UTC)'), message)
        print(outstr, end='')
       

def alive_loop(hostname, max_miss=5, interval=60, timeout=None):
    if timeout is not None:
        log_to_file('Pinging {0:s} every {1:.0f} sec... (next log message when connection is lost, or timeout in {2:.0f} sec)'.format(hostname, interval, timeout), echo=echo)
    else:
        log_to_file('Pinging {0:s} every {1:.0f} sec... (next log message when connection is lost, no timeout set)'.format(hostname, interval, timeout), echo=echo)

    log_to_file('To stop alive loop: touch {0}'.format(alive_stop_file), echo=echo)

    tic = time.perf_counter()
    miss_count = 0
    while miss_count<=max_miss:
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

        toc = time.perf_counter()
        if (timeout is not None) and (toc-tic >= timeout):
            # We reached timeout...
            if miss_count == 0:
                # We are still recieving pings, success!
                log_to_file('Reached timeout of {0:.0f} sec, host is still replying!'.format(timeout), echo=echo)
                return False
            else:
                # We just lost connection, failure!
                log_to_file('Reached timeout of {0:.0f} sec, no reply on the last {1:.0f} pings!'.format(timeout, miss_coung), echo=echo)
                return True

        time.sleep(interval)
        
        if alive_stop_file.exists():
            log_to_file('Stop file exists, breaking alive loop'.format(miss_count), echo=echo)
            log_to_file('Removing stop file. To recreate: touch {0}'.format(alive_stop_file), echo=echo)
            alive_stop_file.unlink()
            return
    
    log_to_file('No reply on the last {0:.0f} pings! Stop trying.'.format(miss_count), echo=echo)

        
if __name__ == '__main__':
    try:
        alive_loop(terrameter_ip, timeout=5*3600)     # keep checking for 5 hours, unless loss of connection.
    except:
        log_to_file('Unexpected exit of ping alive loop', echo=echo)