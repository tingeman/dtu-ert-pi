#!/usr/bin/python3

import time

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
from io_scripts import gpio_relay

last_device_used = None
wpi_available = False
ina_available = False

if ('WITTYPI4' in CONFIG) and (CONFIG['WITTYPI4']['installed']):
    import wittyPi as wpi
    wpi_available = True
    
if ('INA219' in CONFIG) and (CONFIG['INA219']['installed']):    
    from io_scripts.ina219 import INA219
    gpio_ina_vcc = CONFIG['INA219']['gpio_vcc']
    ina_i2c_bus = CONFIG['INA219']['i2c_bus']
    ina_shunt_resistance = CONFIG['INA219']['shunt_resistance']
    ina_available = True


def get_ina_UI():
    global last_device_used
    if not ina_available:
        raise IOError('INA219 is not installed.')
        
    gpio_relay.gpio_on(gpio_ina_vcc)
    time.sleep(0.1)
    ina = INA219(ina_i2c_bus, ina_shunt_resistance)
    ina.configure(ina.RANGE_32V, ina.GAIN_AUTO)
    
    I = ina.current()*1000
    U = ina.voltage()
    last_device_used = 'ina'    
    gpio_relay.gpio_off(gpio_ina_vcc)
    
    return U, I

def get_ina_input_voltage():
    global last_device_used
    if not ina_available:
        raise IOError('INA219 is not installed.')
        
    gpio_relay.gpio_on(gpio_ina_vcc)
    time.sleep(0.1)
    ina = INA219(ina_i2c_bus, ina_shunt_resistance)
    ina.configure(ina.RANGE_32V, ina.GAIN_AUTO)
    
    U = ina.voltage()
    last_device_used = 'ina'    
    gpio_relay.gpio_off(gpio_ina_vcc)
    
    return U
    
def get_wpi_UI():
    global last_device_used
    if not wpi_available:
        raise IOError('Witty Pi 4 is not installed.')
        
    I = wpi.get_output_current()
    U = wpi.get_output_voltage()
    last_device_used = 'wpi'
    return U, I

def get_wpi_input_voltage():
    global last_device_used
    if not wpi_available:
        raise IOError('Witty Pi 4 is not installed.')
        
    U = wpi.get_input_voltage()
    last_device_used = 'wpi'
    return U
    
def get_UI(device=None):
    global last_device_used
    if device is None:
        if  ina_available:
            device = 'ina'
        elif wpi_available:
            device = 'wpi'
        else:
            raise IOError('No relevant devices available')
    
    if device.lower() == 'wpi':
        if wpi_available:
            U,I = get_wpi_UI()
        else:
            raise IOError('Witty Pi 4 is not available')
    elif device.lower() == 'ina':
        if ina_available:
            U,I = get_ina_UI()
        else:
            raise IOError('Witty Pi 4 is not available')
    else:
        raise ValueError('Device not recognized')
    
    return U, I

def get_input_voltage(device=None):
    global last_device_used
    if device is None:
        if wpi_available:
            device = 'wpi'
        elif ina_available:
            device = 'ina'
        else:
            raise IOError('No relevant devices available')
    
    if device.lower() == 'wpi':
        if wpi_available:
            U = get_wpi_input_voltage()
        else:
            raise IOError('Witty Pi 4 is not available')
    elif device.lower() == 'ina':
        if ina_available:
            U = get_ina_input_voltage()
        else:
            raise IOError('Witty Pi 4 is not available')
    else:
        raise ValueError('Device not recognized')
    
    return U

  
    
if __name__ == '__main__':    
    if ina_available:
        Uina, Iina = get_ina_UI()
        print('--- INA219 -----------------------')
        print('Current draw: {0:.3f} mA'.format(Iina))
        print('Input voltage: {0:.3f} V'.format(Uina))
        print('Power draw: {0:.3f} W'.format(Iina*Uina))
        print('')
        
    if wpi_available:
        Uwpi, Iwpi = get_wpi_UI()
        print('--- Witty Pi 4 -------------------')
        print('Current draw: {0:.3f} mA'.format(Iwpi))
        print('Input voltage: {0:.3f} V'.format(Uwpi))
        print('Power draw: {0:.3f} W'.format(Iwpi*Uwpi))
        print('')

