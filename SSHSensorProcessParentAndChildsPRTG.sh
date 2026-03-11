#!/bin/bash
## Script for PRTG to monitor CPU and Memory used by a Parent and Childs process
# Parent process could be changed for example use master for nginx
parentProcessName="rr"

# xml templates
declare -g xml="<?xml version="1.0" encoding='UTF-8'?> <prtg>"
xmlPid="<result>
<channel>#ProcessIDName</channel>
<value>#pid</value>
<ShowChart>0</ShowChart>
</result>"
xmlResult="<result>
<channel>#Channel</channel>
<value>#value</value>
<unit>Percent</unit>
<float>1</float>
</result>"
nodeEmpty="<result>
<channel>No Data</channel>
<value>0</value>
<unit>Count</unit>
<limitmode>0</limitmode>
<warning>0</warning>
<error>0</error>
</result>
<text>No data available</text>"

declare -g CPUTotal=0
declare -g MemTotal=0

# Function getinfo
# Return CPU and Memory percentage usage of processId using pidstat in a shot (one second usage)
# Inputs:
#   $1 -> process ID
# Outputs
# %CPU %Memory
getinfo(){
    cmdInfo=$(pidstat -p $1 -u -r -I 1 1 2>/dev/null)
    averageInfo=$(echo "$cmdInfo" | grep Average | grep -v UID)
    mapfile -t info <<< "$averageInfo"
    CPU=$(echo ${info[0]} | awk '{print $8'})
    MEM=$(echo ${info[1]} | awk '{print $8'})
    CPU=${CPU:-0}
    MEM=${MEM:-0}
    echo "$CPU $MEM" #2>/dev/null
}

# Function addNodeXML
# Return nodes XML for a processid with channels: pid, cpu, memory in PRTG format
# Also sum CPU and Memory in global variables
# Inputs:
#   $1 -> Name of Channel
#   $2 -> [optional] pid Process Id for getinfo and set in XML
# Outputs
#   Globals -> xml, CPUTotal, MemTotal
addNodeXML(){
    # If is a pid get CPU and Mem else is Total Node
    if [ -n "$2" ]; then  
	    read -ra cpuAndMem <<< "$(getinfo $2)"
	    nodePid=$(echo $xmlPid | sed -e "s/#ProcessIDName/PID-${1}/" -e "s/#pid/${2}/")
    else
	    cpuAndMem=($CPUTotal $MemTotal)
    fi
    nodeCPU=$(echo $xmlResult | sed -e "s/#Channel/CPU-${1}/" -e "s/#value/${cpuAndMem[0]}/")
    nodeMem=$(echo $xmlResult | sed -e "s/#Channel/Mem-${1}/" -e "s/#value/${cpuAndMem[1]}/")
    CPUTotal=$(echo "$CPUTotal + ${cpuAndMem[0]}" | bc)
    MemTotal=$(echo "$MemTotal + ${cpuAndMem[1]}" | bc)
    xml="$xml$nodePid$nodeCPU$nodeMem"
}

# Get pid for Parent process
pidParent=$(pidof $parentProcessName)
if [ -n "$pidParent" ]; then
    # addNode CPU and Memory for parent
    addNodeXML "parent" $pidParent
    # Get pids from Workers and add Nodes
    pidwks=$(pgrep -P ${pidParent} | sort -u)
    i=0
    for pid in $pidwks; do
	addNodeXML "child0$i" $pid
        i=$((i+1))
    done
else
   # Add node to avoid alert if main process is not running
   xml="$xml$nodeEmpty"
fi
# Add node Total
addNodeXML "Total"

xml="$xml</prtg>"
echo $xml