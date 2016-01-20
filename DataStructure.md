Information Regarding Data Structures

# Master Boot Record

| Offset | Length | Value | Value Format             | Notes |
| ------ | ------ | ===== |------------------------- | ----- |
| 0      | 440    |       |                          | Bootstrap code |
| 440    | 4      |       | Hexadecimal String       | Drive Signature |
| 444    | 2      | 00 00 |                          |  |
| 446    | 64     |       | See Partion Entry Format | Partition Table |
| 510    | 2      | 55 AA | Hexadecimal              | End of MBR Marker |

## MBR Partition Entry
Offsets are shown from the start of the entry itself
| Offset | Length | Value    | Value Format            | Notes |
| ------ | ------ | -------- | ----------------------- | ----- |
| 0      | 1      | 00 or 80 |                         | Is Bootable Flag. 80 means bootable |
| 1      | 1      |          | Decimal Value           | Starting Head |
| 2      | 6/8    |          | Decimal Value           | Starting Sector. Lower 6 bits |
| 2      | 1 2/8  |          | Decimal Value           | Starting Cylinder |
| 4      | 1      |          |                         | Partition Type |
| 5      | 1      |          | Decimal Value           | Ending Head |
| 6      | 6/8    |          | Decimal Value           | Ending Sector |
| 6      | 1 2/8  |          | Decimal Value           | Ending Cylinder |
| 8      | 4      |          | Unsigned 32-bit Integer | Relative Start Sector |
| 12     | 4      |          | Unsigned 32-bit Integer | Total Sectors |

## GUID Partition Table Header
| Offset | Length | Value    | Value Format            | Notes |
| ------ | ------ | -------- | ----------------------- | ----- |
| 0      | 8      | EFI PART | ASCII String            | GPT Signature |
| 8      | 4      |          | Hexadecimal String      | GPT Revision (0x01 0x00 means 1.0) |
| 12     | 4      | 92       | Decimal value           | GPT Header Size |
| 16     | 4      |          | Hexadecimal String      | Header CRC |
| 20     | 4      |          |                         | Unknown |
| 24     | 8      | 1        | Unsigned 64-bit integer | LBA of the GPT |
| 32     | 8      |          | Unsigned 64-bit integer | LBA of alternate GPT |
| 40     | 8      |          | Unsigned 64-bit integer | First usable LBA |
| 48     | 8      |          | Unsigned 64-bit integer | Last usable LBA |
| 56     | 16     |          | Hexadecimal String      | Disk GUID. 1st half in little endian, 2nd half big endian |
| 72     | 8      | 2        | Unsigned 64-bit integer | LBA of the Partition Table |
| 80     | 4      | 128      | Unsigned 32-bit integer | Number of Partition Entries |
| 84     | 4      | 128      | Unsigned 32-bit integer | Size of Partition Entries |
| 88     | 4      |          | Hexadecimal string      | Partition Entry Array CRC

## GPT Partition Entry
Offsets are shown from the start of the entry itself
Offsets are shown from the start of the entry itself
| Offset | Length | Value Format            | Notes |
| ------ | ------ | ----------------------- | ----- |
| 0      | 16     | Hexadecimal String      | Partition Type GUID. 1st half little endian, 2nd half big endian |
| 16     | 16     | Hexadecimal string      | Unique Partition GUID. 1st half little endian, 2nd half big endian |
| 32     | 8      | Unsigned 64-bit integer | Partition Start LBA |
| 40     | 8      | Unsigned 64-bit integer | Partition End LBA |
| 48     | 8      |                         | Attributes |
| 56     | 72     | Unicode String          | Partition Name |