
[String]$PolicyAssignname = « Assign-$PolicyName »

$UpdatePolicyTagName = « UpdatePolicy »

$AllowedValues = @(« AlwaysReboot », »RebootIfRequired », »OnlyReboot », »NeverReboot »)

$PolicyDefinition = Get-AzPolicyDefinition -SubscriptionId $SubscriptionID | Where-Object {$_.Properties.displayname -eq $PolicyDisplayName}

$AssignParameters = @{

‘UpdatePolicyTagName’ = $UpdatePolicyTagName;

‘UpdatePolicyTagAllowedValues’=($AllowedValues)

}

New-AzPolicyAssignment -Name $PolicyAssignname `

-PolicyDefinition $PolicyDefinition `

-Scope $Scope `

-PolicyParameterObject $AssignParameters