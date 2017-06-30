# Restoring of SQL Azure databases and overwritting existing database

Please refer to my blog article for a detailed description of the project
https://www.richardpilkington.co.za/2017/05/16/automating-the-restores-of-a-sql-azure-database/

##Brief description
There are two PowerShell Scripts here both are Azure automation run books designed to restore a SQL Azure database into a pool and replace the existing one with the same name and create the relevant users.
One runs a stored procedure after the restore. This can be used for anonymisation.
