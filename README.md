## About
Repository for utility scripts used as Custom Sensors for PRTG, extending its capability to monitor IT resources
## Files / Scripts
- [SSHSensorProcessParentAndChildsPRTG.sh](https://github.com/Mencrypto/PRTGCustomSensors/blob/main/SSHSensorProcessParentAndChildsPRTG.sh): [SSH Sensor] Monitor CPU and Memory of a parent process and childs using pidstat at a single point in time (no use average) return a XML in PRTG format
- [serverMonitor.py](https://github.com/Mencrypto/PRTGCustomSensors/blob/main/serverMonitor.py): [http sensor] Execute script SSHSensorProcessParentAndChildsPRTG.sh in remote server and returns the XML output for that script. Can be run with Gunicorn. See the last lines of the script for testing.
