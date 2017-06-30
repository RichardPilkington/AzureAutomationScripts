<# 
	This PowerShell script was automatically converted to PowerShell Workflow so it can be run as a runbook.
	Specific changes that have been made are marked with a comment starting with “Converter:”
#>
  <# 
    .SYNOPSIS  
    The purpose of this runbook is to make a copy of a database and overwrite another database with this new copy. It runs a stored proc before making the copy 
 
    .DESCRIPTION 
    This runbook is designed to make a copy of a database, run a stored proc on the new version and then replace the database with the copy
    
    .PARAMETER SourceServerName
    This is the name of the server where the source database is located
    
    .PARAMETER SourceDatabaseName
    This is the name of the source database

    .PARAMETER DestDatabaseName
    This is the name of the database to be be replaced

    .PARAMETER DestServerName
    This is the name of the server the database being restored to

    .PARAMETER DestDatabaseTempName
    This is the temp  name of the database being restored to

    .PARAMETER ResourceGroupName
    This is the name of the resource group which contains the source database
     
    .PARAMETER DestResourceGroupName
    This is the name of the resource group which contains the destination database
      
    .PARAMETER SQlCredential
    The  Sql server credentials stored in assests to the destination server
       
    .PARAMETER PoolName
    The name of the elastic pool in which the destination database will be restored too
    
    .PARAMETER UserToCreateOnDestination
    The name of theuser to create on destination database

    .PARAMETER LoginUserToCreateUserFrom
    The name of the login to user to create from on destination database
    
  


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
        [String]$DestDatabaseTempName,
        [Parameter(Mandatory=$True)]  
      	[ValidateNotNullOrEmpty()] 
        [String]$ResourceGroupName,
        [Parameter(Mandatory=$True)]  
      	[ValidateNotNullOrEmpty()] 
        [String]$DestResourceGroupName,
        [Parameter(Mandatory=$True)]  
      	[ValidateNotNullOrEmpty()] 
        [String]$SQlCredential,
        [Parameter(Mandatory=$True)]  
      	[ValidateNotNullOrEmpty()] 
        [String]$PoolName,
        [Parameter(Mandatory=$True)]  
      	[ValidateNotNullOrEmpty()] 
        [String]$UserToCreateOnDestination,
        [Parameter(Mandatory=$True)]  
      	[ValidateNotNullOrEmpty()] 
        [String]$LoginUserToCreateUserFrom
      	
	)
       $myCredential = Get-AutomationPSCredential -Name $SQlCredential
       $Username = $myCredential.UserName
       $securePassword = $myCredential.Password
       $Password = $myCredential.GetNetworkCredential().Password
      		
    	#Configure PowerShell credentials and connection context
   		
		$connectionName = "AzureRunAsConnection"
		try
		{
    		# Get the connection "AzureRunAsConnection "
    		$servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         
		
    		"Logging in to Azure..."
    		Add-AzureRmAccount `
                                -ServicePrincipal `
                                -TenantId $servicePrincipalConnection.TenantId `
                                -ApplicationId $servicePrincipalConnection.ApplicationId `
                                -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
		}
		catch 
        {
    		if (!$servicePrincipalConnection)
    		{
        		$ErrorMessage = "Connection $connectionName not found."
        		throw $ErrorMessage
    		} else{
        		Write-Error -Message $_.Exception
        		throw $_.Exception
    		}
		}
    		#Set the point in time to restore too and the target database
    		
 		
    		 $sourceDB =Get-AzureRmSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $SourceServerName -DatabaseName $SourceDatabaseName
    $destDB=Get-AzureRmSqlElasticPool -ResourceGroupName $DestResourceGroupName -ServerName $DestServerName -ElasticPoolName $PoolName
    
      If ($sourceDB.Edition -Match $destDB.Edition ) {
         Write-Output "Creating new copy of Database into pool"  
         New-AzureRmSqlDatabaseCopy -CopyDatabaseName $DestDatabaseTempName	-DatabaseName $SourceDatabaseName -CopyResourceGroupName $DestResourceGroupName  -CopyServerName $DestServerName 	-ResourceGroupName $ResourceGroupName	-ServerName $SourceServerName -ElasticPoolName $PoolName
	   }
      Else { 
         Write-Output "Creating new copy of Database"  
         New-AzureRmSqlDatabaseCopy -CopyDatabaseName $DestDatabaseTempName	-DatabaseName $SourceDatabaseName -CopyResourceGroupName $DestResourceGroupName  -CopyServerName $DestServerName 	-ResourceGroupName $ResourceGroupName	-ServerName $SourceServerName 
		 
         Write-Output "Putting database into the pool"  
   		 Set-AzureRmSqlDatabase -ResourceGroupName $DestResourceGroupName -ServerName $DestServerName -DatabaseName $DestDatabaseTempName -ElasticPoolName $PoolName
         Start-Sleep -Seconds 120
         }
    	
         Write-Output "Finished creating new copy of database"
    
      	Write-Output "Deleting old  database"
       	Remove-AzureRmSqlDatabase -DatabaseName $DestDatabaseName -ResourceGroupName $DestResourceGroupName -ServerName $DestServerName -Force
   		Start-Sleep -Seconds 120
    	
    
    	Write-Output "Creating users and renaming"
      

        $connectionString = "Server=tcp:"+$DestServerName+".database.windows.net,1433;Initial Catalog="+$DestDatabaseTempName+";Persist Security Info=False;User ID="+$username+";Password="+$password+";MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=3000;"
    	$connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    	$sqlCommand="CREATE USER "+$UserToCreateOnDestination+" FROM LOGIN "+$LoginUserToCreateUserFrom+";"
    	$command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)

      	$connection.Open()

     	$command.ExecuteNonQuery();
        $command.CommandText="EXEC sys.sp_addrolemember 'db_datareader','"+$UserToCreateOnDestination+"'"
        $command.ExecuteNonQuery();
        $command.CommandText="EXEC sys.sp_addrolemember 'db_datawriter','"+$UserToCreateOnDestination+"'"
        $command.ExecuteNonQuery();
  $command.CommandText="EXEC sys.sp_addrolemember 'db_ddladmin','"+$UserToCreateOnDestination+"'"
        $command.ExecuteNonQuery();
   
         $command.CommandText="EXEC sys.sp_addrolemember 'db_executor','"+$UserToCreateOnDestination+"'"
        $command.ExecuteNonQuery();

    
    	$connection.Close()

        $connectionString = "Server=tcp:"+$DestServerName+".database.windows.net,1433;Initial Catalog=master;Persist Security Info=False;User ID="+$username+";Password="+$password+";MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=3000;"
    	$connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    	$sqlCommand="ALTER DATABASE ["+$DestDatabaseTempName+"] MODIFY  NAME = ["+$DestDatabaseName+"]"
    	$command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
        $connection.Open()
        
        $command.ExecuteNonQuery();
     
        $connection.Close()

  		Write-Output "Complete" 		
		
	
