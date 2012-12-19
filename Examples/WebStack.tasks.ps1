. ..\octo-tasks.ps1

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
