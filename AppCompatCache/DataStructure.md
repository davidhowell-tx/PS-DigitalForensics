
# Windows AppCompatCache Registry Data Structure
This information was derived from analysis of Harlan Carvey's AppCompatCache.pl
This information may be inaccurrate


# Windows XP 32-bit

## Header - 400 Bytes
| Offset | Length | Value    | Value Format            | Notes |
| ------ | ------ | -------- | ----------------------- | ----- |
| 0      | 4      | EFBEADDE | Hexadecimal string      | Header - DEADBEEF in Little-Endian |
| 4      | 4      |          | Unsigned 32-bit integer | Number of entries in the cache |
| 8      | 4      |          | Unsigned 32-bit integer | Number of LUR array entries |
| 12     | 4      |          |                         | Unknown |
| 16     |        |          |                         | Start of LRU Array. Each LRU Entry is a 32-bit unsigned integer which is the index number of the cache entry |

## Cache Entry - 552 bytes
Offsets are shown from the start of the entry

| Offset | Length | Value Format            | Notes |
| ------ | ------ | ----------------------- | ----- |
| 0      | 528    | Unicode string          | File path and name |
| 528    | 8      | Unsigned 64-bit integer Windows File Time | Last modified time of file at the time of execution |
| 536    | 8      | Unsigned 64-bit integer | File's size at execution |
| 544    | 8      | Unsigned 64-bit integer Windows File Time | Last updated time |

# Windows XP 64-bit, Windows Server 2003, Windows Vista, Windows 2008

## Header - 8 Bytes
| Offset | Length | Value    | Value Format            | Notes |
| ------ | ------ | -------- | ----------------------- | ----- |
| 0      | 4      | FE0FDCBA | Hexadecimal string      | Header - BADC0FFE in Little-Endian |
| 4      | 4      |          | Unsigned 32-bit integer | Number of entries in the cache |

## 64-bit OS Entry - 32 Bytes
Offsets are shown from the start of the entry

| Offset | Length | Value Format                              | Notes |
| ------ | ------ | ----------------------------------------- | ----- |
| 0      | 2      | Unsigned 16-bit Integer                   | Length of filename string |
| 2      | 2      | Unsigned 16-bit Integer                   | Maximum length of filename |
| 4      | 4      |                                           | Unknown / Padding |
| 8      | 8      | Unsigned 64-bit Integer                   | Offset to start of filename string |
| 16     | 8      | Unsigned 64-bit Integer Windows File Time | Last Modified Time of the file |
| 24     | 8      | Unsigned 64-bit Integer                   | File Size |

## 32-bit OS Entry - 24 Bytes
Offsets are shown from the start of the entry

| Offset | Length | Value Format                              | Notes |
| ------ | ------ | ----------------------------------------- | ----- |
| 0      | 2      | Unsigned 16-bit Integer                   | Length of filename string |
| 2      | 2      | Unsigned 16-bit Integer                   | Maximum length of filename |
| 4      | 4      | Unsigned 32-bit Integer                   | Offset to start of filename string |
| 8      | 8      | Unsigned 64-bit Integer Windows File Time | Last Modified Time of the file |
| 16     | 8      | Unsigned 64-bit Integer                   | File Size |



# Windows 7, Windows 2008 R2

## Header - 128 Bytes
| Offset | Length | Value    | Value Format            | Notes |
| ------ | ------ | -------- | ----------------------- | ----- |
| 0      | 4      | EE0FDCBA | Hexadecimal string      | Header - BADC0FEE in Little-Endian |
| 4      | 4      |          | Unsigned 32-bit integer | Number of entries in the cache |
| 8      | 4      | 120      |                         | Unknown - remaining size of header? |
| 12     | 116    |          |                         | Unknown - cache statistics? |

## 64-Bit OS Entry - 48 bytes
Offsets are shown from the start of the entry

| Offset | Length | Value Format                              | Notes |
| ------ | ------ | ----------------------------------------- | ----- |
| 0      | 2      | Unsigned 16-bit Integer                   | Length of filename string |
| 2      | 2      | Unsigned 16-bit Integer                   | Max length of filename string (with unicode end-of-string character) |
| 4      | 4      |                                           | Unknown / Padding |
| 8      | 4      | Unsigned 32-bit Integer                   | Offset to start of filename string |
| 12     | 8      | Unsigned 64-bit Integer Windows File Time | Last Modified Time of the file |
| 20     | 4      |                                           | Insertion Flags |
| 24     | 4      |                                           | Shim Flags |
| 28     | 8      | Unsigned 64-bit Integer                   | Data size |
| 36     | 8      | Unsigned 64-bit Integer                   | Data offset |

## 32-Bit OS Entry - 32 bytes
Offsets are shown from the start of the entry

| Offset | Length | Value Format                              | Notes |
| ------ | ------ | ----------------------------------------- | ----- |
| 0      | 2      | Unsigned 16-bit Integer                   | Length of filename string |
| 2      | 2      | Unsigned 16-bit Integer                   | Max length of filename string (with unicode end-of-string character) |
| 4      | 4      | Unsigned 32-bit Integer                   | Offset to start of filename string |
| 8      | 8      | Unsigned 64-bit Integer Windows File Time | Last Modified Time of the file |
| 16     | 4      |                                           | Insertion Flags |
| 20     | 4      |                                           | Shim Flags |
| 24     | 4      | Unsigned 32-bit Integer                   | Data size |
| 28     | 4      | Unsigned 32-bit Integer                   | Data offset |

# Windows 8

## Header - 128 Bytes
| Offset | Length | Value | Value Format | Notes |
| ------ | ------ | ----- | -------------| ----- |
| 0      | 4      | 128   | Decimal      | Header Size / Cache Array Offset |
| 4      | 4      |       |              | Unknown |
| 8      | 120    |       |              | Unknown |

## Windows 8.0 Cache Entry - Variable Size
Offsets are shown from the start of the entry

| Offset | Length | Value | Value Format                              | Notes |
| ------ | ------ | ----- | ----------------------------------------- | ----- |
| 0      | 4      | 00ts  | ASCII String                              | Signature |
| 4      | 4      |       |                                           | Unknown |
| 8      | 4      |       | Unsigned 32-bit Integer                   | Cache Entry Data Size |
| 12     | 2      |       | Unsigned 16-bit Integer                   | Path Size |
| 14     |        |       | Unicode String                            | Path |
|        | 4      |       |                                           | Unknown - Insertion flags? |
|        | 4      |       |                                           | Unknown - Shim Flags? |
|        | 8      |       | Unsigned 64-bit Integer Windows File Time | Last Modified Time of the file |
|        | 4      |       | Unsigned 32-bit Integer                   | Data size |
|        |        |       |                                           | Data |

## Windows 8.1 Cache Entry - Variable Size
Offsets are shown from the start of the entry

| Offset | Length | Value | Value Format                              | Notes |
| ------ | ------ | ----- | ----------------------------------------- | ----- |
| 0      | 4      | 10ts  | ASCII String                              | Signature |
| 4      | 4      |       |                                           | Unknown |
| 8      | 4      |       | Unsigned 32-bit Integer                   | Cache Entry Data Size |
| 12     | 2      |       | Unsigned 16-bit Integer                   | Path Size |
| 14     |        |       | Unicode String                            | Path |
|        | 4      |       |                                           | Unknown - Insertion flags? |
|        | 4      |       |                                           | Unknown - Shim Flags? |
|        | 2      |       |                                           | Unknown |
|        | 8      |       | Unsigned 64-bit Integer Windows File Time | Last Modified Time of the file |
|        | 4      |       | Unsigned 32-bit Integer                   | Data size |
|        |        |       |                                           | Data |



# Windows 10

## Header - 48 bytes
| Offset | Length | Value | Value Format            | Notes |
| ------ | ------ | ----- | ----------------------- | ----- |
| 0      | 4      | 48    | Decimal                 | Header Size / Cache Array Offset |
| 4      | 4      |       |                         | Unknown |
| 8      | 4      |       |                         | Unknown - empty values |
| 12     | 4      |       |                         | Unknown |
| 16     | 4      |       |                         | Unknown |
| 20     | 16     |       |                         | Unknown - empty values |
| 36     | 4      |       | Unsigned 32-bit Integer | Number of cache entries |
| 40     | 8      |       |                         | Unknown - empty values |

## Windows 10 Cache Entry - Variable Size
Offsets are shown from the start of the entry

| Offset | Length | Value | Value Format                              | Notes |
| ------ | ------ | ----- | ----------------------------------------- | ----- |
| 0      | 4      | 10ts  | ASCII String                              | Signature |
| 4      | 4      |       |                                           | Unknown |
| 8      | 4      |       | Unsigned 32-bit Integer                   | Cache Entry Data Size |
| 12     | 2      |       | Unsigned 16-bit Integer                   | Path Size |
| 14     |        |       | Unicode String                            | Path |
|        | 8      |       | Unsigned 64-bit Integer Windows File Time | Last Modified Time of the file |
|        | 4      |       | Unsigned 32-bit Integer                   | Data size |
|        |        |       |                                           | Data |
