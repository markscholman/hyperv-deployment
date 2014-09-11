function Set-HVHFirewallRules {
<#
.SYNOPSIS
Configures the Windows Firewall for Hyper-V Server
.DESCRIPTION
See the Synopsis. This isn't to complex. It doesnt requires any input parameters.
.EXAMPLE
Set-HVHFirewallRules
This Command sets the firewall for Hyper-V Server.
#>
	netsh advfirewall firewall set rule group = ”Remote Administration” new enable = yes
	netsh advfirewall firewall set rule group = ”File and Printer Sharing” new enable = yes
	netsh advfirewall firewall set rule group = ”Remote Service Management” new enable = yes
	netsh advfirewall firewall set rule group = ”Performance Logs and Alerts” new enable = yes
	netsh advfirewall firewall set rule group = ”Remote Event Log Management” new enable = yes
	netsh advfirewall firewall set rule group = ”Remote Scheduled Tasks Management” new enable = yes
	netsh advfirewall firewall set rule group = ”Remote Volume Management” new enable = yes
	netsh advfirewall firewall set rule group = ”Remote Desktop” new enable = yes
	netsh advfirewall firewall set rule group = ”Windows Firewall Remote Management” new enable = yes
	netsh advfirewall firewall set rule group = ”windows management instrumentation (wmi)” new enable = yes
	netsh advfirewall firewall add rule name = ”Https Replica in ” dir = in protocol = TCP localport = 443 action = allow
}
function Set-HVHRoles {
<#
.SYNOPSIS
Configures the roles forHyper-V Server
.DESCRIPTION
See the Synopsis. It doesnt requires any input parameters.
.EXAMPLE
Set-HVHRoles
This Command configures Remote Volume Management, Enables features MultiPath IO, Failover Cluster and Hyper-V Role.
#>
	#For remote volume management
	if ((Get-Service vds | Select-Object -ExpandProperty status) -eq "Stopped") {
		Start-Service vds
	}
	
	#Install MPIO
	if (!((Get-WindowsFeature MultiPath-IO | Select-Object -ExpandProperty Installstate) -eq "Installed")) {
		Install-WindowsFeature Multipath-IO -IncludeAllSubFeature -IncludeManagementTools
	}
	#Install Failover Cluster
	if (!((Get-WindowsFeature Failover-Clustering | Select-Object -ExpandProperty Installstate) -eq "Installed")) {
		Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
	}
	
	#Install Hyper-V
	if ((Get-WmiObject -Class win32_computersystem | Select-Object -Expandproperty Model) -eq "Virtual Machine") {
		Enable-WindowsOptionalFeature –Online -FeatureName Microsoft-Hyper-V –All -NoRestart
	}
	else {
		if (!((Get-WindowsFeature Hyper-V | Select-Object -ExpandProperty Installstate) -eq "Installed")) {
			Install-WindowsFeature -Name Hyper-V -IncludeManagementTools
		}
	}
}
function Set-HVHNetwork {
<#
.SYNOPSIS
Configures the networks for Hyper-V Server
.DESCRIPTION
See the Synopsis. It requires Administrative privileges.
.PARAMETER ManagementIP
Configures the Management IP for the Management adapter.
.PARAMETER ManagementVLANID
Configures the Management VLAN ID for the management adapter.
.PARAMETER ManagementIPDFGW
Configures the Default gateway for the management network.
.PARAMETER ClusterIP
Configures the CSV Network ip address.
.PARAMETER ClusterVLANID
Configures the CSV Network VLAN ID.
.PARAMETER LiveMigrationIP
Configures the Live Migration network IP Addres.
.PARAMETER LiveMigrationVLANID
Configures the Live Migration network VLAN ID.
.PARAMETER PrimaryDNS
Configures the Primary DNS Server to use.
.PARAMETER SecondaryDNS
Configures the Secondary DNS Server to use. This parameter is optional.
.PARAMETER Lan
Changes the NLB Settings for use in Lab environments. Dynamic is not supported in Virtual Machines.	
.EXAMPLE
Set-HVHNetwork -ManagementIP "10.10.0.25" -ManagementVLANID "1" -ManagementIPDFGW "10.10.0.1" -ClusterIP "10.11.0.25" -ClusterVLANID "2" -LiveMigrationIP "10.12.0.25" -LiveMigrationVLANID "3" -PrimaryDNS "10.10.0.46" -SecondaryDNS "10.10.0.47"
Configures the network with All the required network configuration with 2 DNS Servers.
.EXAMPLE
Set-HVHNetwork -ManagementIP "10.10.0.25" -ManagementVLANID "1" -ManagementIPDFGW "10.10.0.1" -ClusterIP "10.11.0.25" -ClusterVLANID "2" -LiveMigrationIP "10.12.0.25" -LiveMigrationVLANID "3" -PrimaryDNS "10.10.0.46"
Configures the network with All the required network configuration with 1 DNS Servers.
.EXAMPLE
Set-HVHNetwork -ManagementIP "10.10.0.25" -ManagementVLANID "1" -ManagementIPDFGW "10.10.0.1" -ClusterIP "10.11.0.25" -ClusterVLANID "2" -LiveMigrationIP "10.12.0.25" -LiveMigrationVLANID "3" -PrimaryDNS "10.10.0.46" -SecondaryDNS "10.10.0.47" -Lab
Configures the network with All the required network configuration with 2 DNS Servers and running it on a virtual machine.
#>
	[cmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
	param (
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Management IP Address',
				   Position = 0,
				   ValueFromPipeline = $true,
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('MGTIP')]
		[ipaddress]$ManagementIP,
		
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Management Gateway IP Address',
				   Position = 1,
				   ValueFromPipeline = $true,
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('MGTDFGWIP')]
		[ipaddress]$ManagementIPDFGW,
		
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Management Vlan ID',
				   Position = 2,
				   ValueFromPipeline = $true,
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('MGTVLANID')]
		[int]$ManagementVLANID,
		
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Live Migration IP Address',
				   Position = 3,
				   ValueFromPipeline = $true,
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('LMIP')]
		[ipaddress]$LiveMigrationIP,
		
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Live Migration VLAN ID',
				   Position = 4,
				   ValueFromPipeline = $true,
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('LMVLANID')]
		[int]$LiveMigrationVLANID,
		
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Cluster (CSV) IP Address',
				   Position = 5,
				   ValueFromPipeline = $true,
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('CSVIP')]
		[ipaddress]$ClusterIP,
		
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Cluster (CSV) VLAN ID',
				   Position = 6,
				   ValueFromPipeline = $true,
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('CSVVLANID')]
		[int]$ClusterVLANID,
		
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Specify DNS Server',
				   Position = 7,
				   ValueFromPipeline = $true,
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('PDNS')]
		[ipaddress]$PrimaryDNS,
		
		[Parameter(Mandatory = $false,
				   Helpmessage = 'Specify Secondary DNS Server',
				   Position = 8,
				   ValueFromPipeline = $true,
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('SDNS')]
		[ipaddress]$SecondaryDNS,
		
		[Parameter(Mandatory = $false,
				   Helpmessage = 'Deploy HVH on HVH',
				   Position = 9,
				   ValueFromPipeline = $true,
				   ValuefromPipelineByPropertyName = $true)]
		[switch]$Lab
		
	)
	#Create Team
	$mgtteamnics = Get-NetAdapter | Where-Object { $_.Name -like "MGT-LM-CSV*" } | select -ExpandProperty Name
	if ($PSCmdlet.ShouldProcess("Network Configuration")) {
		if (!(Get-NetLbfoTeam -Name "MGT-LM-CSV-TEAM" -ErrorAction 'SilentlyContinue')) {
			if (!($lab)) {
				New-NetLbfoTeam -Name MGT-LM-CSV-TEAM -TeamMembers $mgtteamnics -TeamingMode SwitchIndependent -LoadBalancingAlgorithm Dynamic -TeamNicName MGT -Confirm:$false
			}
			else {
				New-NetLbfoTeam -Name MGT-LM-CSV-TEAM -TeamMembers $mgtteamnics -TeamingMode SwitchIndependent -LoadBalancingAlgorithm IPAddresses -TeamNicName MGT -Confirm:$false
			}
			if (($ManagementVLANID -eq "0") -or ($ManagementVLANID -eq "1")) {
				Set-NetLbfoTeamNic -Name MGT -Default
			}
			else {
				Set-NetLbfoTeamNic -Name MGT -VlanID $ManagementVLANID -Confirm:$false
			}
			if (!(Get-NetLbfoTeamNic -Name "LM" -ErrorAction 'SilentlyContinue')) {
				Add-NetLbfoTeamNic -Team MGT-LM-CSV-TEAM -Name LM -VlanID $LiveMigrationVLANID -Confirm:$false
			}
			if (!(Get-NetLbfoTeamNic -Name "CSV" -ErrorAction 'SilentlyContinue')) {
				Add-NetLbfoTeamNic -Team MGT-LM-CSV-TEAM -Name CSV -VlanID $ClusterVLANID -Confirm:$false
			}
		}
		
		#Set Network settings
		Set-NetAdapterBinding CSV -ComponentID ms_tcpip6 -Enabled $False
		Set-NetAdapterBinding MGT -ComponentID ms_tcpip6 -Enabled $False
		Set-NetAdapterBinding LM -ComponentID ms_tcpip6 -Enabled $False
		Set-DNSClient -InterfaceAlias "LM" -RegisterThisConnectionsAddress $false
		Set-DNSClient -InterfaceAlias "CSV" -RegisterThisConnectionsAddress $false
		
		#Set Ip Addresses
		if (!((Get-NetIPAddress -InterfaceAlias "CSV" | Select-Object -ExpandProperty IPAddress) -eq $ClusterIP)) {
			New-NetIPAddress -InterfaceAlias CSV -AddressFamily IPv4 -IPAddress $ClusterIP -PrefixLength 24
		}
		if (!((Get-NetIPAddress -InterfaceAlias "LM" | Select-Object -ExpandProperty IPAddress) -eq $LiveMigrationIP)) {
			New-NetIPAddress -InterfaceAlias LM -AddressFamily IPv4 -IPAddress $LiveMigrationIP -PrefixLength 24
		}
		if (!((Get-NetIPAddress -InterfaceAlias "MGT" | Select-Object -ExpandProperty IPAddress) -eq $ManagementIP)) {
			New-NetIPAddress -InterfaceAlias MGT -AddressFamily IPv4 -IPAddress $ManagementIP -PrefixLength 24 -DefaultGateway $ManagementIPDFGW
		}
		
		if ($SecondaryDNS) {
			Get-NetIPInterface MGT | Set-DNSClientServerAddress -ServerAddresses $PrimaryDNS, $SecondaryDNS
		}
		else {
			Get-NetIPInterface MGT | Set-DNSClientServerAddress -ServerAddresses $PrimaryDNS
		}
		
		Invoke-CimMethod -ClassName Win32_NetworkAdapterConfiguration -MethodName EnableWINS -Arguments @{ DNSEnabledForWINSResolution = $false; WINSEnableLMHostsLookup = $false }
		Get-CimInstance win32_networkadapterconfiguration -filter 'IPEnabled=TRUE' | Invoke-CimMethod -MethodName settcpipnetbios -Arguments @{ TcpipNetbiosOptions = 2 }
		
		Get-NetAdapter -Physical | Where-Object { $_.status -eq "disconnected" } | Disable-NetAdapter -Confirm:$false
	}
}
function Set-HVHComputerName {
<#
.SYNOPSIS
Renames the Servername to the new name specified.
.DESCRIPTION
It's not so difficult.Specify a new computername.
.PARAMETER ServerName
Specify the new Server name
.EXAMPLE
Set-HVHComputerName -ServerName "HVH01"
#>
	[cmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
	param (
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Specify ServerName',
				   ValuefromPipelineByPropertyName = $true)]
		[string]$ServerName
	)
	if (!($env:COMPUTERNAME -eq $ServerName)) {
		if ($PSCmdlet.ShouldProcess("localhost")) {
			Rename-Computer -ComputerName $env:COMPUTERNAME -NewName $ServerName
		}
	}
}
function Join-HVH2Domain {
<#
.SYNOPSIS
Joins the local computer to a domain
.DESCRIPTION
See Synopsis. Specify Domain and credentials to join the local machine to a domain
.PARAMETER DomainName
Specify the new domain name to join the Hyper-V Server to.
.PARAMETER Cred
Specify the credentials you would like to use to join the domain.
.EXAMPLE
Join-HVH2Domain -DomainName "HyperV.Lab" -Cred (Get-Credential)
#>
	[cmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
	param (
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Domain Name',
				   Position = 1,
				   ValueFromPipeline = $true,
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('Domain')]
		[string]$DomainName,
		
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Credentials',
				   Position = 2,
				   ValueFromPipeline = $true,
				   ValuefromPipelineByPropertyName = $true)]
		$cred = (Get-Credential)
	)
	PROCESS {
		if ($PSCmdlet.ShouldProcess($DomainName)) {
			#Join computer to the domain
			Clear-DnsClientCache
			if (!((Get-WmiObject -Class Win32_NTDomain | Select -ExpandProperty DnsForestName) -eq $DomainName)) {
				Start-Sleep -Seconds 5
				Add-Computer -DomainName $DomainName -Credential $cred
			}
		}
	}
}
function Set-HVHAdminGroup {
<#
.SYNOPSIS
Creates a new AD Group on specified DC. This Group will be added to the local computer's Administrator Group.
.DESCRIPTION
This will setup a Remote Powershell session to the DC specified. It will run New-ADGroup to create a new group.
.PARAMETER GroupName
Specify the name of the group you want to create.
.PARAMETER OU
Specify the DN of the path where you want to create the group.
.PARAMETER DomainController
Specify the domain controller you want to remote powershell into.
.PARAMETER Cred
Specify the credentials you want to use to connect to the domain controller.
.EXAMPLE
Set-HVHAdminGroup -GroupName "HVH01_Local_Administrators" -OU "OU=GRP,OU=SYSCTR,DC=HyperV,DC=Lab" -DomainController "DC01.HyperV.Lab" -Cred (get-credential)
Will create the group HVH01_Local_Administrators in the OU GRP/SYSCTR/HYPERV/LAB. It is using the DC DC01.hyperv.lab. After it created the group it will be added to the local administrators group.
#>
	[cmdletBinding()]
	param (
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Group Name',
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('Group')]
		[string]$GroupName,
		
		[Parameter(Mandatory = $true,
				   Helpmessage = 'OU Path',
				   ValuefromPipelineByPropertyName = $true)]
		[string]$OU,
		
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Specify Domain Controller',
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('DC')]
		[string]$DomainController,
		
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Credentials',
				   ValuefromPipelineByPropertyName = $true)]
		$cred
	)
	#Create a Local Admin group in the AD
	set-item wsman:localhost\client\trustedhosts -value * -Confirm:$false -Force
	$sess = New-PSSession -ComputerName $DomainController -Credential $cred
	Invoke-Command -Session $sess -ScriptBlock {
		try {
			Import-Module ActiveDirectory
			New-ADGroup -Name $args[0] -GroupScope DomainLocal -GroupCategory Security -Path $args[1] -ErrorAction Stop -ErrorVariable aderr -PassThru
		}
		catch {
			$aderr
		}
	} -ArgumentList ($GroupName, $OU)
	Remove-PSSession $sess
	Start-Sleep -Seconds 10
	#Add the new created group and the deployment user to the Local Administrators group
	try {
		([ADSI]"WinNT://$env:COMPUTERNAME/Administrators,group").add("WinNT://$(Get-WmiObject -Class Win32_NTDomain |Select -ExpandProperty DomainName)/$GroupName,group")
		
	}
	catch {
	}
}
workflow Deploy-HyperVHost {
	[cmdletBinding()]
	param (
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Management IP Address',
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('MGTIP')]
		[ipaddress]$ManagementIP,
		
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Management Gateway IP Address',
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('MGTDFGWIP')]
		[ipaddress]$ManagementIPDFGW,
		
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Management Vlan ID',
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('MGTVLANID')]
		[int]$ManagementVLANID,
		
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Live Migration IP Address',
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('LMIP')]
		[ipaddress]$LiveMigrationIP,
		
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Live Migration VLAN ID',
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('LMVLANID')]
		[int]$LiveMigrationVLANID,
		
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Cluster (CSV) IP Address',
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('CSVIP')]
		[ipaddress]$ClusterIP,
		
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Cluster (CSV) VLAN ID',
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('CSVVLANID')]
		[int]$ClusterVLANID,
		
		[Parameter(Mandatory = $false,
				   Helpmessage = 'Backup IP Address',
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('BCKIP')]
		[ipaddress]$BackupIP,
		
		[Parameter(Mandatory = $false,
				   Helpmessage = 'Backup VLAN ID',
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('BCKVLANID')]
		[int]$BackupVLANID,
		
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Specify new server name',
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('NewComputerName')]
		[string]$ServerName,
		
		[Parameter(Mandatory = $true,
				   Position = 9,
				   Helpmessage = 'Specify DNS Server',
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('PDNS')]
		[ipaddress]$PrimaryDNS,
		
		[Parameter(Mandatory = $false,
				   Helpmessage = 'Specify Secondary DNS Server',
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('SDNS')]
		[ipaddress]$SecondaryDNS,
		
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Specify Domain name',
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('Domain')]
		[string]$DomainName,
		
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Specify Domain Controller',
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('DC')]
		[string]$DomainController,
		
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Specify OU',
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('OU')]
		[string]$OUPath,
		
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Specify new Groups name',
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('Group')]
		[string]$GroupName,
		
		[Parameter(Mandatory = $false,
				   Helpmessage = 'Deploy HVH on HVH',
				   ValuefromPipelineByPropertyName = $true)]
		[switch]$lab,
		
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Credentials',
				   ValuefromPipelineByPropertyName = $true)]
		$cred
		
	)
	
	Set-HVHFirewallRules
	
	Set-HVHRoles
	
	if (!($lab)) {
		Set-HVHNetwork -ManagementIP $ManagementIP -ManagementVLANID $ManagementVLANID -ManagementIPDFGW $ManagementIPDFGW -LiveMigrationIP $LiveMigrationIP -LiveMigrationVLANID $LiveMigrationVLANID -ClusterIP $ClusterIP -ClusterVLANID $ClusterVLANID -PrimaryDNS $PrimaryDNS -SecondaryDNS $SecondaryDNS -Confirm:$false
	}
	else {
		Set-HVHNetwork -ManagementIP $ManagementIP -ManagementVLANID $ManagementVLANID -ManagementIPDFGW $ManagementIPDFGW -LiveMigrationIP $LiveMigrationIP -LiveMigrationVLANID $LiveMigrationVLANID -ClusterIP $ClusterIP -ClusterVLANID $ClusterVLANID -PrimaryDNS $PrimaryDNS -SecondaryDNS $SecondaryDNS -lab -Confirm:$false
	}
	Join-HVH2Domain -DomainName $DomainName -cred $cred -Confirm:$false
	
	Set-HVHComputerName -ServerName $ServerName -Confirm:$false
	
	Set-HVHAdminGroup -GroupName $GroupName -OU $OUPath -DomainController $DomainController -cred $cred
	
	Restart-Computer -Force
}
function Set-HVHCluster {
<#
.SYNOPSIS
Configure the node for a new or add the node to an existing cluster.
.DESCRIPTION
See SYNOPSIS. Specify new clustername and ip address. Or add it to a existing cluster by enter the clustername. 
.PARAMETER Clustername
Specify the CLustername to create or the existing clustername to add this node to.
.PARAMETER ClusterIPAddress
Specify the new cluster ip address.
.PARAMETER AddNode
Switch to specify to add the node to an existing cluster.
.EXAMPLE
Set-HVHCluster -ClusterName "HVHCLS01" -ClusterIPAddress "10.10.0.30"
Creates a new cluster named HVHCLS01 with the cluster ip address 10.10.0.30.
.EXAMPLE
Set-HVHCluster -ClusterName "HVHCLS01" -AddNode
Add the current node to an existing cluster named HVHCLS01.
#>
	[cmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
	param (
		[Parameter(Mandatory = $true,
				   Helpmessage = 'Specify Cluster Name',
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('Cluster')]
		[string]$ClusterName,
		
		[Parameter(Mandatory = $false,
				   ParameterSetName = "New Cluster",
				   Helpmessage = 'Specify Cluster IP',
				   ValuefromPipelineByPropertyName = $true)]
		[Alias('ClusterIP')]
		[string]$ClusterIPAddress,
		
		[Parameter(Mandatory = $false,
				   ParameterSetName = "Add to existing Cluster",
				   Helpmessage = 'Add to excisting Cluster',
				   ValuefromPipelineByPropertyName = $true)]
		[switch]$AddNode
		
	)
	$ServerName = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Name
	if ($PSCmdlet.ShouldProcess($ServerName)) {
		if ($AddNode) {
			Add-ClusterNode -Cluster $ClusterName
		}
		else {
			New-Cluster -Name $ClusterName -Node @($ServerName) -StaticAddress $ClusterIPAddress -NoStorage
			
			$MGT = (Get-NetIPAddress -InterfaceAlias MGT | Select-Object -ExpandProperty IPAddress -first 1)
			$MGT = ($MGT).ToString()
			$Subnet = $MGT.Split('.')
			$x = $Subnet[0] + "." + $Subnet[1] + "." + $Subnet[2] + ".0"
			(Get-ClusterNetwork | Where-Object { $_.Address -eq $x }).Name = "MGT"
			
			$CSV = (Get-NetIPAddress -InterfaceAlias CSV | Select-Object -ExpandProperty IPAddress -first 1)
			$CSV = ($CSV).ToString()
			$Subnet = $CSV.Split('.')
			$x = $Subnet[0] + "." + $Subnet[1] + "." + $Subnet[2] + ".0"
			(Get-ClusterNetwork | Where-Object { $_.Address -eq $x }).Name = "CSV"
			
			$LM = (Get-NetIPAddress -InterfaceAlias LM | Select-Object -ExpandProperty IPAddress -first 1)
			$LM = ($LM).ToString()
			$Subnet = $LM.Split('.')
			$x = $Subnet[0] + "." + $Subnet[1] + "." + $Subnet[2] + ".0"
			(Get-ClusterNetwork | Where-Object { $_.Address -eq $x }).Name = "LM"
			
			Get-ClusterResourceType -Name "Virtual Machine" | Set-ClusterParameter -Name MigrationExcludeNetworks -Value ([String]::Join(";", (Get-ClusterNetwork | Where-Object { ($_.Name -ne "LM") }).ID))
		}
	}
}

Export-ModuleMember -Function Set-HVHFirewallRules, Set-HVHRoles, Set-HVHNetwork, Set-HVHComputerName, Join-HVH2Domain, Set-HVHAdminGroup, Set-HVHCluster, Deploy-HyperVHost