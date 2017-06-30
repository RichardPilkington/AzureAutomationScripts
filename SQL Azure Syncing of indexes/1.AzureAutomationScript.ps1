
  <# 
.SYNOPSIS  
    The purpose of this runbook is to sync database indexes from one database to another
 
.DESCRIPTION 
    WARNING: This runbook deletes all indexes in the destination database and replaces them with the sources

    
    .PARAMETER SourceServerName
    This is the name of the server where the source database is located
    .PARAMETER SourceServerCredentials
    This is the name of the server credentials where the destination database is located
    .PARAMETER SourceDatabaseName
    This is the name of the database being used as a source of the indexes from
    .PARAMETER DestServer
    This is the name of the server where the destination database is located
    .PARAMETER DestServerCredentials
    This is the name of the server credentials where the destination database is located
    .PARAMETER DestDatabaseName
    This is the  name of the database to which indexes are being applied to 
 

#> 

   
	param([Parameter(Mandatory=$True)] 
      	[ValidateNotNullOrEmpty()] 
      	[String]$SourceServerName,
      	[Parameter(Mandatory=$True)]  
      	[ValidateNotNullOrEmpty()] 
      	[String]$SourceDatabaseName,
      	[Parameter(Mandatory=$True)]  
      	[ValidateNotNullOrEmpty()] 
        [String]$DestDatabaseName,
        [Parameter(Mandatory=$True)] 
      	[ValidateNotNullOrEmpty()] 
      	[String]$DestServerName, 
        [Parameter(Mandatory=$True)] 
        [ValidateNotNullOrEmpty()] 
      	[String]$DestServerCredentials, 
        [Parameter(Mandatory=$True)] 
        [ValidateNotNullOrEmpty()] 
      	[String]$SourceServerCredentials
         
      	
	) 
	   		Write-Output "Getting new index script from source database"  

		    $myCredential = Get-AutomationPSCredential -Name $SourceServerCredentials
            $Username = $myCredential.UserName
            $Password = $myCredential.GetNetworkCredential().Password
 
    		$connectionString = "Server=tcp:"+$SourceServerName+".database.windows.net,1433;Initial Catalog="+$SourceDatabaseName+
    ";Persist Security Info=False;User ID="+$Username+";Password="+$Password+";MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=300;"
    		
		
     		$connection = new-object system.data.SqlClient.SQLConnection($connectionString)
     	    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
            $SqlCmd.CommandText = "dbo.[upGetCreateIndexScript]"
            $SqlCmd.Connection = $connection
           
            $connection.Open()
            $script= $SqlCmd.ExecuteScalar()
            $connection.Close()
          

		    Write-Output "Received new index script from source database"  

			Write-Output "Applying new index script to destination database"  
            $myCredential = Get-AutomationPSCredential -Name $DestServerCredentials
            $Username = $myCredential.UserName
            $Password = $myCredential.GetNetworkCredential().Password

    		$connectionString = "Server=tcp:"+$DestServerName+".database.windows.net,1433;Initial Catalog="+$DestDatabaseName+
    ";Persist Security Info=False;User ID="+$Username+";Password="+$Password+";MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=300;"
    		
		
     		$connection = new-object system.data.SqlClient.SQLConnection($connectionString)
     	    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
            $SqlCmd.CommandText = "EXEC [dbo].[upBuildNewIndex] @CreateScript"
            $SqlCmd.Parameters.AddWithValue("@CreateScript", $script)
            $SqlCmd.Connection = $connection
          $SqlCmd.CommandTimeout=9999
            $connection.Open()
            $SqlCmd.ExecuteNonQuery()
            $connection.Close()
            

            Write-Output "Finished applying new index script to destination database"  