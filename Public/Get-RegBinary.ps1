function Get-RegBinary
{
	<#
	.SYNOPSIS
		   Retrieves a binary data registry value (REG_BINARY) from local or remote computers.

	.DESCRIPTION
		   Use Get-RegBinary to retrieve a binary data registry value (REG_BINARY) from local or remote computers.

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

	.PARAMETER Ping
		   Use ping to test if the machine is available before connecting to it.
		   If the machine is not responding to the test a warning message is output.

	.EXAMPLE
		$Key = "SOFTWARE\Microsoft\Internet Explorer\Registration"
		Get-RegBinary -Key $Key -Value DigitalProductId

		ComputerName Hive            Key                  Value              Data                 Type
		------------ ----            ---                  -----              ----                 ----
		COMPUTER1    LocalMachine    SOFTWARE\Microsof... IE Installed Date  {114, 76, 180, 17... Binary

		Description
		-----------
		The command gets the DigitalProductId binary value from the local computer.
		The name of ComputerName parameter, which is optional, is omitted.

	.EXAMPLE
		"SERVER1","SERVER2","SERVER3" | Get-RegBinary -Key $Key -Value DigitalProductId -Ping

		ComputerName Hive         Key                                               Value            Data              Type
		------------ ----         ---                                               -----            ----              ----
		SERVER1      LocalMachine SOFTWARE\Microsoft\Internet Explorer\Registration DigitalProductId {164, 0, 0, 0...} Binary
		SERVER2      LocalMachine SOFTWARE\Microsoft\Internet Explorer\Registration DigitalProductId {164, 0, 0, 0...} Binary
		SERVER3      LocalMachine SOFTWARE\Microsoft\Internet Explorer\Registration DigitalProductId {164, 0, 0, 0...} Binary

		Description
		-----------
		The command gets the DigitalProductId binary value from remote computers.
		When the Switch parameter Ping is specified the command issues a ping test to each computer.
		If the computer is not responding to the ping request a warning message is written to the console and the computer is not processed.

	.EXAMPLE
		Get-Content servers.txt | Get-RegBinary -Key $Key -Value DigitalProductId

		ComputerName Hive         Key                                               Value            Data              Type
		------------ ----         ---                                               -----            ----              ----
		SERVER1      LocalMachine SOFTWARE\Microsoft\Internet Explorer\Registration DigitalProductId {164, 0, 0, 0...} Binary
		SERVER2      LocalMachine SOFTWARE\Microsoft\Internet Explorer\Registration DigitalProductId {164, 0, 0, 0...} Binary
		SERVER3      LocalMachine SOFTWARE\Microsoft\Internet Explorer\Registration DigitalProductId {164, 0, 0, 0...} Binary

		Description
		-----------
		The command uses the Get-Content cmdlet to get the server names from a text file.

	.EXAMPLE
		Get-RegString -Hive LocalMachine -Key $Key -Value DigitalProductId | Test-RegValue -ComputerName SERVER1,SERVER2 -Ping
		True
		True

		Description
		-----------
		he command gets the DigitalProductId binary value from the local computer.
		The output is piped to the Test-RegValue function to check if the value exists on two remote computers.
		When the Switch parameter Ping is specified the command issues a ping test to each computer.
		If the computer is not responding to the ping request a warning message is written to the console and the computer is not processed.

	.OUTPUTS
		PSFanatic.Registry.RegistryValue (PSCustomObject)


	.LINK
		Set-RegBinary
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
}presentpresent