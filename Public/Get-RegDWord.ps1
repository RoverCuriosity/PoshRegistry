function Get-RegDWord
{

	<#
	.SYNOPSIS
	       Retrieves a 32-bit binary number (REG_DWORD) registry value from local or remote computers.

	.DESCRIPTION
	       Use Get-RegDWord to retrieve a 32-bit binary number (REG_DWORD) registry value from local or remote computers.

	.PARAMETER ComputerName
	    	An array of computer names. The default is the local computer.

	.PARAMETER Hive
	   	The HKEY to open, from the RegistryHive enumeration. The default is 'LocalMachine'.
	   	Possible values:

		- ClassesRoot
		- CurrentUser
		- LocalMachine
		- Users
		- PerformanceData
		- CurrentConfig
		- DynData

	.PARAMETER Key
	       The path of the registry key to open.

	.PARAMETER Value
	       The name of the registry value.

	.PARAMETER AsHex
	       Returnes the value in HEX notation.

	.PARAMETER Ping
	       Use ping to test if the machine is available before connecting to it.
	       If the machine is not responding to the test a warning message is output.

	.EXAMPLE
		$Key = "System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
		Get-RegDWord -ComputerName SERVER1 -Hive LocalMachine -Key $Key -Value PortNumber

		ComputerName Hive            Key                  Value       Data  Type
		------------ ----            ---                  -----       ----  ----
		SERVER1      LocalMachine    System\CurrentCon... PortNumber  3389  DWord


		Description
		-----------
	   	The command gets the Terminal Server's listening port from SERVER1 server.

	.EXAMPLE
		Get-RegDWord -ComputerName SERVER1 -Key $Key -Value PortNumber

		ComputerName Hive            Key                  Value       Data  Type
		------------ ----            ---                  -----       ----  ----
		SERVER1      LocalMachine    System\CurrentCon... PortNumber  3389  DWord


		Description
		-----------
	   	The command gets the Terminal Server's listening port from SERVER1 server.
	   	You can omit the -Hive parameter (which is optional), if the registry Hive the key resides in is LocalMachine (HKEY_LOCAL_MACHINE).

	.EXAMPLE
		Get-RegDWord -CN SERVER1,SERVER2 -Key $Key -Value PortNumber -AsHex

		ComputerName Hive            Key                  Value       Data   Type
		------------ ----            ---                  -----       ----   ----
		SERVER1      LocalMachine    System\CurrentCon... PortNumber  0xd3d  DWord
		SERVER2      LocalMachine    System\CurrentCon... PortNumber  0xd3d  DWord


		Description
		-----------
	   	This command gets the Terminal Server's listening port from SERVER1 and SERVER2.
	   	The command uses the ComputerName parameter alias 'CN' to specify a collection of computer names.
	   	When the AsHex Switch Parameter is used, the value's data returnes in HEX notation.

	.OUTPUTS
		PSFanatic.Registry.RegistryValue (PSCustomObject)

	.LINK
		Set-RegQWord
		Get-RegValue
		Remove-RegValue
		Test-RegValue
	#>


	[OutputType('PSFanatic.Registry.RegistryValue')]
	[CmdletBinding(DefaultParameterSetName="__AllParameterSets")]

	param(
		[Parameter(
			Position=0,
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true,
			HelpMessage="An array of computer names. The default is the local computer."
		)]
		[Alias("CN","__SERVER","IPAddress")]
		[string[]]$ComputerName="",

		[Parameter(
			Position=1,
			ValueFromPipelineByPropertyName=$true,
			HelpMessage="The HKEY to open, from the RegistryHive enumeration. The default is 'LocalMachine'."
		)]
		[ValidateSet("ClassesRoot","CurrentUser","LocalMachine","Users","PerformanceData","CurrentConfig","DynData")]
		[string]$Hive="LocalMachine",

		[Parameter(
			Mandatory=$true,
			Position=2,
			ValueFromPipelineByPropertyName=$true,
			HelpMessage="The path of the subkey to open."
		)]
		[string]$Key,

		[Parameter(
			Mandatory=$true,
			Position=3,
			ValueFromPipelineByPropertyName=$true,
			HelpMessage="The name of the value to get."
		)]
		[string]$Value,

		[switch]$AsHex,

		[switch]$Ping
	)


	process
	{

	    	Write-Verbose "Enter process block..."

		foreach($c in $ComputerName)
		{
			try
			{
				if($c -eq "")
				{
					$c=$env:COMPUTERNAME
					Write-Verbose "Parameter [ComputerName] is not presnet, setting its value to local computer name: [$c]."

				}

				if($Ping)
				{
					Write-Verbose "Parameter [Ping] is presnet, initiating Ping test"

					if( !(Test-Connection -ComputerName $c -Count 1 -Quiet))
					{
						Write-Warning "[$c] doesn't respond to ping."
						return
					}
				}


				Write-Verbose "Starting remote registry connection against: [$c]."
				Write-Verbose "Registry Hive is: [$Hive]."
				$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]$Hive,$c)

				Write-Verbose "Open remote subkey: [$Key]"
				$subKey = $reg.OpenSubKey($Key)

				if(!$subKey)
				{
					Throw "Key '$Key' doesn't exist."
				}

				Write-Verbose "Get value name : [$Value]"
				$rv = $subKey.GetValue($Value,-1)

				if($rv -eq -1)
				{
					Write-Error "Cannot find value [$Value] because it does not exist."
				}
				else
				{
					if($AsHex)
					{
						Write-Verbose "Parameter [AsHex] is presnet, return value as HEX."
						$rv = "0x{0:x}" -f $rv
					}
					else
					{
						Write-Verbose "Parameter [AsHex] is not presnet, return value as INT."
					}


					Write-Verbose "Create PSFanatic registry value custom object."
					$pso = New-Object PSObject -Property @{
						ComputerName=$c
						Hive=$Hive
						Value=$Value
						Key=$Key
						Data=$rv
						Type=$subKey.GetValueKind($Value)
					}

					Write-Verbose "Adding format type name to custom object."
					$pso.PSTypeNames.Clear()
					$pso.PSTypeNames.Add('PSFanatic.Registry.RegistryValue')
					$pso

				}

				Write-Verbose "Closing remote registry connection on: [$c]."
				$subKey.close()
			}
			catch
			{
				Write-Error $_
			}
		}

		Write-Verbose "Exit process block..."
	}
}presentpresentpresentpresent