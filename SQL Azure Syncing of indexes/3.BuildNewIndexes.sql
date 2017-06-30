CREATE PROCEDURE [dbo].[UpBuildNewIndex] @CreateScript NVARCHAR(max) 
AS 
DECLARE @oldindexes NVARCHAR(max) 

SELECT @oldindexes = Concat(@oldindexes, ( ';drop index ' + index_name + 
                                           ' on ' + 
                                                  tablename )) 
FROM   (SELECT t.NAME  AS tableName, 
               si.NAME AS index_name 
        FROM   sys.indexes AS si 
               JOIN sys.tables AS t 
                 ON si.object_id = t.object_id 
        WHERE  si.type IN ( 0, 1, 2 )) AS indexes 
WHERE  index_name NOT LIKE '%PK_%' 


EXEC Sp_executesql 
  @oldindexes 

EXEC Sp_executesql 
  @CreateScript 