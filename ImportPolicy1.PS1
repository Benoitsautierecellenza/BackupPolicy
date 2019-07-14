#
# Import 1 OK
#
[String]$ManagementGroupName = "MGMT01"
[String]$PolicyDefinitionFileURI = "https://raw.githubusercontent.com/Benoitsautierecellenza/BackupPolicy/master/AZ-ALLOWEDTAGVALUES/AZ-ALLOWEDTAGVALUES-02-RULE.json"
[String]$PolicyParameterFileURI = "https://raw.githubusercontent.com/Benoitsautierecellenza/BackupPolicy/master/AZ-ALLOWEDTAGVALUES/AZ-ALLOWEDTAGVALUES-02-PARAMETERS.json"
[String]$PolicyName = "AllowedValues4BackupPolicy"
New-AzPolicyDefinition -Name $PolicyName `
-DisplayName $PolicyName `
-Policy $PolicyDefinitionFileURI `
-Parameter $PolicyParameterFileURI `
-ManagementGroupName $ManagementGroupName `
-Mode All
#
# Assign 1 OK
#
[String]$ManagementGroupName = "MGMT01"
[String]$SubscriptionID = (Get-Azcontext).Subscription.id
[String]$BackupPolicyTagName = "BackupPolicy"
[String]$DefaultTagValue = "No"
[String]$PolicyName = "AllowedValues4BackupPolicy"
[String]$PolicyAssignName = "MGMT01-VM-P1"
[array]$AllowedValues = @("Yes", "No")
[String]$Scope = "/providers/Microsoft.Management/managementGroups/$ManagementGroupName"
$PolicyDefinition = Get-AzPolicyDefinition  -ManagementGroupName $ManagementGroupName -Name $PolicyName
$AssignParameters = @{
    'BackupPolicyTagName' = $BackupPolicyTagName;
    'BackupPolicyTagAllowedValues'= ($AllowedValues)
}
New-AzPolicyAssignment -Name $PolicyAssignname `
    -PolicyDefinition $PolicyDefinition `
    -Scope $Scope `
    -PolicyParameterObject $AssignParameters  
#
# Import 2 OK
#
[String]$ManagementGroupName = "MGMT01"
[String]$PolicyDefinitionFileURI = "https://raw.githubusercontent.com/Benoitsautierecellenza/BackupPolicy/master/AZ-DEFAULTTAG/AZ-DEFAULTTAG-01-RULE.json"
[String]$PolicyParameterFileURI = "https://raw.githubusercontent.com/Benoitsautierecellenza/BackupPolicy/master/AZ-DEFAULTTAG/AZ-DEFAULTTAG-01-PARAMETERS.json"
[String]$PolicyName = "DefaultValue4BackupPolicy"
New-AzPolicyDefinition -Name $PolicyName `
-DisplayName $PolicyName `
-Policy $PolicyDefinitionFileURI `
-Parameter $PolicyParameterFileURI `
-ManagementGroupName $ManagementGroupName `
-Mode All
#
# Assign 2 OK (ManagementGroup)
#
[String]$ManagementGroupName = "MGMT01"
[String]$BackupPolicyTagName = "BackupPolicy"
[String]$DefaultTagValue = "No"
[String]$PolicyName = "DefaultValue4BackupPolicy"
[String]$PolicyAssignName = "MGMT01-VM-P2"
[String]$AllowedValues = "Yes"
[String]$Scope = "/providers/Microsoft.Management/managementGroups/$ManagementGroupName"
$PolicyDefinition = Get-AzPolicyDefinition  -ManagementGroupName $ManagementGroupName -Name $PolicyName
$AssignParameters = @{
    'BackupPolicyTagName' = $BackupPolicyTagName;
    'DefaultTagValue'=($AllowedValues)
}
New-AzPolicyAssignment -Name $PolicyAssignname `
-PolicyDefinition $PolicyDefinition `
-Scope $Scope `
-PolicyParameterObject $AssignParameters



#
# Assign 2 OK (Souscription)
#
$SubscriptionID = (Get-AzContext).Subscription.id 
[String]$BackupPolicyTagName = "BackupPolicy"
[String]$DefaultTagValue = "No"
[String]$PolicyName = "DefaultValue4BackupPolicy"
[String]$PolicyAssignName = "MGMT01-VM-P2"
[String]$AllowedValues = "Yes"
[String]$Scope = "/subscriptions/$SubscriptionID"
$PolicyDefinition = Get-AzPolicyDefinition  -ManagementGroupName $ManagementGroupName -Name $PolicyName
$AssignParameters = @{
    'BackupPolicyTagName' = $BackupPolicyTagName;
    'DefaultTagValue'=($AllowedValues)
}
New-AzPolicyAssignment -Name $PolicyAssignname `
-PolicyDefinition $PolicyDefinition `
-Scope $Scope `
-PolicyParameterObject $AssignParameters
