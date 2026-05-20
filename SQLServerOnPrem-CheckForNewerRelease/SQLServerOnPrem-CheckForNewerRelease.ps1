############################################################################################################################################
#
# Table-driven PowerShell script which checks your SQL Server machines and determines if the build is the latest one.  This is usually a
# manual process and therefore not done often. This script can be automated to run weekly, so new builds can be identified quickly.
#
#   (1) Table containing all SQL Server instances to check:
#       Server: sql-db-01-ljokhan-server.database.windows.net
#       Database: sql-db-01-ljokhan
#       Table: [maintenance].[SQLServerInstances]
#
#   (2) Table which logs all the results for review:
#       Server: sql-db-01-ljokhan-server.database.windows.net
#       Database: sql-db-01-ljokhan
#       Table: [maintenance].[Log-SQLServerInstanceUpgrade]
#
# This script can run on these types of SQL Servers:
#
#   (1) SQL Server on-premise machines
#   (2) SQL Server on Azure Virtual Machines
#   (3) SQL Server on AWS Virtual Machines
#   (4) SQL Server on VMWare Virtual Machines
#
# This script is not recommended for these (because upgrades are managed by Microsoft):
#
#   (1) Azure SQL Database
#   (2) Azure Managed Instance
#
############################################################################################################################################

# Import modules:
Import-Module dbatools

# Variables:
$UserName = '********'
$Pass = '*********!'

# This is a table-driven script. Get list of SQL Server instances from an Azure SQL Database:
$SQLServerMachines = Invoke-Sqlcmd -Query "SELECT [SQLServerInstance] FROM [maintenance].[SQLServerInstances]" `
        -ServerInstance "sql-db-01-ljokhan-server.database.windows.net" -Database "sql-db-01-ljokhan" -Username $UserName -Password $Pass

# For each SQL Server machine in the table, compare the build to the latest Microsoft build:
foreach ($OneSQLServerMachine in $SQLServerMachines) {

    # Log the SQL Server instance:
    $SQL = "INSERT INTO [maintenance].[Log-SQLServerInstanceUpgrade] (LogEntry) VALUES ('SQL Server instance: " + $OneSQLServerMachine.SQLServerInstance + "') "
    Invoke-Sqlcmd -Query $SQL -ServerInstance "sql-db-01-ljokhan-server.database.windows.net" -Database "sql-db-01-ljokhan" -Username $UserName -Password $Pass  

    # Connect to the SQL Server instance:
    $SQLServerMachine = Connect-DbaInstance -SqlInstance $OneSQLServerMachine.SQLServerInstance -TrustServerCertificate

    # Test the instance against the latest Microsoft release:
    $buildStatus = Test-DbaBuild -SqlInstance $SQLServerMachine -Latest

    if ($buildStatus.Compliant -eq $false) {

        # The instance is not the latest, so update the log to state that an upgrade is available:
        $SQL = "INSERT INTO [maintenance].[Log-SQLServerInstanceUpgrade] (LogEntry) VALUES ('SQL Server instance: " `
            + $OneSQLServerMachine.SQLServerInstance + " - Upgrade is available"  +"') " 
        Invoke-Sqlcmd -Query $SQL -ServerInstance "sql-db-01-ljokhan-server.database.windows.net" -Database "sql-db-01-ljokhan" -Username $UserName -Password $Pass  

        # Update the log with the current build:
        $SQL = "INSERT INTO [maintenance].[Log-SQLServerInstanceUpgrade] (LogEntry) VALUES ('SQL Server instance: " `
            + $OneSQLServerMachine.SQLServerInstance + " - Current build is " + $buildStatus.Build +"') " 
        Invoke-Sqlcmd -Query $SQL -ServerInstance "sql-db-01-ljokhan-server.database.windows.net" -Database "sql-db-01-ljokhan" -Username $UserName -Password $Pass  

        # Update the log with the latest build:
        $SQL = "INSERT INTO [maintenance].[Log-SQLServerInstanceUpgrade] (LogEntry) VALUES ('SQL Server instance: " `
            + $OneSQLServerMachine.SQLServerInstance + " - Latest build from Microsoft is " + $buildStatus.BuildTarget +"') " 
        Invoke-Sqlcmd -Query $SQL -ServerInstance "sql-db-01-ljokhan-server.database.windows.net" -Database "sql-db-01-ljokhan" -Username $UserName -Password $Pass 

    } else {
        # The instance the latest available, so log that information:
        $SQL = "INSERT INTO [maintenance].[Log-SQLServerInstanceUpgrade] (LogEntry) VALUES ('SQL Server instance: " `
            + $OneSQLServerMachine.SQLServerInstance + " - Build is the latest available from Microsoft') " 
        Invoke-Sqlcmd -Query $SQL -ServerInstance "sql-db-01-ljokhan-server.database.windows.net" -Database "sql-db-01-ljokhan" -Username $UserName -Password $Pass 
    }
}
