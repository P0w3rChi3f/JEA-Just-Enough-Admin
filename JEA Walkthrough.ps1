# Verify users and groups

Enter-PSSession -ComputerName JEA-DC -Credential jeademo\jea.admin

Get-ADUser -filter 'name -like "JEA*"' | Select-Object name
Get-ADGroupMember -Identity "Domain Admins" | Select-Object name
Get-ADGroupMember "Domain Users" | Select-Object name

#test remote sessions
Enter-PSSession -ComputerName JEA-DEMOSVR -Credential jeademo\jea.user
Enter-PSSession -ComputerName JEA-DEMOSVR -Credential jeademo\jea.contractor
Enter-PSSession -ComputerName JEA-DEMOSVR -Credential jeademo\jea.dev
Enter-PSSession -ComputerName JEA-DEMOSVR -Credential jeademo\jea.admin

get-command * | Group-Object CommandType

Exit-PSSession


#build the JEA Module Folder
New-Item -ItemType directory -Path 'C:\JEAConfigs\Modules\' -Name ISSA
New-Item -ItemType directory -Path 'C:\JEAConfigs\Modules\ISSA' -Name RoleCapabilities #Must Have

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

Enter-PSSession -ComputerName JEA-DemoSVR -Credential jeademo\jea.Admin
Set-Location 'C:\Program Files\WindowsPowerShell\Modules\'
Get-ChildItem .
Exit-PSSession

$DemoSVRSession = New-PSSession -ComputerName Jea-DemoSVR -Credential 'jeademo\jea.admin'
Copy-Item -Path 'C:\JEAConfigs\Modules\ISSA' -Destination 'c:\Program Files\WindowsPowerShell\Modules\ISSA' -ToSession $DemoSVRSession -Recurse
Enter-PSSession $DemoSVRSession
Set-Location 'C:\Program Files\WindowsPowerShell\Modules\'
Get-ChildItem .
##Exit-PSSession

#Register the EndPoint - 

Enter-PSSession -ComputerName JEA-DemoSVR -Credential jeademo\jea.Admin
Set-Location 'C:\Program Files\WindowsPowerShell\Modules\'
Get-PSSessionConfiguration | Select-Object name
Exit-PSSession

Invoke-Command -ComputerName JEA-DemoSVR -Credential jeademo\jea.admin -ScriptBlock { Unregister-PSSessionConfiguration -Name ISSA-Demo }
Invoke-Command -ComputerName JEA-DemoSVR -Credential jeademo\jea.admin -ScriptBlock { Register-PSSessionConfiguration -Name ISSA-Demo -Path 'C:\Program Files\WindowsPowerShell\Modules\ISSA\RestrictedSession.pssc' }

# Restart WinRM Service on remote computer
Enter-PSSession -ComputerName JEA-DemoSVR -Credential jeademo\jea.Admin
Get-PSSessionConfiguration | Select-Object name
Exit-PSSession

Invoke-Command -ComputerName JEA-DemoSVR -Credential jeademo\jea.Admin -ScriptBlock { Restart-Service -Name WinRM }
Invoke-Command -ComputerName JEA-DemoSVR -Credential jeademo\jea.Admin -ScriptBlock { Get-PSSessionConfiguration | Select-Object name,permission }

Enter-PSSession -ComputerName JEA-DEMOSVR -Credential 'jeademo\jea.user' -ConfigurationName ISSA-Demo

# Enter Remote Sessions with unprivledge users

Enter-PSSession -ComputerName JEA-DEMOSVR -Credential 'jeademo\jea.dev'
Enter-PSSession -ComputerName JEA-DEMOSVR -Credential 'jeademo\jea.dev' -ConfigurationName ISSA-Demo

get-command * | Group-Object CommandType
Restart-Service -Name BITS
Restart-Service -Name WinRM
whoami
Exit-PSSession 

# Make sure I am loged into the Jea-DEMOSVR
Enter-PSSession -ComputerName JEA-DEMOSVR -Credential 'jeademo\jea.contractor' -ConfigurationName ISSA-Demo 
Get-Command
Restart-Service -Name BITS
whoami
restart-computer
Restart-Computer -force

##################################################################################################
# Reset WinRM Walk Through

Invoke-Command -ComputerName JEA-DemoSVR -ScriptBlock { 
    Unregister-PSSessionConfiguration -Name ISSA-Demo  

    Remove-Item -path 'c:\Program Files\WindowsPowerShell\Modules\ISSA' -Recurse -Force

    Restart-Service -Name WinRM -Force

    Get-PSSessionConfiguration | Select-Object name,permission 
} -Credential jeademo\jea.admin



