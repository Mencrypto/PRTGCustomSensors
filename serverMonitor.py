import paramiko
from flask import Flask, Response, request
import subprocess

app = Flask(__name__)
"""
Function to connect to remote server and execute a command
"""
def run_remote_ssh_command(ip, command):
    # Set user that connect to remote host and have RSA Key change to access without password
    username="user"
    try:

        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())  # Auto add host
        ssh.connect(ip, username=username)
        stdin, stdout, stderr = ssh.exec_command(command)
        result = stdout.read().decode()
        ssh.close()

        return result

    except Exception as e:
        return f"Error connecting or executing command: {str(e)}"

@app.route('/monitorCPUAndRAM', methods=['GET'])
def get_xml():
    ip = request.args.get('ip')  # Get IP from parameters in URL

    if not ip:
        return Response("IP not found in parameters", status=400)

    # Command to execute in this case a script in the remote host
    # Make sure you place the script in this path
    command = 'bash /home/user/scripts/SSHSensorProcessParentAndChildsPRTG.sh.sh'  

    result = run_remote_ssh_command(ip, command)

    if "Error" in result:
        return Response(result, status=500)

    # Respond with XML result from remote host
    xml_response = f'''{result}'''

    return Response(xml_response, mimetype='application/xml')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)

# Start with Gunicorn:
# gunicorn -w 1 -b 0.0.0.0:5000 serverMonitor:app
# Example of URL to Test
# http://${IPServer}:5000/monitorCPUAndRAM?ip=${IPRemote}
# IPServer: This is IP where python script is running
# IPRemote: This is IP when process parent and childs are running and you place script sh