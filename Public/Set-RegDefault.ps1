function Set-RegDefault
{

	<#
	.SYNOPSIS
	       Sets the default value (REG_SZ) of the registry key on local or remote computers.

	.DESCRIPTION
	       Use Set-RegDefault to set the default value (REG_SZ) of the registry key on local or remote computers.

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

	.PARAMETER Data
	       The data to set in the registry default value.

	.PARAMETER Force
	       Overrides any confirmations made by the command. Even using the Force parameter, the function cannot override security restrictions.

	.PARAMETER Ping
	       Use ping to test if the machine is available before connecting to it.
	       If the machine is not responding to the test a warning message is output.

	.PARAMETER PassThru
	       Passes the newly custom object to the pipeline. By default, this function does not generate any output.

	.EXAMPLE
		$Key = "SOFTWARE\MyCompany"
		"SERVER1","SERVER2","SERVER3" | Set-RegDefault -Key $Key -Data MyDefaultValue -Ping -PassThru -Force

		ComputerName Hive            Key                  Value      Data            Type
		------------ ----            ---                  -----      ----            ----
		SERVER1      LocalMachine    SOFTWARE\MyCompany   (Default)  MyDefaultValue  String
		SERVER2      LocalMachine    SOFTWARE\MyCompany   (Default)  MyDefaultValue  String
		SERVER3      LocalMachine    SOFTWARE\MyCompany   (Default)  MyDefaultValue  String

		Description
		-----------
		Set the reg default value of the SOFTWARE\MyCompany subkey on three remote computers local machine hive (HKLM) .
		Ping each server before setting the value and use -PassThru to get the objects back. Use Force to override confirmations.

	.OUTPUTS
		PSFanatic.Registry.RegistryValue (PSCustomObject)

	.LINK
		Get-RegDefault
		Get-RegValue
	#>


	[OutputType('PSFanatic.Registry.RegistryValue')]
	[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High',DefaultParameterSetName="__AllParameterSets")]

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
			HelpMessage="The data to set in the registry default value."
		)]
		[AllowEmptyString()]
		[string]$Data,

		[switch]$Ping,
		[switch]$Force,
		[switch]$PassThru
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

				Write-Verbose "Open remote subkey: [$Key] with write access."
				$subKey = $reg.OpenSubKey($Key,$true)

				if(!$subKey)
				{
					Throw "Key '$Key' doesn't exist."
				}

				if($Force -or $PSCmdlet.ShouldProcess($c,"Set Registry Default Value '$Hive\$Key\$Value'"))
				{
					Write-Verbose "Parameter [Force] or [Confirm:`$False] is presnet, suppressing confirmations."
					Write-Verbose "Setting [$Key] default value."
					$subKey.SetValue($null,$Data)
				}


				if($PassThru)
				{
					Write-Verbose "Parameter [PassThru] is presnet, creating PSFanatic registry custom objects."
					Write-Verbose "Create PSFanatic registry value custom object."

					$pso = New-Object PSObject -Property @{
						ComputerName=$c
						Hive=$Hive
						Value="(Default)"
						Key=$Key
						Data=$subKey.GetValue($null)
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