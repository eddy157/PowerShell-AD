# 2017-03-23 Eddy & Matthew Fugel
# Script to Find LastLogonDate, Disable, Move Computers to Deleted OU and Delete dnsNode.

# Gets time stamps for all computers in the domain that have NOT logged in since after specified date 90 Days
Import-Module ActiveDirectory
$DaysInactive = 90  
$time = (Get-Date).Adddays(-($DaysInactive)) 
  
# Get all AD computers with lastLogonTimestamp less than our time 
Get-ADComputer -SearchBase "OU=KIDSII Computers,DC=KDNS001,DC=LOCAL" -Filter {LastLogonTimeStamp -lt $time} -Properties LastLogonTimeStamp |
  
# Output hostname and lastLogonTimestamp into CSV 
select-object Name,@{Name="Stamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}} | export-csv C:\OLD_Computer.csv -notypeinformation


Import-Csv "C:\OLD_Computer.csv" | ForEach-Object {
    $Name = $_."Name"
    # Move Computer to Deleted Computers OU
    Get-ADComputer $Name | Move-ADObject -TargetPath 'OU=Deleted Computers,DC=KDNS001,DC=LOCAL'
    # Disable Computer
    Get-ADComputer $Name | Disable-ADAccount
    # Delete Computer dnsNode
    $ComputerName=$Name
    $dnsnodepath="DC=" + $ComputerName + ",DC=kdns001.local,CN=MicrosoftDNS,CN=System,DC=KDNS001,DC=LOCAL"
    Remove-ADObject -Confirm:$false -Identity:$dnsnodepath -Server:"KPDC7.KDNS001.LOCAL"

}
       
# The End!