 ![##Images_README_Header##](./Images/README_Header.png)

LiskMonitor is a stand-alone PowerShell script made 100% by me to do end-user monitoring on Lisk MainNet and TestNet nodes and delegates. It uses PowerShell so it run only on Windows but can monitor a node on any type of installation since it uses HTTP protocol to communicate with API. For hardcore Linux users or just people wanting more protection by running more than 1 instance of the script, don’t forget, am inexspansive Windows Server Box can do the job pretty well.

This is v1.0.x.x of the script. Included features are:

 - Monitoring Block Height of every provided nodes URLs.
 - Monitoring Last Forged Block Height of configured delegate on all provided nodes URLs.
 - Monitoring Delegate Forging Status on all provided URLs.

If I see enough interest, next version will/could include:

 - Auto-switching of active forging node on detection of a problem on currently active forging node.
 - Daily/Hourly Auto-transfer of forged Lisk in secondary account.
 - Multi-Accounts Daily Balance Reporting
 - Monitoring Port Accessibility and Latency Problem of all provided URLs.
 - And more ...


###**1 Installation**
--------------

Download latest version here: [LiskMonitor-master.zip](https://github.com/Gr33nDrag0n69/LiskMonitor/archive/master.zip)

Extract the zip archive and copy the LiskMonitor.ps1 file to it's final destination.

I recommend saving it near root directory. For example: C:\SCRIPTS\LiskMonitor.ps1

###***2 Configuration**
---------------

Open the script in your favorite text editor.

I recommend notepad++ available for free [HERE](https://notepad-plus-plus.org/).

Go to the section named (around line #:
Configurable Variables | MANDATORY !!! EDIT THIS SECTION !!!

In the "### Test | Activate / Deactivate" Sub-section

In the "MainNet | Account" Sub-section

Note:
Public Key can be left empty, it will be retreived automaticaly.
Example: $Config.MainNet.Account.PublicKey = ''
Configuring PublicKey remove 1 api call everytime the script runs...


In the "" Sub-section

In the "" Sub-section

Save and close the file.

3 Manual Usage & Testing
------------------------

Text text text text text

4 Scheduled Task(s) Creation & Testing
--------------------------------------

Text text text text text

5 Troubleshooting & Common Error(s)
------------------------------------------------------------------------
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

