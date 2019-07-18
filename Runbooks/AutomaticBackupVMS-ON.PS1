
# Parse Virtual machines for Backup Policy tag and register / unregister virtual machines to Azur Site recovery
#
# TODO : Filtrer si VM de type DevEnv car on ne propose pas la sauvegarde
# Raise Alert if backup registration fail
#
[Int]$CountAddedVms = 0
[Bool]$Automation_Flag = $True
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
[String]$ExpectedTagValue = "Yes"
#
# Process Virtual machiness with BackupPolicy Tags with Yes
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
        Set-AzRecoveryServicesVaultContext -Vault $SubscriptionVault -WarningAction SilentlyContinue | Out-Null
        $CheckregistredVM = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM -Status Registered -FriendlyName $($VMSForbackupTag.name)
        If ([string]::IsNullOrEmpty($CheckregistredVM))
        {
            #
            # Virtual machines not yet registered with ASR
            # OK
            Write-Output "Virtual machine $($VMSForbackupTag.name) is not yet registered for backup in Azure Site Recovery."
            $BackupPolicy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $backupPolicyname -ErrorAction SilentlyContinue
            If ([string]::IsNullOrEmpty($BackupPolicy) -eq $false)
            {
                #
                # Backup Plan found
                # OK
                Write-output "Virtual machine $($VMSForbackupTag.name) will be linked to the $backupPolicyname backup plan."
                try {
                    $job = Enable-AzRecoveryServicesBackupProtection -ResourceGroupName  $($VMSForbackupTag.ResourceGroupName) `
                        -Name $($VMSForbackupTag.name) `
                        -Policy $BackupPolicy
                    If($job.status -eq "completed")
                    {
                        $CountAddedVms = $CountAddedVms + 1
                        Write-Output "Virtual machine $($VMSForbackupTag.name) successfully registred for backup to the  $backupPolicyname backup plan."
                    }
                    else {
                        Write-Output "Unable to register Virtual machine $($VMSForbackupTag.name) to the $backupPolicyname backup plan."
                        # Déclencher une alarme                    
                    }                
                }
                catch {
                    Write-Output "Unable to register Virtual machine $($VMSForbackupTag.name) to the $backupPolicyname backup plan : $($_.exception.message)."
                    # Déclencher une alarme
                }
            }
            else {
                #
                # Backup plan not found
                # OK
                Write-Warning "Backup Plan $backupPolicyname does not exists in $($SubscriptionVault.name)"
                  # Déclencher une alarme
            }
        }
        else {
            #
            # Virtual machine is already registered for backup
            # OK
            Write-Output "Virtual machine $($VMSForbackupTag.name) is already resgistered for backup in Azure Site Recovery."
        }
    }
    else {
        Write-Warning "No Azure Site Recovery instance located in Azure region $($VMSForbackupTag.location). Unable to deliver backup service."
        Exit
    }
 
}
Write-host "Added virtual machines : $CountAddedVms"