


function build-lab {

    [CmdletBinding()]
    
    param(
        [Parameter(Mandatory=$true)]
        [string] $NewName)

$currentIP = Get-NetIPAddress | Where-Object {$_.InterfaceAlias -like "Ethernet0"} | Where-Object {$_.AddressFamily -like "IPv4"}

Set-NetIPAddress -IPAddress $currentIP.IPAddress -PrefixLength $currentIP.PrefixLength

Get-DnsClientServerAddress | Where-Object {$_.AddressFamily -like "IPv4"} #| Where-Object{$_.InterfaceAlias -like "Ethernet0"}
Rename-Computer -NewName $NewName
Restart-Computer


# Install Domain

Install-WindowsFeature -Name Install-WindowsFeature -Name AD-Domain-Services
install-addsforest -Domainname 

Add-Computer -DomainName jeademo.local

# Create OU structure
# DemoLab
    # Users
    # Groups
        # jea_contractors
        # jea_developers
    # Computers

#create users

$DomainUsers = "Jea Admin", "Jea User", "Jea Dev", "Jea Contractor"

foreach ($user in $DomainUsers) {
    New-ADUser -SamAccountName ($user).SamAccountName -Name ($user) -AccountPassword (ConvertTo-SecureString -AsPlainText "Password12#$" -Force) -Enabled $true -path "OU=Users,OU=DemoLAB,DC=JEADemo,DC=local"


# add logon with period beween fname and last name
    }# Close foreach loop


# Create Computers
    # ou=Computers,OU=DemoLab,DC=JEADemo,DC=local
    # Jea-DC
    # Jea-DemoSvr
    # JeaClient - add: C:\JEA-DemoFiles\RoleCapabilities\Developer.psrc; C:\JEAConfigs\JEA-DemoFiles\RoleCapabilities\Developer.psrc;  





}# Close function