/*
Author: Renato Magalhães Silva
Contact: dbacriativo@gmail.com
Date: 26/04/2024

Description:
This function is used to add or update a text value at the specified JSON path within a JSON object. This function is more versatile, where it is possible to enter a Json Object, or Text, value. It also has support for including items in arrays.

Parameters:
- `@JSON NVARCHAR(MAX)`: The JSON object.
- `@PATH NVARCHAR(MAX)`: The JSON path to add or update.
- `@VALUE NVARCHAR(MAX)`: The text value to add at the specified path.

Examples:
```sql
-- TEST INSERT INTEGER
 SELECT dbo.[JSON_TEXT]('{}', 'this.is.a.path', 1234)
 -- output {"this":{"is": {"a": {"path": "1234"}}}}

 -- TEST ADD DATE
 SELECT dbo.[JSON_TEXT]('{}', 'this.is.a.path', CONVERT(VARCHAR(23), GETDATE(),126))
-- output {"this":{"is": {"a": {"path": "2024-04-26T16:51:11.833"}}}}

 -- TEST ADD ITEM ON ARRAY
 SELECT dbo.[JSON_TEXT]('{"this":{"is": {"a": {"path": {"name":["renato"]}}}}}', 'this.is.a.path.name', 1234)
 -- output  {"this":{"is": {"a": {"path": {"name":["renato","1234"]}}}}}
 
  -- TEST ADD JSON OBJECT
 SELECT dbo.[JSON_TEXT]('{"this":{"is": {"a": {"path": {"name":["renato"]}}}}}', 'this.is.a.path.name', '{"item":"ok"}')
 -- output  {"this":{"is": {"a": {"path": {"name":["renato",{"item":"ok"}]}}}}}

 -- TEST ADD THREE
 SELECT dbo.[JSON_TEXT]('{"this":{"is": {"a": {"path": {"name":["renato"]}}}}}', 'this.is.a.path.that.not.exists', 1234)
-- {"this":{"is": {"a": {"path": {"name":["renato"],"that":{"not": {"exists": "1234"}}}}}}}

```

*/
CREATE FUNCTION [dbo].[JSON_TEXT](@JSON NVARCHAR(MAX), @PATH NVARCHAR(255), @VALUE VARCHAR(500))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    -- SETUP JSON
    IF ISNULL(@JSON,'') = ''
    BEGIN
	   SET @JSON = '{}';
    END;

    SET @PATH = REPLACE(@PATH, '$.', '');

    -- quando o path existir e for uma propriedade atualiza o valor ou adiciona um valor ao array
    IF JSON_VALUE(@JSON, CONCAT('$.', @PATH)) IS NOT NULL 
    BEGIN
	   --RETURN 'É UMA PROPRIEDADE'
	   IF ISJSON(@VALUE) > 0 BEGIN
		  -- se o valor a ser atualizado é um objeto json então utiliza json_query
		  SET @JSON = JSON_MODIFY(@JSON, CONCAT('$.', @PATH), JSON_QUERY(@VALUE))
	   END 
	   ELSE BEGIN
		  -- caso contrário utiliza valor comum
	   	  SET @JSON = JSON_MODIFY(@JSON, CONCAT('$.', @PATH), @VALUE)
	   END;
    END
    ELSE
    BEGIN
	   IF JSON_QUERY(@JSON, CONCAT('$.', @PATH)) IS NOT NULL
	   BEGIN
		  --RETURN 'É UM OBJETO OU ARRAY'

		  IF ISJSON(@VALUE) > 0 BEGIN
			 -- se o valor a ser atualizado é um objeto json então utiliza json_query
			 SET @JSON = JSON_MODIFY(@JSON, CONCAT('append lax $.', @PATH), JSON_QUERY(@VALUE))
		  END 
		  ELSE BEGIN
			 -- caso contrário utiliza valor comum
			 SET @JSON = JSON_MODIFY(@JSON, CONCAT('append lax $.', @PATH), @VALUE)
		  END
	   END 
	   ELSE
	   BEGIN
	   	  --RETURN 'O PATH NÃO EXISTE'
		  DECLARE @TBLPATH TABLE (ID int identity, NAME varchar(255));
		  DECLARE @LEVELS INT = LEN(@PATH) - LEN(REPLACE(@PATH, '.','')) + 1;
		  DECLARE @JSON2 NVARCHAR(MAX) = '';
		  DECLARE @NAME VARCHAR(255);
		  DECLARE @CURPATH VARCHAR(255) = '$';
		  DECLARE @ID int = 1;

		  -- quando o path não existir é necessário um loop para criar o path no objeto json de origem
		  INSERT INTO @TBLPATH
			 SELECT value FROM STRING_SPLIT(@PATH, '.')

		  -- realiza um loop no objeto de origem para criar o path completo
		  WHILE @ID <= @LEVELS
		  BEGIN
			 SELECT @NAME = NAME
			   FROM @TBLPATH
			  WHERE ID = @ID;

			 -- se não existir o path tenta criar
			 IF JSON_QUERY(@JSON, @CURPATH) IS NULL
			 BEGIN
				SET @JSON = JSON_MODIFY(@JSON, @CURPATH, JSON_QUERY(CONCAT('{"', @NAME, '": null}'))); 
			 END;

			 -- atualiza o current path
			 SET @CURPATH = CONCAT(@CURPATH, '.', @NAME);

			 SET @ID = @ID + 1;
		  END;

		  -- depois que criar a arvore atualiza o valor
		  IF ISJSON(@VALUE) > 0
		  BEGIN
			 SET @JSON = JSON_MODIFY(@JSON, CONCAT('$.', @PATH), JSON_QUERY(@VALUE))
		  END ELSE
		  BEGIN
			 SET @JSON = JSON_MODIFY(@JSON, CONCAT('$.', @PATH), @VALUE)
		  END;
	   END;
    END;

    RETURN @JSON;
END;

GO


