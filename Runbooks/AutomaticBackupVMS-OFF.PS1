
# Parse Virtual machines for Backup Policy tag and register / unregister virtual machines to Azur Site recovery
#
# Raise Alert if backup registration fail
#
[Int]$CountAddedVms = 0
[Int]$CountRemovedVms = 0
[Bool]$Automation_Flag = $False
If($Automation_Flag -eq $True)
{
    $connectionName = "AzureRunAsConnection"
    try
    {
        # Get the connection "AzureRunAsConnection "
        $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         
    
        "Logging in to Azure..."
        Add-AzureRmAccount `
            -ServicePrincipal `
            -TenantId $servicePrincipalConnection.TenantId `
            -ApplicationId $servicePrincipalConnection.ApplicationId `
            -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
    }
    catch {
        if (!$servicePrincipalConnection)
        {
            $ErrorMessage = "Connection $connectionName not found."
            throw $ErrorMessage
        } else{
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }
}
[string]$BackupPolicyTagName = "BackupPolicy"
[String]$backupPolicyname = "DefaultPolicy"
[String]$ExpectedTagValue = "No"
#
# Process Virtual machiness with BackupPolicy Tags with No
#
$ListVMSForbackupTag = Get-AzResource -ResourceType "Microsoft.Compute/virtualMachines" -TagName $BackupPolicyTagName -TagValue $ExpectedTagValue
Write-Output "Process virtual machines from subscription with tag $BackupPolicyTagName configured to $ExpectedTagValue : $($ListVMSForbackupTag.count)"
ForEach ($VMSForbackupTag in $ListVMSForbackupTag)
{
    Write-Output "Processing Virtual machine $($VMSForbackupTag.name) located in $($VMSForbackupTag.ResourceGroupName)"
    #
    # Check if Virtual machine is already register for backup
    # OK
    $SubscriptionVault = Get-AzRecoveryServicesVault | where-object {$_.location -eq $VMSForbackupTag.location}
    If ([string]::IsNullOrEmpty($SubscriptionVault) -eq $False)
    {
        $CheckregistredVM = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM -Status Registered -FriendlyName $($VMSForbackupTag.name)
        If ([string]::IsNullOrEmpty($CheckregistredVM) -eq $false)
        {
            Write-Output "Virtual machine $($VMSForbackupTag.name) is already registered to Azure Site Recovery."
            $BackupPolicy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $backupPolicyname -ErrorAction SilentlyContinue
            If ([string]::IsNullOrEmpty($BackupPolicy) -eq $false)
            {
                Write-output "Virtual machine $($VMSForbackupTag.name) will be removed from the $backupPolicyname backup plan."
                try {
                    #
                    # Perform backup removal 
                    # OK
                    $Container = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM -Status Registered -FriendlyName $($VMSForbackupTag.name)
                    $ProtectedItem = Get-AzRecoveryServicesBackupItem -Container $Container[0] -WorkloadType AzureVM 
                    $job = Disable-AzRecoveryServicesBackupProtection -Item $ProtectedItem[0] -Force -RemoveRecoveryPoints
                    If($job.status -eq "completed")
                    {
                            $CountRemovedVms = $CountRemovedVms + 1
                            Write-output "Virtual machine $($VMSForbackupTag.name) successfully unregistered from backup to the $backupPolicyname backup plan."
                    }
                    else {
                        Write-output "Unable to unregister Virtual machine $($VMSForbackupTag.name) from the $backupPolicyname backup plan."
                        # Déclencher une alarme                    
                    }                
                }
                catch {
                        Write-output "Unable to unregister Virtual machine $($VMSForbackupTag.name) to the $backupPolicyname backup plan :$($_.exception.message)."
                        # Déclencher une alarme
                }
            }
            else {
                Write-Warning "Backup Plan $backupPolicyname does not exists in $($SubscriptionVault.name)."
                # Raise Alarm
            }
        }
        else {
            #
            # Virtual machine is not registered for Backup
            # OK
            Write-Output "Virtual machine $($VMSForbackupTag.name) not registered for backup in Azure Site Recovery."
        }
    }
    else {
        Write-Warning "No Azure Site Recovery instance located in Azure region $($VMSForbackupTag.location). Unable to deliver backup service."
        Exit
    }
}
Write-host "Added virtual machines : $CountAddedVms"
Write-host "Removed virtual machines : $CountRemovedVms"
