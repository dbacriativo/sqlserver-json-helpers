# SQL Server JSON Helpers

This is my first project published on github. I will be happy to know if it will be useful to you. Feel free to criticize or suggest improvements.

This repository contains helper functions for working with JSON in SQL Server.

## Functions

### JSON_INT()

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

### JSON_OBJECT()

Description:
This function is used to add or update a JSON object at the specified JSON path within a JSON object.

Parameters:
- `@JSON NVARCHAR(MAX)`: The JSON object.
- `@PATH NVARCHAR(MAX)`: The JSON path to add or update.
- `@VALUE NVARCHAR(MAX)`: The JSON object to add at the specified path.

Examples:
```sql
-- error test
 SELECT dbo.[JSON_OBJECT]('{}', 'este.eh.um.path', 'invalid json')
 -- output error

  -- TEST ADD OBJECT
 SELECT dbo.[JSON_OBJECT]('{}', 'this.is.a.path', '{"name":"renato"}')
 -- output {"this":{"is": {"a": {"path": {"name":"renato"}}}}}

 -- TEST ADD OBJECT ON ANOTHER PATH
 SELECT dbo.[JSON_OBJECT]('{"this":{"is": {"a": {"path": {"name":["renato"]}}}}}', 'this.path.not.exist', '{"dir":"c:\\"}')
 -- output {"this":{"is": {"a": {"path": {"name":["renato"]}}},"path":{"not": {"exist": {"dir":"c:\\"}}}}}
```

### JSON_TEXT()

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
