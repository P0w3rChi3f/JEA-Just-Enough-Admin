Remove-Computer -ComputerName $env:COMPUTERNAME -UnjoinDomaincredential "JEADemo\jea.admin" -PassThru -Verbose -Restart

Add-Computer -ComputerName "$env:COMPUTERNAME" -LocalCredential "$env:COMPUTERNAME\Administrator" -DomainName "jeademo.local" -Credential "JEADemo\jea.admin" -Force -Verbose -Restart



Ethernet adapter Ethernet0:

   Connection-specific DNS Suffix  . : 
   Link-local IPv6 Address . . . . . : fe80::d902:767f:5e9f:1fc%4
   IPv4 Address. . . . . . . . . . . : 192.168.121.138
   Subnet Mask . . . . . . . . . . . : 255.255.255.0
   Default Gateway . . . . . . . . . : 192.168.121.2