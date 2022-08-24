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

try:
    REGISTERED_TASKS
except NameError:
    #print('Defining REGISTERED_TASKS={}')
    REGISTERED_TASKS = {}

def add_task(func):
    global REGISTERED_TASKS
    REGISTERED_TASKS[func.__name__] = func
    print('Registered task: {0}'.format(func.__name__))
    return func
