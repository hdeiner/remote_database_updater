import paramiko
import time
import exitstatus
import re

def ssh_and_run_database_script(sql_runner_host, sql_runner_userid, sql_runner_password, database_type, database_host, database_userid, database_password, port, database, sql_script_to_run):
    retryCount = 0
    finishedSession = False

    while ((not finishedSession) and (retryCount < 5)):
        try:
            #                key = paramiko.RSAKey.from_private_key_file(os.path.expanduser("~/.ssh/id_rsa"))
            client = paramiko.SSHClient()
            #               client.load_system_host_keys()
            #               client.load_host_keys(os.path.expanduser('~/.ssh/known_hosts'))
            client.set_missing_host_key_policy(paramiko.AutoAddPolicy)

            print("connecting to " + sql_runner_host+" with username="+sql_runner_userid+" and password="+sql_runner_password)
            #                client.connect(machine, username=username, pkey=key)
            client.connect(sql_runner_host, username=sql_runner_userid, password=sql_runner_password)

            print("transferring " + sql_script_to_run + " to /tmp/sql_sqript_to_run on " + sql_runner_host)
            ftp_client = client.open_sftp()
            ftp_client.put(sql_script_to_run,'/tmp/sql_script_to_run')
            ftp_client.close()

            if (database_type == 'MySQL'):
                command_to_run = "mysql -h " + database_host + " -P " + port + " -u " + database_userid + " --password=" + database_password + " " + database + " < /tmp/sql_script_to_run"
            else:
                raise Exception("Bad database_type of " + database_type)

            stdin, stdout, stderr = client.exec_command(command_to_run)
            print("executed " + command_to_run + " on " + sql_runner_host)

            errors = 0
            for line in stderr:
                if (errors == 0):
                    print("stderr")
                isError = True
                if (re.search(r'mysql\:\ \[Warning\]', line)):
                    isError = False
                if (isError):
                    errors = errors + 1
                print(line)

            stdin.close()
            stdout.close()
            stderr.close()
            client.close()
            del client
            finishedSession = True

            if (errors != 0):
                print("ERROR IN DATABASE UPDATE")
                return exitstatus.ExitStatus.failure

        except paramiko.AuthenticationException as authenticationFailure:
            print("Authentication failed: %s" % authenticationFailure)
            return exitstatus.ExitStatus.failure
        except paramiko.SSHException as sshException:
            print("Unable to establish SSH connection: %s" % sshException)
            return exitstatus.ExitStatus.failure
        except paramiko.BadHostKeyException as badHostKeyException:
            print("Unable to verify server's host key: %s" % badHostKeyException)
            return exitstatus.ExitStatus.failure
        except Exception as exception:
            print("Exception: %s" % exception)
            if (retryCount < 5):
                retryCount = retryCount + 1
                print("retry...")
                continue
            else:
                return exitstatus.ExitStatus.failure
        finally:
            time.sleep(1)

    return exitstatus.ExitStatus.success
