##################################################################################################

# Deploys four SQL Server performance condition alerts to groups of SQL Server machines:

# (1) SQL Server On-premise machines 
#           OR
# (2) SQL Server Virtual Machines

# Do not deploy to:
# (1) Azure SQL Database (Azure cloud instances)
# (1) Azure Managed Instances (Azure cloud instances)

##################################################################################################

# Create list of SQL Server machines:
$SQLServerMachines = @(
    [PSCustomObject]@{SQLServerIP = '20.246.47.35'}
)

foreach ($SQLServerMachine in $SQLServerMachines) {

    Write-Output $SQLServerMachine.SQLServerIP

    # Create alert for database % log used:
    $SQLCode_DB_PercentLogUsed = "EXEC msdb.dbo.sp_add_alert @name=N'Databases_PercentLogUsed', 
		    @message_id=0, 
		    @severity=0, 
		    @enabled=1, 
		    @delay_between_responses=0, 
		    @include_event_description_in=0, 
		    @category_name=N'[Uncategorized]', 
		    @performance_condition=N'Databases|Percent Log Used|_Total|>|80', 
		    @job_id=N'00000000-0000-0000-0000-000000000000'"

    try {
    Invoke-Sqlcmd -ServerInstance "20.246.47.35" -Username "ljokhan" -Password "NissanAltima2013#" -Query $SQLCode_DB_PercentLogUsed
    }
    catch {
    Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Create alert for % databases log used:
    $SQLCode_Locks_DeadlocksPerSec = "EXEC msdb.dbo.sp_add_alert @name=N'Locks-NumberOfDeadlocks/sec', 
		    @message_id=0, 
		    @severity=0, 
		    @enabled=1, 
		    @delay_between_responses=0, 
		    @include_event_description_in=0, 
		    @category_name=N'[Uncategorized]', 
		    @performance_condition=N'Locks|Number of Deadlocks/sec|_Total|>|0', 
		    @job_id=N'00000000-0000-0000-0000-000000000000'"

    try {
    Invoke-Sqlcmd -ServerInstance "20.246.47.35" -Username "ljokhan" -Password "NissanAltima2013#" -Query $SQLCode_Locks_DeadlocksPerSec
    }
    catch {
    Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Create alert for free memory:
    $SQLCode_MemoryManager_FreeMemory = "EXEC msdb.dbo.sp_add_alert @name=N'MemoryManager-FreeMemory', 
		    @message_id=0, 
		    @severity=0, 
		    @enabled=1, 
		    @delay_between_responses=0, 
		    @include_event_description_in=0, 
		    @category_name=N'[Uncategorized]', 
		    @performance_condition=N'Memory Manager|Free Memory (KB)||<|500000000', 
		    @job_id=N'00000000-0000-0000-0000-000000000000'"

    try {
    Invoke-Sqlcmd -ServerInstance "20.246.47.35" -Username "ljokhan" -Password "NissanAltima2013#" -Query $SQLCode_MemoryManager_FreeMemory
    }
    catch {
    Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Create alert for database % log used:
    $SQLCode_Locks_AvgWaitTime = "EXEC msdb.dbo.sp_add_alert @name=N'Locks-AvgWaitTime', 
		    @message_id=0, 
		    @severity=0, 
		    @enabled=1, 
		    @delay_between_responses=0, 
		    @include_event_description_in=0, 
		    @category_name=N'[Uncategorized]', 
		    @performance_condition=N'Locks|Average Wait Time (ms)|_Total|>|1000', 
		    @job_id=N'00000000-0000-0000-0000-000000000000'"

    try {
    Invoke-Sqlcmd -ServerInstance "20.246.47.35" -Username "ljokhan" -Password "NissanAltima2013#" -Query $SQLCode_Locks_AvgWaitTime
    }
    catch {
    Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
    }
}