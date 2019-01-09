Function Enable-RDP
{
<# 
	.SYNOPSIS 
		Remotly enable RDP on domain machines or workgroup.

	.DESCRIPTION 
		Use Enable-RDP to enable RDP on all domain machines or workgroup.

	.PARAMETER ComputerName 
		Specific Computer Name or Ldap path to object or set of object like computer, OU or whole domain.

	.EXAMPLE 
		Get-ADComputer PC1 | Enable-RDP

		RDP is enabled in Remote Registry on machine: PC1

	.EXAMPLE 
		Enable-RDP -ComputerName "CN=Computers,DC=your,DC=domain,DC=com"

		RDP is enabled in Remote Registry on machine: PC1
		RDP is enabled in Remote Registry on machine: PC2
		WARNING: Machine: PC3 is unavailable
		RDP is enabled in Remote Registry on machine: PC4

	.EXAMPLE 
		"PC1", "PC2" | Enable-RDP

		RDP is enabled in Remote Registry on machine: PC1
		RDP is enabled in Remote Registry on machine: PC2
		
	.NOTES 
		Author: Michal Gajda 
#> 

	[CmdletBinding(
		SupportsShouldProcess=$True,
		ConfirmImpact="High" 
	)]
	param
	(
		[Parameter(ValueFromPipeline=$True)]
		[Array]$ComputerName = "LocalHost"
	)

	Begin{}

	Process
	{
		if($ComputerName -match "=")
		{
			Write-Verbose "Searching LDAP Objects in path: $ComputerName" 
			$Searcher=[adsisearcher]"(&(objectCategory=computer)(objectClass=computer))" 

			$ComputerName = ([String]$ComputerName).replace("LDAP://","")
			$Searcher.SearchRoot="LDAP://$ComputerName"
			$Results=$Searcher.FindAll()
			$Direct = $false			
		}
		else
		{
			Write-Verbose "Direct access to specific machine: $ComputerName" 
			$Results = $ComputerName			
			$Direct = $true
		}
		
		Foreach($result in $results)
		{
			if($Direct)
			{
				$ComputerName = $result 
			}
			else
			{
				$ComputerName = $result.Properties.Item("Name") 
			}
			$EnableFlag = $null
				
			if ($pscmdlet.ShouldProcess($ComputerName,"Enable RDP"))
			{
				Do
				{
					#Check Remote Registry status via WinRM 
					Write-Verbose "Checking Remote Registry status via WinRM on machine: $ComputerName" 
					$RRStatusIC = Invoke-Command -ComputerName $ComputerName -ScriptBlock {C:\Windows\System32\sc query RemoteRegistry} -ErrorAction SilentlyContinue

					if([string]$RRStatusIC -eq "")
					{
						#Check Remote Registry status via WMI 
						Write-Verbose "Checking Remote Registry status via WMI on machine: $ComputerName" 
						$RRStatusGWMI = Get-WmiObject -computer $ComputerName Win32_Service -Filter "Name='RemoteRegistry'" -ErrorAction SilentlyContinue
	
						if($RRStatusGWMI -notlike $null)
						{
							#Check Remote Registry status 
							Write-Verbose "Checking Remote Registry status via Get-Service on machine: $ComputerName"  
							$RRStatusGS = Get-Service -ComputerName $ComputerName RemoteRegistry -ErrorAction SilentlyContinue
							
							if($RRStatusGS -notlike $null)
							{
								#Get-Service, WMI and WinRM not respond.
								$EnableFlag = $false
								Write-Warning "Machine: $ComputerName is unavailable"
							}
						}
						else
						{
							#Start Remote Registry via WMI
							Try
							{
								Write-Verbose "Starting Remote Registry via WMI on machine: $ComputerName" 
								(Get-WmiObject -computer $ComputerName Win32_Service -Filter "Name='RemoteRegistry'" -ErrorAction SilentlyContinue ).InvokeMethod("StartService",$null) | Out-Null
							}
							Catch
							{
								$EnableFlag = $false
								Write-Warning "Can't start Remote Registry on machine: $ComputerName"
							}
						}
						
					}
					else
					{
						if($RRStatusIC -match "STOPPED")
						{
							#Start Remote Registry via WinRM
							Write-Verbose "Starting Remote Registry via WinRM on machine: $ComputerName" 
							Invoke-Command -ComputerName $ComputerName -ScriptBlock {net start RemoteRegistry} -ErrorAction SilentlyContinue | Out-Null
						}
						else
						{
							Write-Verbose "Remote Registry is Running on machine: $ComputerName"
							$EnableFlag = $true
						}
					}
				}
				While($EnableFlag -eq $null)
				
				if($EnableFlag)
				{
					#Try modify registry value 
					Try
					{
						Write-Verbose "Modifying Remote Registry on machine: $ComputerName" 
						$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $ComputerName)
						$regkey = $reg.OpenSubKey("SYSTEM\\CurrentControlSet\\Control\\Terminal Server",$true)
						$regkey.SetValue('fDenyTSConnections','0','DWord')  
		
						Write-Host "RDP is enabled in Remote Registry on machine: $ComputerName"           
					}
					Catch
					{
						#Sometimes can't open remote key by HostName then try by IP
						[string]$HostIP = ([System.Net.Dns]::GetHostByName($ComputerName)).AddressList
						Try
						{
							Write-Verbose "Modifying Remote Registry by IP on machine: $ComputerName" 
							$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $HostIP)
							$regkey = $reg.OpenSubKey("SYSTEM\\CurrentControlSet\\Control\\Terminal Server",$true)
							$regkey.SetValue('fDenyTSConnections','0','DWord')  
							#$regkey.GetValue("fDenyTSConnections",-1)
			
							Write-Host "RDP is enabled in Remote Registry on machine: $ComputerName"  
						}
						Catch
						{
							Write-Warning "You havent access to Remote Registry on machine: $ComputerName"
						}
					}

					#Enable firewall rules 
					Write-Verbose "Enable firewall rules on machine: $ComputerName" 
					$fw = Invoke-Command -ComputerName $ComputerName -ScriptBlock {netsh firewall set service remoteadmin enable} -ErrorAction SilentlyContinue
					$fw = Invoke-Command -ComputerName $ComputerName -ScriptBlock {netsh firewall set service remotedesktop enable} -ErrorAction SilentlyContinue
					if(!($fw -match "Ok."))
					{
						Write-Warning "Can't enable firewall rules on machine: $ComputerName. Try use maunaly winrm quickconfig on remote machine."
					}
					
					if([string]$RRStatusIC -ne "")
					{
						#Restart Terminal Service service via WinRM
						Write-Verbose "Restart Terminal Service service via WinRM on machine: $ComputerName"
						Invoke-Command -ComputerName $ComputerName -ScriptBlock {net stop UmRdpService} -ErrorAction SilentlyContinue | Out-Null
						Invoke-Command -ComputerName $ComputerName -ScriptBlock {net stop TermService} -ErrorAction SilentlyContinue | Out-Null
						Invoke-Command -ComputerName $ComputerName -ScriptBlock {net start TermService} -ErrorAction SilentlyContinue | Out-Null
						Invoke-Command -ComputerName $ComputerName -ScriptBlock {net start UmRdpService} -ErrorAction SilentlyContinue | Out-Null
					}
					else
					{
						#Restart Terminal Service service via WMI
						Try
						{
							Write-Verbose "Restart Terminal Service service via WMI on machine: $ComputerName"
							(Get-WmiObject -computer $ComputerName Win32_Service -Filter "Name='UmRdpService'" -ErrorAction SilentlyContinue ).InvokeMethod("StopService",$null) | Out-Null  
							(Get-WmiObject -computer $ComputerName Win32_Service -Filter "Name='TermService'" -ErrorAction SilentlyContinue ).InvokeMethod("StopService",$null) | Out-Null
							(Get-WmiObject -computer $ComputerName Win32_Service -Filter "Name='TermService'" -ErrorAction SilentlyContinue ).InvokeMethod("StartService",$null) | Out-Null
							(Get-WmiObject -computer $ComputerName Win32_Service -Filter "Name='UmRdpService'" -ErrorAction SilentlyContinue ).InvokeMethod("StartService",$null) | Out-Null 
						}
						Catch
						{
							Write-Warning "Can't restart Terminal Service on machine: $ComputerName. Try Reboot this machine manualy."
						}	
					}
				}
			}  
		}
	} 

	End{} 
}
