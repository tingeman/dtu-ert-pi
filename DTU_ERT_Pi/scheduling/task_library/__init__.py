from pathlib import Path
import pkgutil
import importlib
import sys

from . import base_task
REGISTERED_TASKS = base_task.REGISTERED_TASKS

# find and specify all modules in the package
__all__ = [name for _, name, _ in pkgutil.iter_modules([Path(__file__).parent])]

def load_tasks():
    task_path = Path(__file__).parent
    available_task_modules = task_path.glob('TASK_*.py')
    for mod in sorted(available_task_modules):      # iterate over available tasks
        #print(mod.stem)
        if mod.stem not in REGISTERED_TASKS.keys():
            if mod.stem not in sys.modules:
                # Import module, any functions decorated with @add_task will register in REGISTERED_TASKS
                try:
                    importlib.import_module('.'+mod.stem, package='task_library')  
                except ModuleNotFoundError:
                    importlib.import_module('.'+mod.stem, package='scheduling.task_library')  
                #print('Imported task: {0}'.format(mod.name))
            else:
                importlib.reload(mod.stem)


def reload_tasks():
    task_path = Path(__file__).parent
    available_task_modules = task_path.glob('TASK_*.py')
    for mod in sorted(available_task_modules):      # iterate over available tasks
        try:
            # Reload module if possible
            importlib.reload(mod.stem)
        except:
            # Import module if not already imported
            importlib.import_module('.'+mod.stem, package='task_library')  


print('Loading tasks...')
load_tasks()
print('Finished loading tasks!')

