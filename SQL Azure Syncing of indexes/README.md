# Syncing of indexes

Please refer to my blog article for a description of the project
https://www.richardpilkington.co.za/2017/06/30/syncing-indexes-across-sql-azure-databases-2/

To install
1. Create a new Azure Automation runbook and copy and paste the contents of 1.AzureAutomationScript.ps1 into the editor
2. Run 2.GetCreateIndexScript.sql script on your master database
3. Run 3.BuildNewIndexes.sql script on your subscriber/slave
4. Set up your jobs within Azure Automation