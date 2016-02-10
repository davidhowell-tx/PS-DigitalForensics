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


# Volume Boot Record

## FAT32 VBR
| Offset | Length | Value     | Value Format            | Notes |
| ------ | ------ | --------- | ----------------------- | ----- |
| 0      | 3      |           |                         | Jump Instruction |
| 3      | 8      | MSDOS5.0  | ASCII String            | VBR Signature |
| 11     | 2      |           | Unsigned 16-bit Integer | Bytes per sector |
| 13     | 1      |           |                         | logical sectors per cluster |
| 14     | 2      |           | Unsigned 16-bit Integer | Reserved logical sectors |
| 16     | 1      |           |                         | Number of FATs |
| 17     | 2      |           | Unsigned 16-bit Integer | Root directory entries |
| 19     | 2      |           | Unsigned 16-bit Integer | Total logical sectors |
| 21     | 1      |           |                         | Media descriptor |
| 22     | 2      |           | Unsigned 16-bit Integer | Logical sectors per FAT |
| 24     | 2      |           | Unsigned 16-bit Integer | Physical sectors per track |
| 26     | 2      |           | Unsigned 16-bit Integer | Number of heads |
| 28     | 4      |           | Unsigned 32-bit Integer | Hidden sectors | 
| 32     | 4      |           | Unsigned 32-bit Integer | Large total logical sectors |
| 36     | 4      |           | Unsigned 32-bit Integer | Logical sectors per FAT |
| 40     | 2      |           |                         | Mirroring flags |
| 42     | 2      |           |                         | Version |
| 44     | 4      |           | Unsigned 32-bit Integer | Root directory cluster |
| 48     | 2      |           | Unsigned 16-bit Integer | Location of FS Information Sector |
| 50     | 2      |           | Unsigned 16-bit Integer | Location of backup sector |
| 52     | 12     |           |                         | Reserved |
| 64     | 1      |           |                         | Physical drive number |
| 65     | 1      |           |                         | Flags |
| 66     | 1      |           |                         | Extended boot signature |
| 67     | 4      |           |                         | Volume serial number |
| 71     | 11     |           | ASCII String            | Volume label |
| 82     | 8      |           | ASCII String            | File System Type |

## NTFS VBR
| Offset | Length | Value     | Value Format            | Notes |
| ------ | ------ | --------- | ----------------------- | ----- |
| 0      | 3      |           |                         | Jump Instruction |
| 3      | 8      | NTFS      | ASCII String            | VBR Signature |
| 11     | 2      |           | Unsigned 16-bit Integer | Bytes per sector |
| 13     | 1      |           |                         | logical sectors per cluster |
| 14     | 2      |           | Unsigned 16-bit Integer | Reserved logical sectors |
| 16     | 1      |           |                         | Number of FATs |
| 17     | 2      |           | Unsigned 16-bit Integer | Root directory entries |
| 19     | 2      |           | Unsigned 16-bit Integer | Total logical sectors |
| 21     | 1      |           |                         | Media descriptor |
| 22     | 2      |           | Unsigned 16-bit Integer | Logical sectors per FAT |
| 24     | 2      |           | Unsigned 16-bit Integer | Physical sectors per track |
| 26     | 2      |           | Unsigned 16-bit Integer | Number of heads |
| 28     | 4      |           | Unsigned 32-bit Integer | Hidden sectors | 
| 32     | 4      |           | Unsigned 32-bit Integer | Large total logical sectors |
| 36     | 1      |           |                         | Physical Drive Number |
| 37     | 1      |           |                         | Flags |
| 38     | 1      |           |                         | Extended boot signature |
| 39     | 1      |           |                         | Reserved |
| 40     | 8      |           | Unsigned 64-bit Integer | Sectors in Volume |
| 48     | 8      |           | Unsigned 64-bit Integer | MFT first cluster number |
| 56     | 8      |           | Unsigned 64-bit Integer | MFT mirror first cluster number |
| 64     | 4      |           | Unsigned 32-bit Integer | MFT record size |
| 68     | 4      |           | Unsigned 32-bit Integer | Index block size |
| 72     | 8      |           |                         | Volume Serial Number |
| 80     | 4      |           |                         | Checksum |

