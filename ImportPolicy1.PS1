$PolicyName = "AZ-DEFAULTTAG"
$PolicyFile = "C:\localgit\BackupPolicy\AZ-DEFAULTTAG\AZ-DEFAULTTAG-01-RULE.JSON"
$Metatada =  '{"category":"Virtual Machine"}' 
$Parameters = '{
    "BackupPolicyTagName":  { "type": "string" }
    "DefaultTagValue": { "type": "array" } 
}'
New-AzPolicyDefinition -Name $PolicyName -Policy $PolicyFile -Parameter $Parameters