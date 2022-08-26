import time
from pathlib import Path
from croniter import croniter
import datetime as dt
import pandas as pd
import argparse
import importlib

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
from scheduling import task_library


def reload_tasks():
    try:
        importlib.reload(task_library)
    except NameError:
        from scheduling import task_library

#base_dir = Path(__file__).parent.parent.absolute()
#if str(base_dir) not in sys.path:
#    sys.path.insert(0, str(base_dir))
#
#io_scripts_dir = str(base_dir / 'io_scripts')
#if str(io_scripts_dir) not in sys.path:
#    sys.path.insert(0, str(io_scripts_dir))

#scheduling_dir = Path(__file__).parent.absolute()
#schedule_file = scheduling_dir / 'schedule.ert'
#last_run_file = scheduling_dir / 'last_run.ert'

schedule_file = Path(CONFIG['scheduling']['SCHEDULE_FILE'])
last_run_file = Path(CONFIG['scheduling']['LAST_RUN_FILE'])

schedule_file.touch()
last_run_file.touch()

def get_past_tasks():
    try:
        df_past_tasks = pd.read_csv(last_run_file, parse_dates=[1])
    except:
        df_past_tasks = pd.DataFrame(columns=['task', 'time', 'completed'])
    
    if len(df_past_tasks) == 0:
        df_past_tasks = pd.DataFrame(columns=['task', 'time', 'completed'])
    
    return df_past_tasks

def read_schedule(file):
    with open(schedule_file) as f:
        lines = f.readlines()

    scheduled_tasks = []

    for line in lines:
        tokens = line.split('#')
        line = tokens[0]
        if len(line.strip()) == 0:
            continue
        
        tokens = line.split()
        
        if len(tokens)<6:
            # silently skip lines that do not have enough entries
            continue
        
        task = {}
        task['schedule'] = '  '.join(tokens[0:5])
        task['task'] = tokens[5]
        
        if (len(tokens)>=8) and (tokens[6] == '=>'):
            task['when_complete'] = tokens[7]
        else:
            task['when_complete'] = 'SHUTDOWN'
            
        scheduled_tasks.append(task)
            
    return scheduled_tasks


def ammend_past_tasks(df_past_tasks, scheduled_tasks, timestamp=None):
    # check that all tasks are in df_past_tasks
    # or add them if they are not

    if timestamp is None:
        timestamp = dt.datetime.now()

    past_task_list = []

    for task in scheduled_tasks:
        if task['task'] not in df_past_tasks['task'].values:
            # this task was never run
            # assume the date of previous scheduled time
            #pdb.set_trace()
            cron = croniter(task['schedule'], timestamp)
            last_run = cron.get_prev(dt.datetime)
            past_task = {}
            past_task['task'] = task['task']
            past_task['time'] = last_run
            past_task['completed'] = -1
            past_task_list.append(past_task)
    
    if len(past_task_list) > 0:
        df_ammended_tasks = pd.DataFrame(past_task_list).sort_values(by='time')
        df_ammended_tasks = df_ammended_tasks.drop_duplicates(subset='task', keep='last', ignore_index=True)
    
        df_past_tasks = pd.concat([df_past_tasks, df_ammended_tasks], ignore_index=True)
        #pdb.set_trace()
        
    df_past_tasks = df_past_tasks.sort_values(by='time')
    
    return df_past_tasks

def get_due_tasks(scheduled_tasks, df_past_tasks, timestamp=None):
    # process scheduled tasks
    if timestamp is None:
        timestamp = dt.datetime.now()

    due_tasks = []

    for task in scheduled_tasks:
        completed_tasks = df_past_tasks[(df_past_tasks['task']==task['task']) & (df_past_tasks['completed'].isin([-1,1]))]
        last_run = completed_tasks.sort_values(by='time')['time'].iloc[-1]
            
        cron = croniter(task['schedule'], last_run)
        due_time = cron.get_next(dt.datetime)
        
        due_outstr = 'no'
        if  due_time <= timestamp:
            task['due_time'] = due_time
            due_tasks.append(task)
            due_outstr = 'YES'

        print('Task: {0};   last run: {1};   due time: {2};   timestamp: {3};   Is due?: {4}'.format(task['task'], last_run, due_time, timestamp, due_outstr))

    if len(due_tasks) > 0:
        df_due_tasks = pd.DataFrame(due_tasks).sort_values(by='due_time')
        df_due_tasks = df_due_tasks.drop_duplicates(subset='task', keep='last', ignore_index=True)
        return df_due_tasks.to_dict('records')
    else:
        return []
    
def execute_task(task, timestamp=None):
    
    if timestamp is None:
        timestamp = dt.datetime.now()

    # HOW DO WE EXECUTE A TASK AND WAIT FOR IT TO COMPLETE?
    time.sleep(1)
    
    this_completed_task = {}
    this_completed_task['task'] = task['task']
    this_completed_task['time'] = timestamp
    this_completed_task['completed'] = 1
   
    return this_completed_task

    
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-d', type=dt.datetime.fromisoformat, help='date/time used to resolve if a task is due ("YYYY-MM-DD hh:mm:ss")')

    args = parser.parse_args()
    evaluation_time = args.d
    
    scheduled_tasks = read_schedule(schedule_file)
    df_past_tasks = get_past_tasks()
    
    # set timezero to 5 days ago, so a task should definitely be due
    timestamp = dt.datetime.now()-dt.timedelta(days=5)
    df_past_tasks = ammend_past_tasks(df_past_tasks, scheduled_tasks, timestamp)
    
    due_tasks = get_due_tasks(scheduled_tasks, df_past_tasks, evaluation_time)
    
    when_complete = 'STAY_ON_UPLOAD'
    for task in due_tasks:
        print('Executing task: {0}'.format(task['task']))
        this_completed_task = execute_task(task, timestamp=evaluation_time)
        df_past_tasks = pd.concat([df_past_tasks, pd.DataFrame([this_completed_task])])
        df_past_tasks = df_past_tasks.reset_index(drop=True)
        df_past_tasks.to_csv(last_run_file, index=False)
        if task['when_complete'].lower() == 'shutdown':
            when_complete = 'SHUTDOWN'
            
    if 'upload' in  when_complete.lower():
        # Execute upload!
        print('Here we should execute upload to server!')
        pass
    if 'shutdown' in when_complete.lower():
        # Execute shutdown!
        print('Here we should execute shutdown!')
        pass
    