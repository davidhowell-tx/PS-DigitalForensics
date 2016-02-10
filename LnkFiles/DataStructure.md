# Invoke-LnkFileParser

## File Header - 76 Bytes

| Offset | Length | Value    | Value Format            | Notes |
| ------ | ------ | -------- | ----------------------- | ----- |
| 0      | 4      | 76       |                         | Header length |
| 4      | 16     |          | Hexadecimal String      | Link file GUID |
| 20     | 4      |          |                         | Data Flags |
| 24     | 4      |          |                         | Attribute Flags |
| 28     | 8      |          | Windows Filetime        | Created Date |
| 36     | 8      |          | Windows Filetime        | Accessed Date |
| 44     | 8      |          | Windows Filetime        | Modified Date |

## Link target identifiers List
| Offset | Length | Value    | Value Format            | Notes |
| ------ | ------ | -------- | ----------------------- | ----- |
| 0      | 2      |          |                         | length of link target list|
| 2      |        |          |                         | link target list |


## Location Information

## Data Strings