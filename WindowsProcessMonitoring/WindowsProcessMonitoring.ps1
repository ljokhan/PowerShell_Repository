#########################################################################################################################################################################################

# This script runs every 5 minutes, captures all processes with no CPU activity, stores that information.
# It also kills frozen Applications, defined as Applications with no CPU activity after 30 minutes.

#########################################################################################################################################################################

# Clear all variables in Powershell ISE session:
Remove-Variable * -Force -ErrorAction SilentlyContinue
Clear-Host

# Define variables:
$CSVPath = "C:\Users\Public\CurrentProcessesNoCPU.csv"
$ApplicationProcessesToKill = @{ApplicationName = "CMD"}
$ThresholdNbrTimesNoCPU = 5

# Get list of current processes which has no CPU activity:
$CurrentProcessesNoCPU = Get-Process | Select-Object Name, ID, CPU | Where-Object { ($_.Name -ne "svchost") -and (($_.CPU -eq 0) -or ($_.CPU -eq $null)) } | Sort-Object -Property Name

# Initialize an empty array to hold the current processes with no CPU activity:
$CurrentProcessesNoCPUTable = @()

# Loop through the current processes and add each to the array:
foreach ($Process in $CurrentProcessesNoCPU) {

    $MyRow = [PSCustomObject]@{
        ProcessName  = $Process.Name.ToUpper()
        ProcessID    = $Process.ID
        NoCPUCounter = 1
    }
    # Add the new row to the table array:
    $CurrentProcessesNoCPUTable += $MyRow
}

# Import previous file of processes with no CPU activity (if it exists):
if (Test-Path "$CSVPath") {
    $PreviousProcessesNoCPU = Import-CSV -Path $CSVPath

    # Loop through the current processes. Search for process in the previous file. If found, then the process had no CPU usage last time around:
    foreach ($Process in $CurrentProcessesNoCPUTable) {
    
        # Extract process name:
        $MyProcessName = $Process.ProcessName
        $MyProcessID   = $Process.ProcessID

        # Search for Process and Process ID in the previous file:
        $Found = $PreviousProcessesNoCPU | Where-Object { ($_.ProcessName -eq "$MyProcessName") -and ($_.ProcessID -eq "$MyProcessID") }
    
        # If found in previous file, increment counter (# times the process has had no CPU usage):
        if ($Found -ne $null) {            
            # Process and Process ID was found in the previous file. That means that process had no CPU last time, so let's increment the counter:
            $Process.NoCPUCounter =  [long]$Found.NoCPUCounter + 1
        }

        # If Process is in the Application list and over threshold for number of times with no CPU activity, kill the process:
        if ($MyProcessName -in $ApplicationProcessesToKill.ApplicationName -and ([int]$Process.NoCPUCounter -gt $ThresholdNbrTimesNoCPU) ) {
            Write-Output "Simulating killing the process...Stop-Process -Name $MyProcessName -Force>"
        }
    }
}

# Export processes to operating system, so we can keep a running total of the times a process had zero CPU usage:
$CurrentProcessesNoCPUTable | Export-CSV -Path $CSVPath -NoTypeInformation
