import argparse
import csv
import sys
import exitstatus

from ssh_and_run_database_script import ssh_and_run_database_script

def get_args():
    """Get command-line arguments"""

    parser = argparse.ArgumentParser(
        description='Sample DevOps Tool',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('-f',
                        '--file',
                        help='CSV file with rows for sql_runner_host, sql_runner_userid, sql_runner_password, database_host, database_userid, database_password, port, database, sql_script_to_run',
                        metavar='FILE',
                        type=argparse.FileType('rt'),
                        default='localhost.csv')

    args = parser.parse_args()

    return args

def main():
    args = get_args()
    success = True

    with args.file as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            sql_runner_host=row['sql_runner_host']
            sql_runner_userid=row['sql_runner_userid']
            sql_runner_password=row['sql_runner_password']
            database_host=row['database_host']
            database_userid=row['database_userid']
            database_password=row['database_password']
            port=row['port']
            database=row['database']
            sql_script_to_run=row['sql_script_to_run']
            success = success and (ssh_and_run_database_script(sql_runner_host, sql_runner_userid, sql_runner_password, database_host, database_userid, database_password, port, database, sql_script_to_run) == exitstatus.ExitStatus.success)
            print()

    if success:
        sys.exit(exitstatus.ExitStatus.success)
    else:
        sys.exit(exitstatus.ExitStatus.failure)

if __name__ == '__main__':
    main()

