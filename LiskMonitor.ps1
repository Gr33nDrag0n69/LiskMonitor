<#
.SYNOPSIS
	Monitoring Tool for Lisk Nodes and Delegates.
	
.DESCRIPTION
	
.PARAMETER ShowMessage
	Output message to screen. (Doesn't affect e-mail functionnality)

.PARAMETER SendTestEmail
	Send a test e-mail to the configured e-mails for INFO, WARNING and ERROR.

.PARAMETER ShowMainNetPublicKey
	Internal Helper Tool to find the public key associated to an address.

.PARAMETER ShowTestNetPublicKey
	Internal Helper Tool to find the public key associated to an address.

.EXAMPLE
	.\LiskMonitor.ps1
	
	Normal run built to be executed by a scheduled task.
	
.EXAMPLE
	.\LiskMonitor.ps1 -ShowMessage
	
	To see on-screen output when script is runned manually.
	
.EXAMPLE
	.\LiskMonitor.ps1 -SendTestEmail
	
	To execute the script in e-mail test mode.
	
.NOTES
	Version :	1.0.0.0
	Author  :	Gr33nDrag0n
	History :	2016/05/29 - Last Modification
#>

###########################################################################################################################################
### Parameters
###########################################################################################################################################

[CmdletBinding()]
Param(
	[parameter( Mandatory=$False )]
	[switch] $ShowMessage,
	
	[parameter( Mandatory=$False )]
	[switch] $SendTestEmail,
	
	[parameter( Mandatory=$False )]
	[switch] $ShowMainNetPublicKey,
	
	[parameter( Mandatory=$False )]
	[switch] $ShowTestNetPublicKey
	)

###########################################################################################################################################
### Host Initialization
###########################################################################################################################################

[System.GC]::Collect()
$error.Clear()

#######################################################################################################################
# Internal Variables Initialization
#######################################################################################################################

$Script:Config = @{}
$Config.Email = @{}
$Config.MainNet = @{}
$Config.MainNet.Account = @{}
$Config.MainNet.Nodes = @()
$Config.TestNet = @{}
$Config.TestNet.Account = @{}
$Config.TestNet.Nodes = @()
$Private:Banner = "LiskMonitor v1.0 | Vote for gr33ndrag0n Delegate | Donation: 7829179317180986041L"

#######################################################################################################################
# Configurable Variables | MANDATORY !!! EDIT THIS SECTION !!!
#######################################################################################################################

### E-Mail ###===============================================================================

# Email List support multiple entries like this: @('email@domain.com','sms@domain.com','5556781212l@myphoneprovider.com')

$Config.Email.SenderEmail      = ''
$Config.Email.SenderSmtp       = ''

$Config.Email.SendErrorMail    = $True
$Config.Email.ErrorEmailList   = @('')

$Config.Email.SendWarningMail  = $True
$Config.Email.WarningEmailList = @('')

$Config.Email.SendInfoMail     = $True
$Config.Email.InfoEmailList    = @('')

### MainNet ###===============================================================================

$Config.MainNet.MonitoringEnabled = $True
$Config.MainNet.MonitorNodeBlockHeight = $True
# Warning: You Delegate must have Forging Enabled on one of your node to enable this feature.
$Config.MainNet.MonitorDelegateForgingStatus = $True
# Warning: You must be and "Active Delegate" to enable this feature.
$Config.MainNet.MonitorDelegateLastForgedBlockAge = $False

$Config.MainNet.Account.Delegate  = ''
$Config.MainNet.Account.PublicKey = ''
$Config.MainNet.Account.Address   = ''

$Config.MainNet.Nodes += @{Name='lisknode.io';URI='https://lisknode.io/'}
#$Config.MainNet.Nodes += @{Name='';URI='https:///'}

### TestNet ###===============================================================================

# Warning: Do NOT activate TestNet Monitoring until re-launch of next version !

$Config.TestNet.MonitoringEnabled = $False
$Config.TestNet.MonitorNodeBlockHeight	= $True
# Warning: You Delegate must have Forging Enabled on one of your node to enable this feature.
$Config.TestNet.MonitorDelegateForgingStatus = $True
# Warning: You must be and "Active Delegate" to enable this feature.
$Config.TestNet.MonitorDelegateLastForgedBlockAge = $False

$Config.TestNet.Account.Delegate  = ''
$Config.TestNet.Account.PublicKey = ''
$Config.TestNet.Account.Address   = ''

$Config.TestNet.Nodes += @{Name='lisktestnet.pw';URI='https://lisktestnet.pw/'}
#$Config.TestNet.Nodes += @{Name='';URI='https:///'}

###########################################################################################################################################
# FUNCTIONS
###########################################################################################################################################

Function Get-LiskAccountPublicKey {

    [CmdletBinding()]
    Param(
		[parameter(Mandatory = $True)]
		[System.String] $URI,
		
        [parameter(Mandatory = $True)]
		[System.String] $Address
        )
	
	$Private:Output = Invoke-LiskApiCall -Method Get -URI $( $URI+'api/accounts/getPublicKey?address='+$Address )
	if( $Output.success -eq $True ) { $Output.publicKey }
}

###########################################################################################################################################

Function Get-LiskSyncStatus {

    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $True)]
		[System.String] $URI
        )
	
	$Private:Output = Invoke-LiskApiCall -Method Get -URI $( $URI+'api/loader/status/sync' )
	if( $Output.success -eq $True )
	{
		$Output | Select-Object -Property Syncing, Blocks, Height
	}
}

###########################################################################################################################################

Function Get-LiskBlockList {

    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $True)]
		[System.String] $URI,
		
        [parameter(Mandatory = $False)]
		[System.String] $TotalFee='',
		
        [parameter(Mandatory = $False)]
		[System.String] $TotalAmount='',
		
        [parameter(Mandatory = $False)]
		[System.String] $PreviousBlock='',
		
        [parameter(Mandatory = $False)]
		[System.String] $Height='',
		
        [parameter(Mandatory = $False)]
		[System.String] $GeneratorPublicKey='',
		
        [parameter(Mandatory = $False)]
		[System.String] $Limit='',
		
        [parameter(Mandatory = $False)]
		[System.String] $Offset='',
		
        [parameter(Mandatory = $False)]
		[System.String] $OrderBy=''
        )

	if( ( $TotalFee -eq '' ) -and ( $TotalAmount -eq '' ) -and ( $PreviousBlock -eq '' ) -and ( $Height -eq '' ) -and ( $GeneratorPublicKey -eq '' ) -and ( $Limit -eq '' ) -and ( $Offset -eq '' ) -and ( $OrderBy -eq '' ) )
	{
		Write-Warning 'Get-LiskBlockList | The usage of at least one parameter is mandatory. Nothing to do.'
	}
	else
	{
		$Private:Query = '?'
		
		if( $TotalFee -ne '' )
		{
			if( $Query -ne '?' ) { $Query += '&' }
			$Query += "totalFee=$TotalFee"
		}
		if( $TotalAmount -ne '' )
		{
			if( $Query -ne '?' ) { $Query += '&' }
			$Query += "totalAmount=$TotalAmount"
		}
		if( $PreviousBlock -ne '' )
		{
			if( $Query -ne '?' ) { $Query += '&' }
			$Query += "previousBlock=$PreviousBlock"
		}
		if( $Height -ne '' )
		{
			if( $Query -ne '?' ) { $Query += '&' }
			$Query += "height=$Height"
		}
		if( $GeneratorPublicKey -ne '' )
		{
			if( $Query -ne '?' ) { $Query += '&' }
			$Query += "generatorPublicKey=$GeneratorPublicKey"
		}
		if( $Limit -ne '' )
		{
			if( $Query -ne '?' ) { $Query += '&' }
			$Query += "limit=$Limit"
		}
		if( $Offset -ne '' )
		{
			if( $Query -ne '?' ) { $Query += '&' }
			$Query += "offset=$Offset"
		}
		if( $OrderBy -ne '' )
		{
			if( $Query -ne '?' ) { $Query += '&' }
			$Query += "orderBy=$OrderBy"
		}
		
		$Private:Output = Invoke-LiskApiCall -Method Get -URI $( $URI+'api/blocks'+$Query )
		if( $Output.success -eq $True ) { $Output.blocks }
	}
}

###########################################################################################################################################

Function Get-LiskDelegateForgingStatus {

    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $True)]
		[System.String] $URI,
		
		[parameter(Mandatory = $True)]
		[System.String] $PublicKey
        )
	
	$Private:Output = Invoke-LiskApiCall -Method Get -URI $( $URI+'api/delegates/forging/status?publicKey='+$PublicKey )
	if( $Output.success -eq $True ) { $Output.enabled }
}

###########################################################################################################################################

Function Invoke-LiskApiCall {

    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $True)]
		[System.String] $URI,
		
		[parameter(Mandatory = $True)]
		[ValidateSet('Get','Post','Put')]
		[System.String] $Method,
		
		[parameter(Mandatory = $False)]
		[System.Collections.Hashtable] $Body = @{}
        )
		
	if( $Method -eq 'Get' )
	{
		Write-Verbose "Invoke-LiskApiCall [$Method] => $URI"
		$Private:WebRequest = Invoke-WebRequest -Uri $URI -Method $Method
	}
	elseif( ( $Method -eq 'Post' ) -or ( $Method -eq 'Put' ) )
	{
		Write-Verbose "Invoke-LiskApiCall [$Method] => $URI"
		$Private:WebRequest = Invoke-WebRequest -Uri $URI -Method $Method -Body $Body
	}
	
	if( ( $WebRequest.StatusCode -eq 200 ) -and ( $WebRequest.StatusDescription -eq 'OK' ) )
	{
		$Private:Result = $WebRequest | ConvertFrom-Json
		if( $Result.success -eq $True ) { $Result }
		else { Write-Warning "Invoke-LiskApiCall | success => false | error => $($Result.error)" }
	}
	else { Write-Warning "Invoke-LiskApiCall | WebRequest returned Status '$($WebRequest.StatusCode) $($WebRequest.StatusDescription)'." }
}

###########################################################################################################################################

Function SendInfoMail {

	Param(
		[parameter( Mandatory=$True, Position=1 )]
		[System.String] $Message
		)
		
	$Private:Subject = 'LiskMonitor INFO'
	Send-MailMessage -SmtpServer $Script:Config.Email.SenderSmtp -From $Script:Config.Email.SenderEmail -To $Script:Config.Email.InfoEmailList -Subject $Subject -Body $Message
}

###########################################################################################################################################

Function SendWarningMail {

	Param(
		[parameter( Mandatory=$True, Position=1 )]
		[System.String] $Message
		)
		
	$Private:Subject = 'LiskMonitor WARNING'
	Send-MailMessage -SmtpServer $Script:Config.Email.SenderSmtp -From $Script:Config.Email.SenderEmail -To $Script:Config.Email.WarningEmailList -Subject $Subject -Body $Message -Priority High
}

###########################################################################################################################################

Function SendErrorMail {
	Param(
		[parameter( Mandatory=$True, Position=1 )]
		[System.String] $Message
		)
		
	$Private:Subject = 'LiskMonitor ERROR'
	Send-MailMessage -SmtpServer $Script:Config.Email.SenderSmtp -From $Script:Config.Email.SenderEmail -To $Script:Config.Email.ErrorEmailList -Subject $Subject -Body $Message -Priority High
}

###########################################################################################################################################

Function CheckNodeBlockHeight {

	[CmdletBinding()]
	Param(
		[parameter( Mandatory=$True, Position=1 )]
		[ValidateSet("MainNet","TestNet")]
		[System.String] $Net,
		
		[parameter( Mandatory=$True, Position=2 )]
		[System.String] $URI
		)

	$Private:WarningThresholdInSeconds = 120
	$Private:ErrorThresholdInSeconds = 300
	
	$Private:BlockHeight = 0
	$Private:BlockAgeInSeconds = 0
	$Private:Message = ''
	
	$Private:SyncStatus = Get-LiskSyncStatus -URI $URI
	if( $SyncStatus -ne $NULL )
	{
		$BlockHeight = $SyncStatus.Height
		$Private:Block = Get-LiskBlockList -URI $URI -Height $BlockHeight
		if( $Block -ne $NULL )
		{
			if( $Net -eq 'MainNet' ) { $Private:GenesisTimestamp = Get-Date "5/24/2016 5:00 PM" }
			elseif( $Net -eq 'TestNet' ) { $Private:GenesisTimestamp = Get-Date "4/9/2015" }

			$BlockAgeInSeconds = [math]::Round( $( (Get-date)-([timezone]::CurrentTimeZone.ToLocalTime(($GenesisTimestamp).Addseconds($Block.timestamp))) ).TotalSeconds )

			if( $BlockAgeInSeconds -ge $ErrorThresholdInSeconds ) { $Message = "ERROR: Node Block Age is > $ErrorThresholdInSeconds sec. Value: $BlockAgeInSeconds sec." }
			elseif( $BlockAgeInSeconds -ge $WarningThresholdInSeconds ) { $Message = "WARNING: Node Block Age is > $WarningThresholdInSeconds sec. Value: $BlockAgeInSeconds sec." }
			else { $Message = "SUCCESS: Node in SYNC. Block Age is $BlockAgeInSeconds sec." }
		}
		else { $Message = "ERROR: Get-LiskBlockList Result is NULL." }
	}
	else { $Message = "ERROR: Get-LiskSyncStatus Result is NULL." }

	$Message
}

###########################################################################################################################################

Function CheckDelegateLastForgedBlockAge {

[CmdletBinding()]
Param(
	[parameter( Mandatory=$True, Position=1 )]
	[ValidateSet("MainNet","TestNet")]
	[System.String] $Net,
	
	[parameter( Mandatory=$True, Position=2 )]
	[System.String] $URI,
	
	[parameter( Mandatory=$True, Position=3 )]
	[System.Collections.Hashtable] $Account
	)

	$Private:WarningThresholdInMinutes = 30
	$Private:ErrorThresholdInMinutes = 45

	$Private:BlockHeight = 0
	$Private:BlockAgeInMinutes = 0
	$Private:Message = ''

	$Private:LastForgedBlock = Get-LiskBlockList -URI $URI -GeneratorPublicKey $Account.PublicKey -Limit 1 -OrderBy 'height:desc'
	if( $LastForgedBlock -ne $NULL )
	{
		$BlockHeight = $LastForgedBlock.Height
		$BlockAgeInMinutes = [math]::Round( $( (Get-date)-([timezone]::CurrentTimeZone.ToLocalTime(([datetime]'4/9/2015').Addseconds($LastForgedBlock.timestamp))) ).TotalMinutes )
		
		if( $BlockAgeInMinutes -ge $ErrorThresholdInMinutes ) { $Message = "ERROR: $Net Delegate $($Account.Delegate) Last Forged Block Age is > $ErrorThresholdInMinutes minutes. Value: $BlockAgeInMinutes minutes." }
		elseif( $BlockAgeInMinutes -ge $WarningThresholdInMinutes ) { $Message = "WARNING: $Net Delegate $($Account.Delegate) Last Forged Block Age is > $WarningThresholdInMinutes minutes. Value: $BlockAgeInMinutes minutes." }
		else { $Message = "SUCCESS: $Net Delegate $($Account.Delegate) Last Forged Block Age is $BlockAgeInMinutes minutes." }
	}
	else { $Message = "ERROR: Get-LiskBlockList Result is NULL. Verify you are part of the 101 currently Active Delegate." }

	$Message
}

###########################################################################################################################################
# MAIN
###########################################################################################################################################

if( $ShowMainNetPublicKey )
{
	Write-Host "`r`n$Banner`r`n" -ForegroundColor Green
	Write-Host "MainNet Public Key Associated to Address: $($Config.MainNet.Account.Address)"
	Write-Host $( Get-LiskAccountPublicKey -Address $Config.MainNet.Account.Address -URI $Config.MainNet.Nodes[0].URI )
	Write-Host ''
}
elseif( $ShowTestNetPublicKey )
{
	Write-Host "`r`n$Banner`r`n" -ForegroundColor Green
	Write-Host "TestNet Public Key Associated to Address: $($Config.MainNet.Account.Address)"
	Write-Host $( Get-LiskAccountPublicKey -Address $Config.TestNet.Account.Address -URI $Config.TestNet.Nodes[0].URI )
	Write-Host ''
}
elseif( $SendTestEmail )
{
	Write-Host "`r`n$Banner`r`n`r`n" -ForegroundColor Green
	Write-Host 'Sending Test Emails...'
	
	if( $Config.Email.SendInfoMail -eq $True ) { SendInfoMail -Message 'LiskMonitor (SendTestEmail) INFO' }
	else { Write-Host '$Config.Email.SendInfoMail is set to False, Skipping INFO Email Test.' }
	
	if( $Config.Email.SendWarningMail -eq $True ) { SendWarningMail -Message 'LiskMonitor (SendTestEmail) WARNING' }
	else { Write-Host '$Config.Email.SendWarningMail is set to False, Skipping WARNING Email Test.' }
	
	if( $Config.Email.SendErrorMail -eq $True ) { SendErrorMail -Message 'LiskMonitor (SendTestEmail) ERROR' }
	else { Write-Host '$Config.Email.SendErrorMail is set to False, Skipping ERROR Email Test.' }
	
	Write-Host "Done`r`n"
}
else
{
	if( $ShowMessage ) { Write-Host "`r`n$Banner`r`n`r`n" -ForegroundColor Green }
	
	$Private:Header = ''
	$Private:Message = ''
	$Private:InfoMessages = ''
	$Private:WarningMessages = ''
	$Private:ErrorMessages = ''
	
	### MainNet ###================================================================================================
	
	if( $Config.MainNet.MonitoringEnabled -eq $True )
	{
		if( $Config.MainNet.MonitorNodeBlockHeight -eq $True )
		{
			ForEach( $Private:Node in $Config.MainNet.Nodes )
			{
				$Header = "MainNet | Node Block Height | $($Node.Name) |"
				$Message = CheckNodeBlockHeight -Net MainNet -URI $Node.URI
				
				if( $Message -like "SUCCESS:*" ) { $InfoMessages += "$Header $Message`r`n`r`n" }
				elseif( $Message -like "WARNING:*" ) { $WarningMessages += "$Header $Message`r`n`r`n" }
				elseif( $Message -like "ERROR:*" ) { $ErrorMessages += "$Header $Message`r`n`r`n" }
				
				if( $ShowMessage ) { Write-Host "$Header $Message`r`n" }
			}
		}
		
		if( $Config.MainNet.MonitorDelegateForgingStatus -eq $True )
		{
			if( $Config.MainNet.Account.PublicKey -eq '' )
			{
				$Config.MainNet.Account.PublicKey = Get-LiskAccountPublicKey -Address $Config.MainNet.Account.Address -URI $Config.MainNet.Nodes[0].URI
			}

			$Header = "MainNet | Delegate Forging Status |"
			$Private:Message = "ERROR: $Net Delegate $($Config.MainNet.Account.Delegate) is NOT Forging !"

			ForEach( $Private:Node in $Config.MainNet.Nodes )
			{
				if( $( Get-LiskDelegateForgingStatus -URI $Node.URI -PublicKey $Config.MainNet.Account.PublicKey ) -eq $True )
				{
					$Message = "SUCCESS: Delegate $($Config.MainNet.Account.Delegate) is Forging on $($Node.Name)"
				}
			}
			
			if( $Message -like "SUCCESS:*" ) { $InfoMessages += "$Header $Message`r`n`r`n" }
			elseif( $Message -like "WARNING:*" ) { $WarningMessages += "$Header $Message`r`n`r`n" }
			elseif( $Message -like "ERROR:*" ) { $ErrorMessages += "$Header $Message`r`n`r`n" }
			
			if( $ShowMessage ) { Write-Host "$Header $Message`r`n" }
		}
		
		if( $Config.MainNet.MonitorDelegateLastForgedBlockAge -eq $True )
		{
			if( $Config.MainNet.Account.PublicKey -eq '' )
			{
				$Config.MainNet.Account.PublicKey = Get-LiskAccountPublicKey -Address $Config.MainNet.Account.Address -URI $Config.MainNet.Nodes[0].URI
			}

			ForEach( $Private:Node in $Config.MainNet.Nodes )
			{
				$Header = "MainNet | Delegate Last Forged Block Age | $($Node.Name) |"
				$Message = CheckDelegateLastForgedBlockAge -Net MainNet -URI $Node.URI -Account $Config.MainNet.Account
				
				if( $Message -like "SUCCESS:*" ) { $InfoMessages += "$Header $Message`r`n`r`n" }
				elseif( $Message -like "WARNING:*" ) { $WarningMessages += "$Header $Message`r`n`r`n" }
				elseif( $Message -like "ERROR:*" ) { $ErrorMessages += "$Header $Message`r`n`r`n" }
				
				if( $ShowMessage ) { Write-Host "$Header $Message`r`n" }
			}
		}
	}
	else
	{
		if( $ShowMessage ) { Write-Host "MainNet Monitoring Disabled, Skipping Section.`r`n" }
	}
	
	### TestNet ###================================================================================================
	
	if( $Config.TestNet.MonitoringEnabled -eq $True )
	{
		if( $Config.TestNet.MonitorNodeBlockHeight -eq $True )
		{
			ForEach( $Private:Node in $Config.TestNet.Nodes )
			{
				$Header = "TestNet | Node Block Height | $($Node.Name) |"
				$Message = CheckNodeBlockHeight -Net TestNet -URI $Node.URI
				
				if( $Message -like "SUCCESS:*" ) { $InfoMessages += "$Header $Message`r`n`r`n" }
				elseif( $Message -like "WARNING:*" ) { $WarningMessages += "$Header $Message`r`n`r`n" }
				elseif( $Message -like "ERROR:*" ) { $ErrorMessages += "$Header $Message`r`n`r`n" }
				
				if( $ShowMessage ) { Write-Host "$Header $Message`r`n" }
			}
		}
		
		if( $Config.TestNet.MonitorDelegateForgingStatus -eq $True )
		{
			if( $Config.TestNet.Account.PublicKey -eq '' )
			{
				$Config.TestNet.Account.PublicKey = Get-LiskAccountPublicKey -Address $Config.TestNet.Account.Address -URI $Config.TestNet.Nodes[0].URI
			}

			$Header = "TestNet | Delegate Forging Status |"
			$Private:Message = "ERROR: $Net Delegate $($Config.TestNet.Account.Delegate) is NOT Forging !"

			ForEach( $Private:Node in $Config.TestNet.Nodes )
			{
				if( $( Get-LiskDelegateForgingStatus -URI $Node.URI -PublicKey $Config.TestNet.Account.PublicKey ) -eq $True )
				{
					$Message = "SUCCESS: Delegate $($Config.TestNet.Account.Delegate) is Forging on $($Node.Name)"
				}
			}
			
			if( $Message -like "SUCCESS:*" ) { $InfoMessages += "$Header $Message`r`n`r`n" }
			elseif( $Message -like "WARNING:*" ) { $WarningMessages += "$Header $Message`r`n`r`n" }
			elseif( $Message -like "ERROR:*" ) { $ErrorMessages += "$Header $Message`r`n`r`n" }
			
			if( $ShowMessage ) { Write-Host "$Header $Message`r`n" }
		}
		
		if( $Config.TestNet.MonitorDelegateLastForgedBlockAge -eq $True )
		{
			if( $Config.TestNet.Account.PublicKey -eq '' )
			{
				$Config.TestNet.Account.PublicKey = Get-LiskAccountPublicKey -Address $Config.TestNet.Account.Address -URI $Config.TestNet.Nodes[0].URI
			}

			ForEach( $Private:Node in $Config.TestNet.Nodes )
			{
				$Header = "TestNet | Delegate Last Forged Block Age | $($Node.Name) |"
				$Message = CheckDelegateLastForgedBlockAge -Net TestNet -URI $Node.URI -Account $Config.TestNet.Account
				
				if( $Message -like "SUCCESS:*" ) { $InfoMessages += "$Header $Message`r`n`r`n" }
				elseif( $Message -like "WARNING:*" ) { $WarningMessages += "$Header $Message`r`n`r`n" }
				elseif( $Message -like "ERROR:*" ) { $ErrorMessages += "$Header $Message`r`n`r`n" }
				
				if( $ShowMessage ) { Write-Host "$Header $Message`r`n" }
			}
		}
	}
	else
	{
		if( $ShowMessage ) { Write-Host "TestNet Monitoring Disabled, Skipping Section.`r`n" }
	}

	### E-mail Reporting ###=======================================================================================

	if( $Config.Email.SendInfoMail -eq $True )
	{
		if( $InfoMessages -ne '' )
		{
			if( $ShowMessage ) { Write-Host "INFO Message(s) Detected, Sending E-mail.`r`n" }
			SendInfoMail -Message $InfoMessages
		}
		else
		{
			if( $ShowMessage ) { Write-Host "No INFO message(s), Skipping E-mail.`r`n" }
		}
	}
	else
	{
		if( $ShowMessage ) { Write-Host 'SendInfoMail = $False, Skipping Email.`r`n' }
	}
	
	if( $Config.Email.SendWarningMail -eq $True )
	{
		if( $WarningMessages -ne '' )
		{
			if( $ShowMessage ) { Write-Host "WARNING Message(s) Detected, Sending E-mail.`r`n" }
			SendWarningMail -Message $WarningMessages
		}
		else
		{
			if( $ShowMessage ) { Write-Host "No WARNING message(s), Skipping E-mail.`r`n" }
		}
	}
	else
	{
		if( $ShowMessage ) { Write-Host 'SendWarningMail = $False, Skipping E-mail.`r`n' }
	}
	
	if( $Config.Email.SendErrorMail -eq $True )
	{
		if( $ErrorMessages -ne '' )
		{
			if( $ShowMessage ) { Write-Host "ERROR Message(s) Detected, Sending E-mail.`r`n" }
			SendErrorMail -Message $ErrorMessages
		}
		else
		{
			if( $ShowMessage ) { Write-Host "No ERROR message(s), Skipping E-mail.`r`n" }
		}
	}
	else
	{
		if( $ShowMessage ) { Write-Host 'SendErrorMail = $False, Skipping Email.`r`n' }
	}
}

############################################################################################################################################################################
### Free Memory
############################################################################################################################################################################

Remove-Variable -Name Banner -ErrorAction SilentlyContinue
Remove-Variable -Name Config -ErrorAction SilentlyContinue
Remove-Variable -Name SendTestEmail -ErrorAction SilentlyContinue
Remove-Variable -Name ShowMainNetPublicKey -ErrorAction SilentlyContinue
Remove-Variable -Name ShowMessage -ErrorAction SilentlyContinue
Remove-Variable -Name ShowTestNetPublicKey -ErrorAction SilentlyContinue
Remove-Variable -Name ErrorMessages -ErrorAction SilentlyContinue
Remove-Variable -Name foreach -ErrorAction SilentlyContinue
Remove-Variable -Name Header -ErrorAction SilentlyContinue
Remove-Variable -Name InfoMessages -ErrorAction SilentlyContinue
Remove-Variable -Name Message -ErrorAction SilentlyContinue
Remove-Variable -Name Node -ErrorAction SilentlyContinue
Remove-Variable -Name WarningMessages -ErrorAction SilentlyContinue

$Private:CurrentSessionVariable_List = Get-Variable | Select-Object -ExpandProperty Name

$Private:PowerShellDefaultVariables = @('$','?','^','args','ConfirmPreference','ConsoleFileName','DebugPreference','Error','ErrorActionPreference','ErrorView','ExecutionContext','false','FormatEnumerationLimit','HOME','Host','input',
'MaximumAliasCount','MaximumDriveCount','MaximumErrorCount','MaximumFunctionCount','MaximumHistoryCount','MaximumVariableCount','MyInvocation','NestedPromptLevel','null','OutputEncoding','PID','PROFILE','ProgressPreference',
'PSBoundParameters','PSCmdlet','PSCommandPath','PSCulture','PSDefaultParameterValues','PSEmailServer','PSHOME','PSScriptRoot','PSSessionApplicationName','PSSessionConfigurationName','PSSessionOption','PSUICulture','PSVersionTable',
'PWD','ShellId','StackTrace','true','VerbosePreference','WarningPreference','WhatIfPreference')

$Private:FreeMemoryVariableFound = $False

ForEach( $Private:CurrentSessionVariable in $CurrentSessionVariable_List )
{
	if( $CurrentSessionVariable -notin $PowerShellDefaultVariables )
	{
		$FreeMemoryVariableFound = $True
		#Write-Host "Remove-Variable -Name $CurrentSessionVariable -ErrorAction SilentlyContinue"
	}
}

if( $FreeMemoryVariableFound -eq $True )
{
	#Write-Host "Free Memory | Variable(s) Found. If it was created by script execution, edit 'Free Memory' section."
}

Remove-Variable -Name FreeMemoryVariableFound -ErrorAction SilentlyContinue
Remove-Variable -Name PowerShellDefaultVariables -ErrorAction SilentlyContinue
Remove-Variable -Name CurrentSessionVariable_List -ErrorAction SilentlyContinue
Remove-Variable -Name CurrentSessionVariable -ErrorAction SilentlyContinue

[System.GC]::Collect()
