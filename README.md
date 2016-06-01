 ![##Images_README_Header##](./PNG/Header.png)

LiskMonitor is a stand-alone PowerShell script to do end-user monitoring on Lisk MainNet and TestNet nodes and delegates. It uses PowerShell so it run only on Windows but can monitor a node on any type of installation since it uses HTTP protocol to communicate with API.

This is v1.0.0.x of the script. Included features are:

 - Monitoring Block Height of every provided nodes URLs.
 - Monitoring Last Forged Block Height of configured delegate on all provided nodes URLs.
 - Monitoring Delegate Forging Status on all provided URLs.

If I see enough interest, next version will/could include:

 - Full encryption of your configuration parameters in an external config file.
 - Auto-switching of active forging node on detection of a problem on currently active forging node.
 - Daily/Hourly Auto-transfer of forged Lisk in secondary account.
 - Multi-Accounts Daily Balance Reporting
 - Monitoring Port Accessibility and Latency Problem of all provided URLs.
 - And more ...


###**Installation**

Download latest version here: [LiskMonitor-master.zip](https://github.com/Gr33nDrag0n69/LiskMonitor/archive/master.zip)

Extract the zip archive and copy the LiskMonitor.ps1 file to it's final destination.

I recommend saving it near root directory. For example: C:\SCRIPTS\LiskMonitor.ps1

###**Configuration, Manual Usage & Testing**

Open the script in your favorite text editor. Basic Notepad WILL work but not recommended. I recommend notepad++ available for free [HERE](https://notepad-plus-plus.org/).

Scroll to line #81

> Configurable Variables | MANDATORY !!! EDIT THIS SECTION !!!


The configuration is splitted in 3 sub-sections:

 - E-mail
 - MainNet
 - TestNet

#### **E-mail**

In this section we will configure the address used to send and received the monitoring automatic e-mails.

Config. | Description | Value Example
------------ | -------------
SenderEmail | This is the e-mail that will be used as sender by the script. | liskmonitor@mydomain.com
SenderSmtp | This is the domain or IP address the script will use as SMTP to send messages. | smtp.myinternetprovider.com
SendErrorMail | Enable/Disable the sending of errors messages. | \$True or \$False
ErrorEmailList | | @('home@mydomain.com','1234567890@phoneprovider.com')
SendWarningMail | Enable/Disable the sending of warnings messages. | \$True or \$False
WarningEmailList | | @('home@mydomain.com')
SendInfoMail| Enable/Disable the sending of infos messages. | \$True or \$False 
InfoEmailList | | @('home@mydomain.com')
 
####_About EmailList_

1 entry example:
> @('email@domain.com')

Multi-entries example:
> @('email@domain.com','5556781212@myphoneprovider.com')

You can use the same address for sender and recipient if you want.

But you can customize the behavior. Example:

 - I put my home e-mail for the info
 - I put my home and work e-mail for warning
 - I put my home and work e-mail + email2sms for error

####_About InfoEmail_
Once everything will work, you can safely disable it.

####_About "email2sms"_
Most phone provider have email2sms functionnality. Just check with your provider, you probably already have an addres looking like:
> 9995551212@YourPhoneProvider.com

It allow text e-mail sent to this address to be redirected as sms to your phone.
 
####**MainNet**

Note:
Public Key can be left empty, it will be retreived automaticaly.
Example: $Config.MainNet.Account.PublicKey = ''
Configuring PublicKey remove 1 api call everytime the script runs...

####**TestNet**

TestNet section work the same way, it' made to use same script to monitor both network. For now, lets wait for next TestNet occurence and let it disabled.

Now, Save and close the file.

###**Scheduled Task(s) Creation & Testing**


###**Troubleshooting & Common Error(s)**

**It doesn’t work.**

Verify PowerShell version installed in your computer. Execute the following command:

> $PSVersionTable

The PSVersion must be at least v4.x.
If not, go [HERE](https://www.microsoft.com/en-us/download/details.aspx?id=40855), select your language, download, install and reboot.

When done re-run the test to confirm your version is now v4.x or upper.

**Script work but communication with server fail.**

Verify the configuration of the server (config,json) to allow your IP address in the whitelist section. Don’t forget to restart your lisk client to update the configuration.

**Script is asking confirmation to execute when running it.**

Verify PowerShell execution policy for your user profile. To do that, use:

> Get-ExecutionPolicy 

If execution policy is set to ??? change default value to ? qith the following command:

> Set-ExecutionPolicy

**You want to use PublicKey for the delegate configuration but you only know your address?**

> .\LiskMonitor.ps1 -ShowPublicKey ##ADDRESS##

**Using "Delegate Last Forged Block Age" You Receive "ERROR: Get-LiskBlockList Result is NULL."**

Are you currently an active delegate ? You must be in the 101 active delegate to forge block.



This ReadMe File was edited using: https://stackedit.io/editor
Thanxs to Slasheks for his help suggesting this tool.


