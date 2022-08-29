import sys
from pathlib import Path

## NEW ROBUST APPROACH
## Will search upwards in folder structure for config_module.py
## until it finds it, then add that folder to sys.path, if it
## is not already included.

def find_upwards(cwd, filename, return_dir=True):
    """Recursively look upwards in folder-structure from current path (cwd) for file filename.
    When found, return the full path to the parent directory (or the file itself, depending on
    the value of return_dir) as a pathlib.Path object."""
    if cwd == Path(cwd.root):
        return None
    fullpath = cwd / filename
    if return_dir:
        # return the path to folder containing the file
        return fullpath.parent if fullpath.exists() else find_upwards(cwd.parent, filename, return_dir)
    else:
        # return the full path to the file (including filename)
        return fullpath if fullpath.exists() else find_upwards(cwd.parent, filename, return_dir)
    
base_dir = Path(__file__).parent.absolute()    

base_dir = find_upwards(Path.cwd(), "config_module.py")

if base_dir is None:
    raise FileNotFoundError('Could not identify location of config_module.py.')
else:
    print('Base directory identified: {0}'.format(base_dir))
    if str(base_dir) not in sys.path:
        sys.path.insert(0, str(base_dir))
        print('Inserted in sys.path...')
     

# Now import the CONFIG dictionary
from config_module import CONFIG
