#Build Credentials

$admin = "jeademo\jea.admin"
$contractor = "jeademo\jea.contractor"
$developer = "jeademo\jea.dev"
$user = "jeademo\jea.user" 

$password = ConvertTo-SecureString -string "Password12#$" -AsPlainText -Force

$adminCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $admin, $password
$contractorCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $contractor, $password
$developerCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $developer, $password
$userCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $password


# Verify users and groups
Enter-PSSession -ComputerName JEA-DC -Credential $adminCreds

Get-ADUser -filter 'name -like "JEA*"' | Select-Object name
Get-ADGroupMember -Identity "Domain Admins" | Select-Object name
Get-ADGroupMember "Domain Users" | Select-Object name

Get-ADUser -Identity jea.contractor | Get-ADPrincipalGroupMembership
Get-ADUser -Identity jea.dev | Get-ADPrincipalGroupMembership
Get-ADUser -Identity jea.user | Get-ADPrincipalGroupMembership
Get-ADUser -Identity jea.admin | Get-ADPrincipalGroupMembership

#test remote sessions
Enter-PSSession -ComputerName JEA-DEMOSVR -Credential $userCreds
Enter-PSSession -ComputerName JEA-DEMOSVR -Credential $contractorCreds
Enter-PSSession -ComputerName JEA-DEMOSVR -Credential $developerCreds
Enter-PSSession -ComputerName JEA-DEMOSVR -Credential $adminCreds

get-command * | Group-Object CommandType

Exit-PSSession


#build the JEA Module Folder
New-Item -ItemType directory -Path 'C:\JEAConfigs\Modules\' -Name ISSA
New-Item -ItemType directory -Path 'C:\JEAConfigs\Modules\ISSA' -Name RoleCapabilities -force #Must Have

#create a role capability file
New-PSRoleCapabilityFile -Path 'C:\JEAConfigs\Modules\ISSA\RoleCapabilities\Developer.psrc'
ise 'C:\JEAConfigs\Modules\ISSA\RoleCapabilities\Developer.psrc'
ise 'C:\JEAConfigs\JEA-DemoFiles\RoleCapabilities\Developer.psrc'

New-PSRoleCapabilityFile -Path 'C:\JEAConfigs\Modules\ISSA\RoleCapabilities\Contractors.psrc'
ise 'C:\JEAConfigs\Modules\ISSA\RoleCapabilities\Contractors.psrc'
ise 'C:\JEAConfigs\JEA-DemoFiles\RoleCapabilities\Contractors.psrc'

#create a session config file
New-PSSessionConfigurationFile -Path 'C:\JEAConfigs\Modules\ISSA\RestrictedSession.pssc' `
                               -SessionType RestrictedRemoteServer `
                               -TranscriptDirectory "C:\Program Files\WindowsPowerShell\Modules\ISSA\" `
                               -RunAsVirtualAccount `
                               -RoleDefinitions @{ 'JeaDemo\JEA_Developers' = @{ RoleCapabilities = 'Developer' } ;
                                              'JeaDemo\JEA_Contractors' = @{ RoleCapabilities = 'Contractors'}} 
 
 ise 'C:\JEAConfigs\Modules\ISSA\RestrictedSession.pssc'                                          

# Copy pre-made files to server
Copy-Item -Path 'C:\JEAConfigs\JEA-DemoFiles\RoleCapabilities\Developer.psrc' -Destination 'C:\JEAConfigs\Modules\ISSA\RoleCapabilities\Developer.psrc' -Force
Copy-Item -Path 'C:\JEAConfigs\JEA-DemoFiles\RoleCapabilities\Contractors.psrc' -Destination 'C:\JEAConfigs\Modules\ISSA\RoleCapabilities\Contractors.psrc' -Force

<#
Enter-PSSession -ComputerName JEA-DemoSVR -Credential $adminCreds
#Set-Location 'C:\Program Files\WindowsPowerShell\Modules\'
Exit-PSSession
#>

invoke-command -ComputerName JEA-DemoSVR -Credential $adminCreds -ScriptBlock {Get-ChildItem 'C:\Program Files\WindowsPowerShell\Modules\'}

$DemoSVRSession = New-PSSession -ComputerName Jea-DemoSVR -Credential $adminCreds
Copy-Item -Path 'C:\JEAConfigs\Modules\ISSA' -Destination 'c:\Program Files\WindowsPowerShell\Modules\ISSA' -ToSession $DemoSVRSession -Recurse

<#
Enter-PSSession $DemoSVRSession
Set-Location 'C:\Program Files\WindowsPowerShell\Modules\'
Get-ChildItem .
Exit-PSSession
#>
invoke-command -ComputerName JEA-DemoSVR -Credential $adminCreds -ScriptBlock {Get-ChildItem 'C:\Program Files\WindowsPowerShell\Modules\'}

#Register the EndPoint - 
invoke-command -ComputerName JEA-DemoSVR -Credential $adminCreds -ScriptBlock {Get-PSSessionConfiguration | Select-Object name}
<#
Enter-PSSession -ComputerName JEA-DemoSVR -Credential $adminCreds
Set-Location 'C:\Program Files\WindowsPowerShell\Modules\'
Get-PSSessionConfiguration | Select-Object name
Exit-PSSession
#>


Invoke-Command -ComputerName JEA-DemoSVR -Credential $adminCreds -ScriptBlock { Unregister-PSSessionConfiguration -Name ISSA-Demo }
Invoke-Command -ComputerName JEA-DemoSVR -Credential $adminCreds -ScriptBlock { Register-PSSessionConfiguration -Name ISSA-Demo -Path 'C:\Program Files\WindowsPowerShell\Modules\ISSA\RestrictedSession.pssc' }


# Restart WinRM Service on remote computer
invoke-command -ComputerName JEA-DemoSVR -Credential $adminCreds -ScriptBlock {Get-PSSessionConfiguration | Select-Object name}
<#
Enter-PSSession -ComputerName JEA-DemoSVR -Credential jeademo\jea.Admin
Get-PSSessionConfiguration | Select-Object name
Exit-PSSession
#>


Invoke-Command -ComputerName JEA-DemoSVR -Credential $adminCreds -ScriptBlock { Restart-Service -Name WinRM }
Invoke-Command -ComputerName JEA-DemoSVR -Credential $adminCreds -ScriptBlock { Get-PSSessionConfiguration | Select-Object name,permission }

Enter-PSSession -ComputerName JEA-DEMOSVR -Credential $userCreds -ConfigurationName ISSA-Demo

# Enter Remote Sessions with unprivledge users

Enter-PSSession -ComputerName JEA-DEMOSVR -Credential $developerCreds
Enter-PSSession -ComputerName JEA-DEMOSVR -Credential $developerCreds -ConfigurationName ISSA-Demo

get-command * | Group-Object CommandType
Restart-Service -Name BITS
Restart-Service -Name WinRM
whoami
Exit-PSSession 

# Make sure I am loged into the Jea-DEMOSVR
Enter-PSSession -ComputerName JEA-DEMOSVR -Credential $contractorCreds -ConfigurationName ISSA-Demo 
invoke-command -ComputerName JEA-DEMOSVR -Credential $contractorCreds -ConfigurationName ISSA-Demo -ScriptBlock {Restart-Service -Name BITS}
invoke-command -ComputerName JEA-DEMOSVR -Credential $contractorCreds -ConfigurationName ISSA-Demo -ScriptBlock {Get-Command}
invoke-command -ComputerName JEA-DEMOSVR -Credential $contractorCreds -ConfigurationName ISSA-Demo -ScriptBlock {whoami}
invoke-command -ComputerName JEA-DEMOSVR -Credential $contractorCreds -ConfigurationName ISSA-Demo -ScriptBlock {restart-computer}

<#
restart-computer
Restart-Computer -force
#>


##################################################################################################
# Reset WinRM Walk Through

Invoke-Command -ComputerName JEA-DemoSVR -Credential $adminCreds -ScriptBlock { 
    Unregister-PSSessionConfiguration -Name ISSA-Demo  
    Remove-Item -path 'c:\Program Files\WindowsPowerShell\Modules\ISSA' -Recurse -Force
    Restart-Service -Name WinRM -Force 
} 
Invoke-Command -ComputerName JEA-DemoSVR -Credential $adminCreds -ScriptBlock {
    Get-PSSessionConfiguration | Select-Object name,permission | Format-Table
    Get-ChildItem -path 'c:\Program Files\WindowsPowerShell\Modules\' | Format-Table
}


