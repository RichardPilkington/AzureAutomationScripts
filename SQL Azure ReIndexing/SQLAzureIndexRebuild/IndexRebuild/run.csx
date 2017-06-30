#r"System.Configuration"
using System;
using System.Runtime.Remoting.Messaging;
using System.Collections.Generic;


public static void Run(TimerInfo RebuildNight, TraceWriter log)
{
    try
    {
        RebuildIndex(log);
    }
    catch (Exception ex)
    {
        RebuildIndex(log);
    }

}
private static void RebuildIndex(TraceWriter log)
{
    List<string> databases;

    using (var connection = GetMasterDatabaseConnectionString())
    {
        var command = GetCommand(connection, "SELECT name FROM sys.databases where name !='master'");
        connection.Open();

        databases = GetResults(command);
        connection.Close();
    }
    foreach (var database in databases)
    {
        log.Info(database);
        RebuildIndex(database, log);
    }
}

private static System.Data.SqlClient.SqlCommand GetCommand(System.Data.SqlClient.SqlConnection connection, string cmdtext)
{
    return new System.Data.SqlClient.SqlCommand(cmdtext, connection) { CommandTimeout = 3000 };
}

private static void RebuildIndex(string name, TraceWriter log)
{
    string RebuildCommand = @"SELECT 
'ALTER INDEX [' + name + '] ON [dbo].[' + object_name(a.object_id) + '] REBUILD WITH (ONLINE = ON);'
        FROM sys.dm_db_index_physical_stats(
               DB_ID(N'')
             , OBJECT_ID(0)
             , NULL
             , NULL
             , NULL) AS a
        JOIN sys.indexes AS b
        ON a.object_id = b.object_id AND a.index_id = b.index_id where   avg_fragmentation_in_percent > 30 and name !='PK_LogEntry' order by avg_fragmentation_in_percent desc 
";

    using (var connection = GetDatabaseConnectionString(name))
    {
        var command = GetCommand(
            connection, RebuildCommand);
        connection.Open();

        var commands = GetResults(command);
        foreach (var rebuildText in commands)
        {
            command = GetCommand(
            connection, rebuildText);
            try
            {
                command.ExecuteNonQuery();
            }
            catch (Exception ex)
            {
                log.Error(ex.Message);
            }
        }
    }
}

private static List<String> GetResults(System.Data.SqlClient.SqlCommand command)
{
    var list = new List<String>();
    using (var reader = command.ExecuteReader())
    {
        while (reader.Read())
        {
            list.Add(reader[0].ToString());
        }
    }
    return list;
}
public static System.Data.SqlClient.SqlConnection GetMasterDatabaseConnectionString()
{
    string masterdatabaseName = "master";
    return
              GetDatabaseConnectionString(masterdatabaseName);
}

public static System.Data.SqlClient.SqlConnection GetDatabaseConnectionString(string name)
{
    string connectionStringTemplate = System.Configuration.ConfigurationManager.ConnectionStrings["ConnectionString"].ConnectionString;

    var connB = new System.Data.SqlClient.SqlConnectionStringBuilder(connectionStringTemplate) { InitialCatalog = name, ConnectTimeout = 500 };

    var conn = new System.Data.SqlClient.SqlConnection(connB.ConnectionString);

    return conn;
}



