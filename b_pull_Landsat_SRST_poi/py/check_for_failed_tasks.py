import ee
from pandas import read_csv
import time
import os

# get configs from yml file
yml = read_csv("b_pull_Landsat_SRST_poi/mid/yml.csv")
# assign proj
eeproj = yml["ee_proj"][0]
# initialize GEE with proj
ee.Initialize(project = eeproj)
# grab run date
run_date = yml["run_date"][0]
# make task error file name
fn = "GEE_task_errors_v" + run_date + ".csv"

# get a list of all the submitted tasks (this times out at 10d, FYI)
ts = list(ee.batch.Task.list())

# for each of the tasks, see if any failed, if so, add a line to a csv file with the task id
for task in ts:
   if ("FAIL" in task.status()['state'] and run_date in task.status()['description']):
       # add the task description to a file called 'GEE_task_errors.csv'
       with open(os.path.join('b_pull_Landsat_SRST_poi/out/', fn), 'a') as f:
          f.write(task.status()['description'] + '\n')
