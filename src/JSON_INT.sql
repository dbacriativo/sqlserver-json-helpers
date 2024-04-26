/*
Author: Renato Magalhães Silva
Contact: dbacriativo@gmail.com
Date: 26/04/2024

Description:
This function is used to add or update an integer value at the specified JSON path within a JSON object.

Parameters:
- `@JSON NVARCHAR(MAX)`: The JSON object.
- `@PATH NVARCHAR(MAX)`: The JSON path to add or update.
- `@VALUE INT`: The integer value to add at the specified path.

Examples:
```sql
 -- TEST INSERT
 SELECT dbo.[JSON_INT]('{}', 'this.is.a.path', 1234)
 -- output {"this":{"is": {"a": {"path": 1234}}}}
 
 -- TEST UPDATE
  SELECT dbo.[JSON_INT]('{"this":{"is": {"a": {"path": {"name":["renato"]}}}}}', 'this.is.a.path', 1234)
 -- output {"this":{"is": {"a": {"path": 1234}}}}
 
 -- TEST TREE
  SELECT dbo.[JSON_INT]('{"this":{"is": {"a": {"path": {"name":["renato"]}}}}}', 'this.path.not.extis', 1234)
-- output {"this":{"is": {"a": {"path": {"name":["renato"]}}},"path":{"not": {"extis": 1234}}}}
```
*/
CREATE FUNCTION [dbo].[JSON_INT](@JSON NVARCHAR(MAX), @PATH NVARCHAR(255), @VALUE INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN

    -- SETUP JSON
    IF ISNULL(@JSON,'') = ''
    BEGIN
	   SET @JSON = '{}';
    END;

    SET @PATH = REPLACE(@PATH, '$.', '');

    -- IF PATH EXISTS AND IS PROPERTY
    IF JSON_VALUE(@JSON, CONCAT('$.', @PATH)) IS NOT NULL 
    BEGIN
	   --RETURN 'PROPERTY'
	   SET @JSON = JSON_MODIFY(@JSON, CONCAT('$.', @PATH), @VALUE)
    END
    ELSE
    BEGIN
	   -- IF PATH EXISTS AND IS OBJECT OR ARRAY
	   IF JSON_QUERY(@JSON, CONCAT('$.', @PATH)) IS NOT NULL
	   BEGIN
		  --RETURN 'OBJECT OR ARRAY'
    		  SET @JSON = JSON_MODIFY(@JSON, CONCAT('$.', @PATH), @VALUE)
	   END 
	   ELSE
	   BEGIN
		  --RETURN 'PATH NOT EXISTS'
	   	  -- PATH NOT EXTISTS NEED TO BUILD PATH
		  DECLARE @TBLPATH TABLE (ID int identity, NAME varchar(255));
		  DECLARE @LEVELS INT = LEN(@PATH) - LEN(REPLACE(@PATH, '.','')) + 1;
		  DECLARE @JSON2 NVARCHAR(MAX) = '';
		  DECLARE @NAME VARCHAR(255);
		  DECLARE @CURPATH VARCHAR(255) = '$';
		  DECLARE @ID int = 1;

		  -- SPLIT PATH INTO PIECES
		  INSERT INTO @TBLPATH
			 SELECT value FROM STRING_SPLIT(@PATH, '.')

		  -- LOOP ON EACH PIECE OF PATH
		  WHILE @ID <= @LEVELS
		  BEGIN
			 SELECT @NAME = NAME
			   FROM @TBLPATH
			  WHERE ID = @ID;

			 -- CREATE PATCH
			 IF JSON_QUERY(@JSON, @CURPATH) IS NULL
			 BEGIN
				SET @JSON = JSON_MODIFY(@JSON, @CURPATH, JSON_QUERY(CONCAT('{"', @NAME, '": null}'))); 
			 END;

			 -- UPDATE CURRENT
			 SET @CURPATH = CONCAT(@CURPATH, '.', @NAME);

			 SET @ID = @ID + 1;
		  END;

		  -- UPDATE TREE
		  SET @JSON = JSON_MODIFY(@JSON, CONCAT('$.', @PATH), @VALUE)
	   END;
    END;

    -- UPDATED JSON
    RETURN @JSON;
END;



GO


