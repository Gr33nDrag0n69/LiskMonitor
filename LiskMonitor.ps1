<#
.SYNOPSIS
	Monitoring Tool for Lisk Nodes and Delegates.
	
.DESCRIPTION
	
.PARAMETER ShowMessage
	Output message to screen. (Doesn't affect e-mail functionnality)

.PARAMETER SendTestEmail
	Send a test e-mail to the configured e-mails ERROR.

.PARAMETER ShowPublicKey
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
	Version :	1.1.0.0
	Author  :	Gr33nDrag0n
	History :	2016/11/20 - Last Modification
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
	[switch] $ShowPublicKey
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
$Config.Account = @{}
$Config.Nodes = @()
$Private:Banner = "LiskMonitor v1.1 by Gr33nDrag0n"

#######################################################################################################################
# Configurable Variables | MANDATORY !!! EDIT THIS SECTION !!!
#######################################################################################################################

### Monitoring ###============================================================================

$Config.MonitoringEnabled = $True
$Config.MonitorNodeBlockHeight = $True
# Warning: You Delegate must have Forging Enabled on 1 of your node to enable this feature.
$Config.MonitorDelegateForgingStatus = $True
# Warning: You must be and "Active Delegate" to enable this feature.
$Config.MonitorDelegateLastForgedBlockAge = $True

### E-Mail ###===============================================================================

$Config.Email.SenderEmail      = 'liskmonitor@mydomain.com'
# Same SMTP address you would use in your e-mail client
$Config.Email.SenderSmtp       = 'smtp.myISP.com'

$Config.Email.SendErrorMail    = $True
$Config.Email.ErrorEmailList   = @('myemail@domain.com','5556781212@myphoneprovider.com')

### Account ###===========================================================================================

$Config.Account.Delegate  = ''
$Config.Account.PublicKey = ''
$Config.Account.Address   = ''

# Account Example

#$Config.Account.Delegate  = 'gr33ndrag0n'
#$Config.Account.PublicKey = 'ad936990fb57f7e686763c293e9ca773d1d921888f5235189945a10029cd95b0'
#$Config.Account.Address   = '194109334904015388L'

### Node(s) ###=======================================================================================

$Config.Nodes += @{Name='';URI=''}

# Node(s) Example

#$Config.Nodes += @{Name='explorer.lisknode.io';URI='http://explorer.lisknode.io:8000/'}
#$Config.Nodes += @{Name='snapshot.lisknode.io';URI='http://snapshot.lisknode.io:8000/'}


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

Function SendErrorMail {
	Param(
		[parameter( Mandatory=$True, Position=1 )]
		[System.String] $Message
		)
		
	$Private:Subject = 'LiskMonitor'
	Send-MailMessage -SmtpServer $Script:Config.Email.SenderSmtp -From $Script:Config.Email.SenderEmail -To $Script:Config.Email.ErrorEmailList -Subject $Subject -Body $Message -Priority High
}

###########################################################################################################################################

Function CheckNodeBlockHeight {

	[CmdletBinding()]
	Param(
		[parameter( Mandatory=$True, Position=1 )]
		[System.String] $URI
		)

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
			$Private:GenesisTimestamp = Get-Date "5/24/2016 5:00 PM"
			$BlockAgeInSeconds = [math]::Round( $( (Get-date)-([timezone]::CurrentTimeZone.ToLocalTime($GenesisTimestamp.Addseconds($Block.timestamp))) ).TotalSeconds )

			if( $BlockAgeInSeconds -ge $ErrorThresholdInSeconds ) { $Message = "ERROR: Node Block Age is > $ErrorThresholdInSeconds sec. Value: $BlockAgeInSeconds sec." }
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
	[System.String] $URI,
	
	[parameter( Mandatory=$True, Position=2 )]
	[System.Collections.Hashtable] $Account
	)

	$Private:ErrorThresholdInMinutes = 90

	$Private:BlockHeight = 0
	$Private:BlockAgeInMinutes = 0
	$Private:Message = ''

	$Private:LastForgedBlock = Get-LiskBlockList -URI $URI -GeneratorPublicKey $Account.PublicKey -Limit 1 -OrderBy 'height:desc'
	if( $LastForgedBlock -ne $NULL )
	{
		$BlockHeight = $LastForgedBlock.Height
		$Private:GenesisTimestamp = Get-Date "5/24/2016 5:00 PM"
		$BlockAgeInMinutes = [math]::Round( $( (Get-date)-([timezone]::CurrentTimeZone.ToLocalTime($GenesisTimestamp.Addseconds($LastForgedBlock.timestamp))) ).TotalMinutes )
		
		if( $BlockAgeInMinutes -ge $ErrorThresholdInMinutes ) { $Message = "ERROR: $Net Delegate $($Account.Delegate) Last Forged Block Age is > $ErrorThresholdInMinutes minutes. Value: $BlockAgeInMinutes minutes." }
		else { $Message = "SUCCESS: $Net Delegate $($Account.Delegate) Last Forged Block Age is $BlockAgeInMinutes minutes." }
	}
	else { $Message = "ERROR: Get-LiskBlockList Result is NULL. Verify you are part of the 101 currently Active Delegate." }

	$Message
}

###########################################################################################################################################
# MAIN
###########################################################################################################################################

if( $ShowPublicKey )
{
	Write-Host "`r`n$Banner`r`n" -ForegroundColor Green
	Write-Host ''
	Write-Host "Delegate:  $($Config.Account.Delegate)"
	Write-Host "Address:   $($Config.Account.Address)"
	Write-Host ''
	Write-Host "Public Key:"
	Write-Host ''
	Write-Host $( Get-LiskAccountPublicKey -Address $Config.Account.Address -URI $Config.Nodes[0].URI )
	Write-Host ''
}
elseif( $SendTestEmail )
{
	Write-Host "`r`n$Banner`r`n`r`n" -ForegroundColor Green
	Write-Host 'Sending Test Email(s)...'
	
	if( $Config.Email.SendErrorMail -eq $True ) { SendErrorMail -Message 'LiskMonitor (SendTestEmail)' }
	else { Write-Host '$Config.Email.SendErrorMail is set to False, Skipping ERROR Email Test.' }
	
	Write-Host "Done`r`n"
}
else
{
	if( $ShowMessage ) { Write-Host "`r`n$Banner`r`n`r`n" -ForegroundColor Green }
	
	$Private:Header = ''
	$Private:Message = ''
	$Private:ErrorMessages = ''
	
	if( $Config.MonitoringEnabled -eq $True )
	{
		if( $Config.MonitorNodeBlockHeight -eq $True )
		{
			ForEach( $Private:Node in $Config.Nodes )
			{
				$Header = "Node Block Height | $($Node.Name) |"
				$Message = CheckNodeBlockHeight -URI $Node.URI
				
				if( $Message -like "ERROR:*" ) { $ErrorMessages += "$Header $Message`r`n`r`n" }
				
				if( $ShowMessage ) { Write-Host "$Header $Message`r`n" }
			}
		}
		
		if( $Config.MonitorDelegateForgingStatus -eq $True )
		{
			if( $Config.Account.PublicKey -eq '' )
			{
				$Config.Account.PublicKey = Get-LiskAccountPublicKey -Address $Config.Account.Address -URI $Config.Nodes[0].URI
			}

			$Header = "Delegate Forging Status |"
			$Private:Message = "ERROR: $Net Delegate $($Config.Account.Delegate) is NOT Forging !"

			ForEach( $Private:Node in $Config.Nodes )
			{
				if( $( Get-LiskDelegateForgingStatus -URI $Node.URI -PublicKey $Config.Account.PublicKey ) -eq $True )
				{
					$Message = "SUCCESS: Delegate $($Config.Account.Delegate) is Forging on $($Node.Name)"
				}
			}
			
			if( $Message -like "ERROR:*" ) { $ErrorMessages += "$Header $Message`r`n`r`n" }
			
			if( $ShowMessage ) { Write-Host "$Header $Message`r`n" }
		}
		
		if( $Config.MonitorDelegateLastForgedBlockAge -eq $True )
		{
			if( $Config.Account.PublicKey -eq '' )
			{
				$Config.Account.PublicKey = Get-LiskAccountPublicKey -Address $Config.Account.Address -URI $Config.Nodes[0].URI
			}

			ForEach( $Private:Node in $Config.Nodes )
			{
				$Header = "Delegate Last Forged Block Age | $($Node.Name) |"
				$Message = CheckDelegateLastForgedBlockAge -URI $Node.URI -Account $Config.Account
				
				if( $Message -like "ERROR:*" ) { $ErrorMessages += "$Header $Message`r`n`r`n" }
				
				if( $ShowMessage ) { Write-Host "$Header $Message`r`n" }
			}
		}
	}
	else
	{
		if( $ShowMessage ) { Write-Host "Monitoring Disabled, Skipping Section.`r`n" }
	}
	
	### E-mail Reporting ###=======================================================================================

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
Remove-Variable -Name ErrorMessages -ErrorAction SilentlyContinue
Remove-Variable -Name foreach -ErrorAction SilentlyContinue
Remove-Variable -Name Header -ErrorAction SilentlyContinue
Remove-Variable -Name Message -ErrorAction SilentlyContinue
Remove-Variable -Name Node -ErrorAction SilentlyContinue
Remove-Variable -Name SendTestEmail -ErrorAction SilentlyContinue
Remove-Variable -Name ShowMessage -ErrorAction SilentlyContinue
Remove-Variable -Name ShowPublicKey -ErrorAction SilentlyContinue

$Private:CurrentSessionVariable_List = Get-Variable | Select-Object -ExpandProperty Name

$Private:PowerShellDefaultVariables = @('$','?','^','args','ConfirmPreference','ConsoleFileName','DebugPreference','Error','ErrorActionPreference','ErrorView','ExecutionContext','false','FormatEnumerationLimit','HOME','Host','input',
'MaximumAliasCount','MaximumDriveCount','MaximumErrorCount','MaximumFunctionCount','MaximumHistoryCount','MaximumVariableCount','MyInvocation','NestedPromptLevel','null','OutputEncoding','PID','PROFILE','ProgressPreference',
'PSBoundParameters','PSCmdlet','PSCommandPath','PSCulture','PSDefaultParameterValues','PSEmailServer','PSHOME','PSScriptRoot','PSSessionApplicationName','PSSessionConfigurationName','PSSessionOption','PSUICulture','PSVersionTable',
'PWD','ShellId','StackTrace','true','VerbosePreference','WarningPreference','WhatIfPreference','InformationPreference','PSEdition')

$Private:FreeMemoryVariableFound = $False

ForEach( $Private:CurrentSessionVariable in $CurrentSessionVariable_List )
{
	if( $CurrentSessionVariable -notin $PowerShellDefaultVariables )
	{
		$FreeMemoryVariableFound = $True
		Write-Host "Remove-Variable -Name $CurrentSessionVariable -ErrorAction SilentlyContinue"
	}
}

if( $FreeMemoryVariableFound -eq $True )
{
	Write-Host "Free Memory | Variable(s) Found. If it was created by script execution, edit 'Free Memory' section."
}

Remove-Variable -Name FreeMemoryVariableFound -ErrorAction SilentlyContinue
Remove-Variable -Name PowerShellDefaultVariables -ErrorAction SilentlyContinue
Remove-Variable -Name CurrentSessionVariable_List -ErrorAction SilentlyContinue
Remove-Variable -Name CurrentSessionVariable -ErrorAction SilentlyContinue

[System.GC]::Collect()
