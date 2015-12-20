
# Windows Prefetch Data Structures


# Windows XP

## File Header - 84 Bytes
| Offset | Length | Value    | Value Format            | Notes |
| ------ | ------ | -------- | ----------------------- |       |
| 0      | 4      | 11000000 | Hexadecimal             | Format Version |
| 4      | 4      | SCCA     | ASCII                   | Signature |
| 8      | 4      | 0F000000 | Hexadecimal             | Unknown Purpose |
| 12     | 4      |          | Unsigned 32-bit Integer | Prefetch File Size |
| 16     | 60     |          | Unicode String          | Name of Executable - 29 characters with U+0000 end-of-string character |
| 76     | 4      |          | Hexadecimal String      | Prefetch Hash |
| 80     | 4      |          |                         | Unknown (flags?) |

## File Information - 68 Bytes
| Offset | Length | Value | Value Format                       | Notes |
| ------ | ------ | ----- | ---------------------------------- | ----- |
| 84     | 4      |       | Unsigned 32-bit Integer            | Offset from start of file to Section A |
| 88     | 4      |       | Unsigned 32-bit Integer            | Number of entries in Section A |
| 92     | 4      |       | Unsigned 32-bit Integer            | Offset from start of file to Section B |
| 96     | 4      |       | Unsigned 32-bit Integer            | Number of entries in Section B |
| 100    | 4      |       | Unsigned 32-bit Integer            | Offset from start of file to Section C |
| 104    | 4      |       | Unsigned 32-bit Integer            | Length of Section C |
| 108    | 4      |       | Unsigned 32-bit Integer            | Offset from start of file to Section D |
| 112    | 4      |       | Unsigned 32-bit Integer            | Number of entries in Section D |
| 116    | 4      |       | Unsigned 32-bit Integer            | Length of Section D |
| 120    | 8      |       | Unsigned 64-bit Integer Epoch Time | Last Execution Time |
| 128    | 16     |       |                                    | Unknown |
| 144    | 4      |       | Unsigned 32-bit Integer            | Execution Count |
| 148    | 4      |       |                                    | Unknown |

## Metrics Array
Metrics Entry Records are 20 bytes each. Offsets are shown from the start of the metrics entry.
| Offset | Length | Value | Value Format            | Notes  |
| ------ | ------ | ----- | ----------------------- | ------ |
| 0      | 4      |       |                         | Unknown |
| 4      | 4      |       |                         | Unknown |
| 8      | 4      |       | Unsigned 32-bit Integer | Filename String Offset |
| 12     | 4      |       | Unsigned 32-bit Integer | Number of Unicode Characters in Filename |
| 16     | 4      |       |                         | Unknown |

## Trace Chains Array
Trace Chains Entry Records are 12 bytes each. Offsets are shown from the start of the Trace Chains entry record.
| Offset | Length | Value Format | Notes |
| ------ | ------ | ------------ | ----- |
| 0      | 4      |              | Next array entry index |
| 4      | 4      |              | Total block load count |
| 8      | 1      |              | Unknown |
| 9      | 1      |              | Unknown (Sample duration in milliseconds?) |
| 10     | 2      |              | Unknown |

## Filename Strings Array
Filename Strings array contains Unicode Filename Strings terminated by the U+0000 end-of-string character. The offset of each string is recorded in the Metrics Array recorded as the offset from the start of the Filename Strings array. The length of each string in Unicode character is also recorded in the Metrics array.

## Volume Information Array
Each volume referenced in the Filename Strings array will also contain an entry in the Volume Information array. 
Each Volume Information array contains information about the volume as well as an NTFS file references array, and a directory strings array.

Volume Information entries are 40 bytes each. Offsets are shown from the start of the Volume Information entry record.

| Offset | Length | Value Format                       | Notes |
| ------ | ------ | ---------------------------------- | ----- |
| 0      | 4      | Unsigned 32-bit Integer            | Offset from start of Section D to volume device path |
| 4      | 4      | Unsigned 32-bit Integer            | Length of volume device path in Unicode characters |
| 8      | 8      | Unsigned 64-bit Integer Epoch time | Volume Creation Time |
| 16     | 4      | Hexadecimal String                 | Volume serial number |
| 20     | 4      | Unsigned 32-bit Integer            | Offset from start of Section D to Subsection E |
| 24     | 4      | Unsigned 32-bit Integer            | Length of Subsection E in bytes |
| 28     | 4      | Unsigned 32-bit Integer            | Offset from start of Section D to Subsection F |
| 32     | 4      | Unsigned 32-bit Integer            | Number of strings in Subsection F |
| 36     | 4      |                                    | Unknown |

### NTFS File Reference Array
NTFS File reference entries are 8 bytes in size.

| Offset | Length | Value Format | Notes |
| ------ | ------ | ------------ | ----- |
| 0      | 6      |              | MFT Entry Index |
| 6      | 2      |              | Sequence Number |

### Directory Strings Array
An array of Unicode directory strings associated with files accessed by the executable. The number of string entries is stored in the Volume Information array.

Each directory string entry has the following structure:
| Offset | Length | Value Format            | Notes |
| ------ | ------ | ----------------------- | ----- |
| 0      | 2      | Unsigned 16-bit Integer | Length of directory string in Unicode characters |
| 2      |        | Unicode string          | Directory Name |
|        | 2      | Unicode                 | U+0000 end-of-string character |

# Windows 7

## Overview of Sections
* File Header - 84 Bytes
* File Information - 156 Bytes
* Section A - Metrics Array
* Section B - Trace Chains Array
* Section C - Filename Strings
* Section D - Volume Information
  * Subsection E - NTFS File References
  * Subsection F - Directory Strings

## File Header
* Offset 0 - Length 4 - Format Version  - Value 0x17000000
* Offset 4 - Length 4 - Signature - Value "SCCA" in ASCII
* Offset 8 - Length 4 - Unknown - Value 0x11000000
* Offset 12 - Length 4 - Prefetch Size - Unsigned 32-bit Integer
* Offset 16 - Length 60 - Original Executable Name - Unicode String
* Offset 76 - Length 4 - Prefetch Hash - Hexadecimal
* Offset 80 - Length 4 - Unknown Flags

## File Information
* Offset 84 - Length 4 - Offset to Section A - Unsigned 32-bit Integer
* Offset 88 - Length 4 - Number of Entries in Section A - Unsigned 32-bit Integer
* Offset 92 - Length 4 - Offset to Section B - Unsigned 32-bit Integer
* Offset 96 - Length 4 - Number of Entries in Section B - Unsigned 32-bit Integer
* Offset 100 - Length 4 - Offset to Section C - Unsigned 32-bit Integer
* Offset 104 - Length 4 - Length of Section C - Unsigned 32-bit Integer
* Offset 108 - Length 4 - Offset to Section D - Unsigned 32-bit Integer
* Offset 112 - Length 4 - Nuumber of Entries in Section D - Unsigned 32-bit Integer
* Offset 116 - Length 4 - Length of Section D - Unsigned 32-bit Integer
* Offset 120 - Length 8 - Unknown
* Offset 128 - Length 8 - Last Execution Time
* Offset 136 - Length 16 - Unknown
* Offset 152 - Length 4 - Number of Executions - Unsigned 32-bit Integer
* Offset 156 - Length 4 - Unknown - Unsigned 32-bit Integer
* Offset 160 - Length 80 - Unknown

## Section A - Metrics Array
Metrics Entries are 32 Bytes Each. Each entry has the following structure:
* Offset 0 - Length 4 - Start Time in Milliseconds - Unsigned 32-bit Integer
* Offset 4 - Length 4 - Duration in Milliseconds - Unsigned 32-bit Integer
* Offset 8 - Length 4 - Average Duration in Milliseconds - Unsigned 32-bit Integer
* Offset 12 - Length 4 - Filename String Offset relative from the start of Section C - Unsigned 32-bit Integer 
* Offset 16 - Length 4 - Number of Unicode Characters in Filename STring - Unsigned 32-bit Integer
* Offset 20 - Length 4 - Unknown Flags
* Offset 24 - Length 8 - NTFS File Reference

## Section B - Trace Chains Array
Trace Chains entries are 12 Bytes each and have the following structure:
* Offset 0 - Length 4 - Next array entry index
* Offset 4 - Length 4 - Total block load count
* Offset 8 - Length 1 - Unknown
* Offset 9 - Length 1 - Sample duration in milliseconds (?)
* Offset 10 - Length 2 - Unknown

## Section C - Filename Strings Array
Section C consists of an array of Strings in Unicode. Each entry can be carved using the Filename String Offset in Section A, and the Filename Length in Unicode Characters from Section A.

## Section D - Volume Information Array
Volume Information entries are 104 bytes in size with the following structure:
* Offset 0 - Length 4 - Offset to Volume Device Path - Unsigned 32-bit Integer
* Offset 4 - Length 4 - Length of Volume Device Path - Unsigned 32-bit Integer
* Offset 8 - Length 8 - Volume Creation Time
* Offset 16 - Length 4 - Volume Serial Number - Hexadecimal
* Offset 20 - Length 4 - Offset to Subsection E - Unsigned 32-bit Integer
* Offset 24 - Length 4 - Length of Subsection E - Unsigned 32-bit Integer
* Offset 28 - Length 4 - Offset to Subsection F - Unsigned 32-bit Integer
* Offset 32 - Length 4 - Number of strings in Subsection F - Unsigned 32-bit Integer
* Offset 36 - Length 4 - Unknown
* Offset 40 - Length 28 - Unknown
* Offset 68 - Length 4 - Unknown
* Offset 72 - Length 28 - Unknown
* Offset 100 - Length 4 - Unknown

### Subsection E - NTFS File References

### Subsection F - Directory Strings Array
Directory string entries have the following structure:
* Offset 0 - Length 2 - Number of Unicode Characters in String - Unsigned 16-bit Integer
* Offset 2 - Length (Character Count * 2) - Directory Name in Unicode

# Windows 8