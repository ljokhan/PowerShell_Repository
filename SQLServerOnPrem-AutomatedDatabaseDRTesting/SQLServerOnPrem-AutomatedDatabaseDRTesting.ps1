###########################################################################################################################
#
# Automated Disaster Recovery Testing
#
# Many organizations conduct Disaster Recovery testing quarterly, semi-annually or annually. This schedule won't catch
# database corruption in backups which could lead to potential data loss if backups are needed. This script helps mitigate 
# this by automating the restore and database checks on a weekly basis within the Disaster Recovery environment...and 
# automatically notifies I.T. of the result. This ensures the backups are free from corruption.
#
###########################################################################################################################

Clear-Host

# Define variables.  Use SQL Authentication for demonstration only. For Production, use Entra  or Windows Authentication.
$SQLServerBackupFolder = "C:\Microsoft SQL Server Backups"
$DRSQLServerMachine = 'LJACER'
$DRSQLServerUsername = "DisasterRecoveryUser"
$DRSQLServerPwd = "ILoveDisasterRecovery#"
$DRLog = "C:\Users\Public\DRTest.log"
$ErrorOccured = 0 # Intialize error flag to "0"

# If previous DR Log exists, delete it:
Remove-Item -Path $DRLog -Force

# Add timestamp to DR Log:
Get-Date >> $DRLog
"Automated SQL Server Disaster Recovery testing...`r`n" >> $DRLog

# Get the last full backup:
$MostRecentFullBackup = Get-ChildItem -Path $SQLServerBackupFolder -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1

# Create SQL for the RESTORE command:
$SQL = "    RESTORE DATABASE [DisasterRecoveryAdventureWorks2022] " `
        + " FROM DISK = N'" + $MostRecentFullBackup + "' " `
        + " WITH  FILE = 1, " `
        + " MOVE N'AdventureWorks2022' TO N'C:\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DisasterRecoveryAdventureWorks2022.mdf', " `
        + " MOVE N'AdventureWorks2022_log' TO N'C:\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DisasterRecoveryAdventureWorks2022_log.ldf', " `
        + " NOUNLOAD,  REPLACE,  STATS = 5"

# Restore the database. Use 15 minute timeout for smaller databases and increase for larger databases:
try {
    # Update log:
    "Starting database restore in disaster recovery site...`r`n" >> $DRLog

    # Perform restore of latest full backup:
    Invoke-Sqlcmd -ServerInstance $DRSQLServerMachine -Username $DRSQLServerUsername -Password $DRSQLServerPwd `
    -TrustServerCertificate  -QueryTimeout 900 -Query $SQL -Verbose *>> $DRLog  
}
catch {
    # Log error:
    $ErrorOccured = 1
    "** Error *** $($_.Exception.Message)`r`n" >> $DRLog
    Write-Host "** Error *** $($_.Exception.Message)" -ForegroundColor Red 
}

# If no errors, then continue with DBCC check:
if ($ErrorOccured -eq 0) {

    $SQL = "DBCC CHECKDB ('DisasterRecoveryAdventureWorks2022') WITH DATA_PURITY"

    # Run DBCC to check for any corruption:
    try {
        # Update log:
        "Restore successful. Performing DBCC check in disaster recovery site...`r`n" >> $DRLog

        Invoke-Sqlcmd -ServerInstance $DRSQLServerMachine -Username $DRSQLServerUsername -Password $DRSQLServerPwd `
        -TrustServerCertificate -QueryTimeout 900 -Query $SQL -Verbose *>> $DRLog  
    }
    catch {   
        # Add error to log:
        "** Error *** $($_.Exception.Message)`r`n" >> $DRLog
        Write-Host "** Error *** $($_.Exception.Message)" -ForegroundColor Red 
    }  
}

# Email results to I.T. department. Would need to be configured with company's SMPT machine:
#if (ErrorOccured -eq 0) {
    #Send-MailMessage -SmtpServer "<SMTP_SERVER>" -Port 25 -From "SQLServer@company.com" -To "ITSupport.company.com" `
    #                 -Subject "** FAILED ** SQL Server Continuous DR Test" -Body $DRLog 
#}
#else {
    #Send-MailMessage -SmtpServer "<SMTP_SERVER>" -Port 25 -From "SQLServer@company.com" -To "ITSupport.company.com" `
    #                 -Subject "** SUCCESSFUL ** SQL Server Disaster DR Test" -Body "Automated disaster recovery test was successful"
#}

