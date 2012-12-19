Octo-Tasks
==========

PowerShell DSL for defining discrete tasks and their dependencies.  It's like an illegitimate love-child of psake and Babushka.


Example
=======

A simple example is the following script to setup IIS and SQL Server on a Bamboo-on-Demand Windows EC2 instance.

```powershell
. .\octo-tasks.ps1

$SQLServerDownloadURL = "http://download.microsoft.com/download/8/D/D/8DD7BDBA-CEF7-4D8E-8C16-D9F69527F909/ENU/x64/SQLEXPRWT_x64_ENU.exe"
$SQLServerLocalInstaller = "C:\Users\Administrator\Downloads\SQLEXPRWT_x64_ENU.exe"

tasks "Windows Web Stack" {

    doc "Configures IIS and install SQL Server by default"
	task default -depends ConfigureIIS, InstallSQLServer

	task ConfigureIIS {
		met? { (Get-Service | ForEach-Object { $_.name }) -contains 'W3SVC' }
		meet {
			Start-Process pkgmgr /iu:"IIS-WebServerRole;IIS-WebServer"
		}
	}

 	task DownloadSQLServer {
    	met? { Test-Path $SQLServerLocalInstaller }
    	meet {
      		$WebClient = New-Object System.Net.WebClient
      		$WebClient.DownloadFile($SQLServerDownloadURL, $SQLServerLocalInstaller)
    	}
  	}

	task InstallSQLServer -depends DownloadSQLServer {
		met? { (Get-Service | ForEach-Object { $_.name }) -contains 'MSSQLSERVER' }
		meet {
            param (
                [Parameter(Mandatory=$True)][string]$SQLServerAccountName,
                [Parameter(Mandatory=$True)][string]$SQLServerAccountPassword
            )
			$Options = "/QS " +
					"/ACTION=Install " +
					"/FEATURES=SQL " +
					"/INSTANCENAME=MSSQLSERVER " +
					"/SQLSVCACCOUNT='$SQLServerAccountName' " +
					"/SQLSVCPASSWORD='$SQLServerAccountPassword' " +
					"/AGTSVCACCOUNT='NT AUTHORITY\Network Service' " +
					"/IACCEPTSQLSERVERLICENSETERMS " +
					"/INDICATEPROGRESS"
	        Invoke-Expression "$SQLServerLocalInstaller $Options"
      		do {
        		sleep 10
        		"...waiting for SQL Server install..."
      		} while ((Get-Service | ForEach-Object { $_.name }) -notcontains 'MSSQLSERVER')
		}
	}

}
```


Features
========
- You can specify a task, a list of tasks, or "help" from the command line.  Specifying "help" shows a list of available tasks.
- If you don't specify a parameter it looks for a "default" task.
- Tasks can be documented using "doc".  Tasks with docs are assumed public and are shown first when you list tasks using "help".
- Giving your blocks mandatory params causes the script to prompt for values at run-time
- The "met?" block is evaluated to see if the "meet" block needs executing.  It is also run after the "meet" block to make sure everything is doing what you expect.
- You can leave out the "met?" block.  This assumes the task always needs to be run.
- If you leave out the "met?" block, you can also leave out the "meet" section.  The whole level up is assumed to be the "meet" block.
- There are no dependencies for recent Windows OS' (you only need PowerShell)
