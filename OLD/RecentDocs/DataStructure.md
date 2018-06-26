
# RecentDocs
HKEY_USERS:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs

Values named numerically containing binary data structures.

MRUListEx Value contains a binary structure with DWORD values noting the Most Recently Used order, referencing the numerical name of other values in this key.

Child Keys for file extensions that also contain MRU lists in the same format

## RecentDocs Entry Structure
| Offset | Length | Format         | Notes |
| ------ | ------ | -------- ----- | ----- |
| 0      |        | Unicode String | Item Name |
|        |        | Unknown        | Unknown values? |
|        |        | ASCII String   | Associated Link file |
|        |        | Unknown        | Unknown values? |
|        |        | Unicode String | Associated Link file |
|        |        | Unknown        | Unknown values? |

Between each string there are some values that are unknown to me.  I can't find any documentation anywhere that explains the purpose of these values, but there is some consistency between these values on my system.

