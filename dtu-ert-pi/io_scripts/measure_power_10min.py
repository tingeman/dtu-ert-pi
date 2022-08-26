#!/usr/bin/python3

import time
import numpy as np
import sys

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


initial_delay_sec = 15
average_minutes = 10
interval_sec = 2

if __name__ == '__main__':
    device = None
    if len(sys.argv) > 1:
        if sys.argv[1].lower() == 'wpi':
            if get_UI.wpi_available:
                device = 'wpi'
            else:
                print('Witty Pi 4 board is not available.')
        elif sys.argv[1].lower() == 'ina': 
            if get_UI.ina_available:
                device = 'ina'
            else:
                print('INA219 board is not available.')
        elif sys.argv[1].lower() in ['help', '-h', '--help', '?']: 
            print('Usage: measure_power_1min.py [device]')
            print('')
            print("Device is one of 'WPI' or 'INA'")
            print('If device is not specified, it will default to INA and fall back to WPI if INA is not available.')
        else:
            print('Unknown device specified, aborting...')
    else:
        device = None

    print('Averaging over {0} min ({1}s measure interval)'.format(average_minutes, interval_sec))
    predicted_measures = int(np.ceil(average_minutes*60/interval_sec))
    I = np.zeros(predicted_measures+100)
    U = np.zeros(predicted_measures+100)
    P = np.zeros(predicted_measures+100)

    print('Initial idling delay of {0} sec ...          '.format(initial_delay_sec), end="")    
    
    sec_list = list(reversed(range(initial_delay_sec)))
    time.sleep(1)

    for s in sec_list:
        print('\r',end="")
        print('Initial idling delay of {0} sec ...          '.format(s), end="")    
        time.sleep(1)

    print('\r',end="")
    print('Initial idling delay of 0 sec ...          '.format(s))    
    print('')

    t_end = time.time() + average_minutes*60
    count = 0
    while time.time() < t_end:
        devU,devI = get_UI.get_UI(device)
        I[count] = devI
        U[count] = devU
        P[count] = I[count]*U[count]
        print('\r', end="")
        print('{0:>4.0f}/{1:<4.0f}: I={2:>5.1f} mA; U={3:>4.1f} V; P={4:>6.3f} W; Pavg={5:>6.3f} W     '.format(count+1, predicted_measures, I[count]*1000, U[count], P[count], P.sum()/(count+1)), end="")
        count += 1
        time.sleep(interval_sec)

    print('')
    print('')
    print('Average over {0:.0f} min (N={1:.0f}):'.format(average_minutes, count))
    print('Current draw: {0:.3f} mA'.format(I.sum()/count*1000))
    print('Input voltage: {0:.3f} V'.format(U.sum()/count))
    print('Power draw: {0:.3f} W'.format(P.sum()/count))
    if get_UI.last_device_used is not None:
        print('Measured using device {0}'.format(get_UI.last_device_used))
