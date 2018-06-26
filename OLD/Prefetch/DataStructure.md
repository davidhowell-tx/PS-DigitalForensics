
# Windows Prefetch Data Structures


# Windows XP

## File Header - 84 Bytes
| Offset | Length | Value    | Value Format            | Notes |
| ------ | ------ | -------- | ----------------------- | ----- |
| 0      | 4      | 11000000 | Hexadecimal             | Format Version |
| 4      | 4      | SCCA     | ASCII                   | Signature |
| 8      | 4      | 0F000000 | Hexadecimal             | Unknown Purpose |
| 12     | 4      |          | Unsigned 32-bit Integer | Prefetch File Size |
| 16     | 60     |          | Unicode String          | Name of Executable - 29 characters with U+0000 end-of-string character |
| 76     | 4      |          | Hexadecimal String      | Prefetch Hash |
| 80     | 4      |          |                         | Unknown (flags?) |

## File Information - 68 Bytes
| Offset | Length | Value Format                       | Notes |
| ------ | ------ | ---------------------------------- | ----- |
| 84     | 4      | Unsigned 32-bit Integer            | Offset from start of file to Metrics Array |
| 88     | 4      | Unsigned 32-bit Integer            | Number of entries in Metrics Array |
| 92     | 4      | Unsigned 32-bit Integer            | Offset from start of file to Trace Chains Array |
| 96     | 4      | Unsigned 32-bit Integer            | Number of entries in Trace Chains Array |
| 100    | 4      | Unsigned 32-bit Integer            | Offset from start of file to Filename Strings Array |
| 104    | 4      | Unsigned 32-bit Integer            | Length of Filename Strings Array |
| 108    | 4      | Unsigned 32-bit Integer            | Offset from start of file to Volume Information Array |
| 112    | 4      | Unsigned 32-bit Integer            | Number of entries in Volume Information Array |
| 116    | 4      | Unsigned 32-bit Integer            | Length of Volume Information Array |
| 120    | 8      | Unsigned 64-bit Integer Epoch Time | Last Execution Time |
| 128    | 16     |                                    | Unknown |
| 144    | 4      | Unsigned 32-bit Integer            | Execution Count |
| 148    | 4      |                                    | Unknown |

## Metrics Array
Metrics Entry Records are 20 bytes each. Offsets are shown from the start of the metrics entry.

| Offset | Length | Value Format            | Notes  |
| ------ | ------ | ----------------------- | ------ |
| 0      | 4      |                         | Unknown |
| 4      | 4      |                         | Unknown |
| 8      | 4      | Unsigned 32-bit Integer | Filename String Offset |
| 12     | 4      | Unsigned 32-bit Integer | Number of Unicode Characters in Filename |
| 16     | 4      |                         | Unknown |

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
| 0      | 4      | Unsigned 32-bit Integer            | Offset from start of Volume Information Array to volume device path |
| 4      | 4      | Unsigned 32-bit Integer            | Length of volume device path in Unicode characters |
| 8      | 8      | Unsigned 64-bit Integer Epoch time | Volume Creation Time |
| 16     | 4      | Hexadecimal String                 | Volume serial number |
| 20     | 4      | Unsigned 32-bit Integer            | Offset from start of Volume Information Array to NTFS File References Array |
| 24     | 4      | Unsigned 32-bit Integer            | Number of entries in NTFS File References Array |
| 28     | 4      | Unsigned 32-bit Integer            | Offset from start of Volume Information Array to Directory Strings Array |
| 32     | 4      | Unsigned 32-bit Integer            | Number of strings in Directory Strings Array |
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

# Windows Vista / 7

## File Header - 84 Bytes
| Offset | Length | Value    | Value Format            | Notes |
| ------ | ------ | -------- | ----------------------- | ----- |
| 0      | 4      | 11000000 | Hexadecimal             | Format Version |
| 4      | 4      | SCCA     | ASCII                   | Signature |
| 8      | 4      | 0F000000 | Hexadecimal             | Unknown Purpose |
| 12     | 4      |          | Unsigned 32-bit Integer | Prefetch File Size |
| 16     | 60     |          | Unicode String          | Name of Executable - 29 characters with U+0000 end-of-string character |
| 76     | 4      |          | Hexadecimal String      | Prefetch Hash |
| 80     | 4      |          |                         | Unknown (flags?) |

## File Information - 156 Bytes
| Offset | Length | Value Format                       | Notes |
| ------ | ------ | ---------------------------------- | ----- |
| 84     | 4      | Unsigned 32-bit Integer            | Offset from start of file to Metrics Array |
| 88     | 4      | Unsigned 32-bit Integer            | Number of entries in Metrics Array |
| 92     | 4      | Unsigned 32-bit Integer            | Offset from start of file to Trace Chains Array |
| 96     | 4      | Unsigned 32-bit Integer            | Number of entries in Trace Chains Array |
| 100    | 4      | Unsigned 32-bit Integer            | Offset from start of file to Filename Strings Array |
| 104    | 4      | Unsigned 32-bit Integer            | Length of Filename Strings Array |
| 108    | 4      | Unsigned 32-bit Integer            | Offset from start of file to Volume Information Array |
| 112    | 4      | Unsigned 32-bit Integer            | Number of entries in Volume Information Array |
| 116    | 4      | Unsigned 32-bit Integer            | Length of Volume Information Array |
| 120    | 8      |                                    | Unknown |
| 128    | 8      | Unsigned 64-bit Integer Epoch Time | Last Execution Time |
| 136    | 16     |                                    | Unknown |
| 152    | 4      | Unsigned 32-bit Integer            | Execution Count |
| 156    | 80     |                                    | Unknown |
| 

## Metrics Array
Metrics Entry Records are 32 bytes each. Offsets are shown from the start of the metrics entry.

| Offset | Length | Value Format            | Notes  |
| ------ | ------ | ----------------------- | ------ |
| 0      | 4      |                         | Unknown |
| 4      | 4      |                         | Unknown |
| 8      | 4      |                         | Unknown |
| 12     | 4      | Unsigned 32-bit Integer | Filename String Offset |
| 16     | 4      | Unsigned 32-bit Integer | Number of Unicode Characters in Filename |
| 20     | 4      |                         | Unknown |
| 24     | 8      |                         | NTFS File Reference of the Filename |

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

Volume Information entries are 104 bytes each. Offsets are shown from the start of the Volume Information entry record.

| Offset | Length | Value Format                       | Notes |
| ------ | ------ | ---------------------------------- | ----- |
| 0      | 4      | Unsigned 32-bit Integer            | Offset from start of Volume Information Array to volume device path |
| 4      | 4      | Unsigned 32-bit Integer            | Length of volume device path in Unicode characters |
| 8      | 8      | Unsigned 64-bit Integer Epoch time | Volume Creation Time |
| 16     | 4      | Hexadecimal String                 | Volume serial number |
| 20     | 4      | Unsigned 32-bit Integer            | Offset from start of Volume Information Array to NTFS File References Array |
| 24     | 4      | Unsigned 32-bit Integer            | Number of entries in NTFS File References Array |
| 28     | 4      | Unsigned 32-bit Integer            | Offset from start of Volume Information Array to Directory Strings Array |
| 32     | 4      | Unsigned 32-bit Integer            | Number of strings in Directory Strings Array |
| 36     | 4      |                                    | Unknown |
| 40     | 28     |                                    | Unknown |
| 68     | 4      |                                    | Unknown |
| 72     | 28     |                                    | Unknown |
| 100    | 4      |                                    | Unknown |

### NTFS File Reference Array
NTFS File reference entries vary in size.

| Offset | Length | Notes |
| ------ | ------ | ----- |
| 0      | 4      | Unknown |
| 4      | 4      | Number of file reference entries |
| 8      |        | Array of file references |

### Directory Strings Array
An array of Unicode directory strings associated with files accessed by the executable. The number of string entries is stored in the Volume Information array.

Each directory string entry has the following structure:

| Offset | Length | Value Format            | Notes |
| ------ | ------ | ----------------------- | ----- |
| 0      | 2      | Unsigned 16-bit Integer | Length of directory string in Unicode characters |
| 2      |        | Unicode string          | Directory Name |
|        | 2      | Unicode                 | U+0000 end-of-string character |


# Windows 8

## File Header - 84 Bytes
| Offset | Length | Value    | Value Format            | Notes |
| ------ | ------ | -------- | ----------------------- | ----- |
| 0      | 4      | 11000000 | Hexadecimal             | Format Version |
| 4      | 4      | SCCA     | ASCII                   | Signature |
| 8      | 4      | 0F000000 | Hexadecimal             | Unknown Purpose |
| 12     | 4      |          | Unsigned 32-bit Integer | Prefetch File Size |
| 16     | 60     |          | Unicode String          | Name of Executable - 29 characters with U+0000 end-of-string character |
| 76     | 4      |          | Hexadecimal String      | Prefetch Hash |
| 80     | 4      |          |                         | Unknown (flags?) |

## File Information - 220 Bytes
| Offset | Length | Value Format                       | Notes |
| ------ | ------ | ---------------------------------- | ----- |
| 84     | 4      | Unsigned 32-bit Integer            | Offset from start of file to Metrics Array |
| 88     | 4      | Unsigned 32-bit Integer            | Number of entries in Metrics Array |
| 92     | 4      | Unsigned 32-bit Integer            | Offset from start of file to Trace Chains Array |
| 96     | 4      | Unsigned 32-bit Integer            | Number of entries in Trace Chains Array |
| 100    | 4      | Unsigned 32-bit Integer            | Offset from start of file to Filename Strings Array |
| 104    | 4      | Unsigned 32-bit Integer            | Length of Filename Strings Array |
| 108    | 4      | Unsigned 32-bit Integer            | Offset from start of file to Volume Information Array |
| 112    | 4      | Unsigned 32-bit Integer            | Number of entries in Volume Information Array |
| 116    | 4      | Unsigned 32-bit Integer            | Length of Volume Information Array |
| 120    | 8      |                                    | Unknown |
| 128    | 8      | Unsigned 64-bit Integer Epoch Time | Last Execution Time |
| 136    | 8      | Unsigned 64-bit Integer Epoch Time | 2nd Last Execution Time |
| 144    | 8      | Unsigned 64-bit Integer Epoch Time | 3rd Last Execution Time |
| 152    | 8      | Unsigned 64-bit Integer Epoch Time | 4th Last Execution Time |
| 160    | 8      | Unsigned 64-bit Integer Epoch Time | 5th Last Execution Time |
| 168    | 8      | Unsigned 64-bit Integer Epoch Time | 6th Last Execution Time |
| 176    | 8      | Unsigned 64-bit Integer Epoch Time | 7th Last Execution Time |
| 184    | 8      | Unsigned 64-bit Integer Epoch Time | 8th Last Execution Time |
| 192    | 16     |                                    | Unknown |
| 208    | 4      | Unsigned 32-bit Integer            | Execution Count |
| 212    | 4      |                                    | Unknown |
| 216    | 4      |                                    | Unknown |
| 220    | 84     |                                    | Unknown |

## Metrics Array
Metrics Entry Records are 32 bytes each. Offsets are shown from the start of the metrics entry.

| Offset | Length | Value Format            | Notes  |
| ------ | ------ | ----------------------- | ------ |
| 0      | 4      |                         | Unknown |
| 4      | 4      |                         | Unknown |
| 8      | 4      |                         | Unknown |
| 12     | 4      | Unsigned 32-bit Integer | Filename String Offset |
| 16     | 4      | Unsigned 32-bit Integer | Number of Unicode Characters in Filename |
| 20     | 4      |                         | Unknown |
| 24     | 8      |                         | NTFS File Reference of the Filename |

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

Volume Information entries are 104 bytes each. Offsets are shown from the start of the Volume Information entry record.

| Offset | Length | Value Format                       | Notes |
| ------ | ------ | ---------------------------------- | ----- |
| 0      | 4      | Unsigned 32-bit Integer            | Offset from start of Volume Information Array to volume device path |
| 4      | 4      | Unsigned 32-bit Integer            | Length of volume device path in Unicode characters |
| 8      | 8      | Unsigned 64-bit Integer Epoch time | Volume Creation Time |
| 16     | 4      | Hexadecimal String                 | Volume serial number |
| 20     | 4      | Unsigned 32-bit Integer            | Offset from start of Volume Information Array to NTFS File References Array |
| 24     | 4      | Unsigned 32-bit Integer            | Number of entries in NTFS File References Array |
| 28     | 4      | Unsigned 32-bit Integer            | Offset from start of Volume Information Array to Directory Strings Array |
| 32     | 4      | Unsigned 32-bit Integer            | Number of strings in Directory Strings Array |
| 36     | 4      |                                    | Unknown |
| 40     | 28     |                                    | Unknown |
| 68     | 4      |                                    | Unknown |
| 72     | 28     |                                    | Unknown |
| 100    | 4      |                                    | Unknown |

### NTFS File Reference Array
NTFS File reference entries vary in size.

| Offset | Length | Notes |
| ------ | ------ | ----- |
| 0      | 4      | Unknown |
| 4      | 4      | Number of file reference entries |
| 8      |        | Array of file references |

### Directory Strings Array
An array of Unicode directory strings associated with files accessed by the executable. The number of string entries is stored in the Volume Information array.

Each directory string entry has the following structure:

| Offset | Length | Value Format            | Notes |
| ------ | ------ | ----------------------- | ----- |
| 0      | 2      | Unsigned 16-bit Integer | Length of directory string in Unicode characters |
| 2      |        | Unicode string          | Directory Name |
|        | 2      | Unicode                 | U+0000 end-of-string character |


# Windows 10

## File Header - 84 Bytes
| Offset | Length | Value    | Value Format            | Notes |
| ------ | ------ | -------- | ----------------------- | ----- |
| 0      | 4      | 11000000 | Hexadecimal             | Format Version |
| 4      | 4      | SCCA     | ASCII                   | Signature |
| 8      | 4      | 0F000000 | Hexadecimal             | Unknown Purpose |
| 12     | 4      |          | Unsigned 32-bit Integer | Prefetch File Size |
| 16     | 60     |          | Unicode String          | Name of Executable - 29 characters with U+0000 end-of-string character |
| 76     | 4      |          | Hexadecimal String      | Prefetch Hash |
| 80     | 4      |          |                         | Unknown (flags?) |

## File Information - 224 Bytes
| Offset | Length | Value Format                       | Notes |
| ------ | ------ | ---------------------------------- | ----- |
| 84     | 4      | Unsigned 32-bit Integer            | Offset from start of file to Metrics Array |
| 88     | 4      | Unsigned 32-bit Integer            | Number of entries in Metrics Array |
| 92     | 4      | Unsigned 32-bit Integer            | Offset from start of file to Trace Chains Array |
| 96     | 4      | Unsigned 32-bit Integer            | Number of entries in Trace Chains Array |
| 100    | 4      | Unsigned 32-bit Integer            | Offset from start of file to Filename Strings Array |
| 104    | 4      | Unsigned 32-bit Integer            | Length of Filename Strings Array |
| 108    | 4      | Unsigned 32-bit Integer            | Offset from start of file to Volume Information Array |
| 112    | 4      | Unsigned 32-bit Integer            | Number of entries in Volume Information Array |
| 116    | 4      | Unsigned 32-bit Integer            | Length of Volume Information Array |
| 120    | 8      |                                    | Unknown |
| 128    | 8      | Unsigned 64-bit Integer Epoch Time | Last Execution Time |
| 136    | 8      | Unsigned 64-bit Integer Epoch Time | 2nd Last Execution Time |
| 144    | 8      | Unsigned 64-bit Integer Epoch Time | 3rd Last Execution Time |
| 152    | 8      | Unsigned 64-bit Integer Epoch Time | 4th Last Execution Time |
| 160    | 8      | Unsigned 64-bit Integer Epoch Time | 5th Last Execution Time |
| 168    | 8      | Unsigned 64-bit Integer Epoch Time | 6th Last Execution Time |
| 176    | 8      | Unsigned 64-bit Integer Epoch Time | 7th Last Execution Time |
| 184    | 8      | Unsigned 64-bit Integer Epoch Time | 8th Last Execution Time |
| 192    | 16     |                                    | Unknown |
| 208    | 4      | Unsigned 32-bit Integer            | Execution Count |
| 212    | 4      |                                    | Unknown |
| 216    | 4      |                                    | Unknown |
| 220    | 88     |                                    | Unknown |

## Metrics Array
Metrics Entry Records are 32 bytes each. Offsets are shown from the start of the metrics entry.

| Offset | Length | Value Format            | Notes  |
| ------ | ------ | ----------------------- | ------ |
| 0      | 4      |                         | Unknown |
| 4      | 4      |                         | Unknown |
| 8      | 4      |                         | Unknown |
| 12     | 4      | Unsigned 32-bit Integer | Filename String Offset |
| 16     | 4      | Unsigned 32-bit Integer | Number of Unicode Characters in Filename |
| 20     | 4      |                         | Unknown |
| 24     | 8      |                         | NTFS File Reference of the Filename |

## Trace Chains Array
Trace Chains Entry Records are 8 bytes each. Offsets are shown from the start of the Trace Chains entry record.

| Offset | Length | Value Format | Notes |
| ------ | ------ | ------------ | ----- |
| 0      | 4      |              | Total block load count |
| 4      | 1      |              | Unknown |
| 5      | 1      |              | Unknown |
| 6      | 2      |              | Unknown (Sample duration in milliseconds?) |

## Filename Strings Array
Filename Strings array contains Unicode Filename Strings terminated by the U+0000 end-of-string character. The offset of each string is recorded in the Metrics Array recorded as the offset from the start of the Filename Strings array. The length of each string in Unicode character is also recorded in the Metrics array.

## Volume Information Array
Each volume referenced in the Filename Strings array will also contain an entry in the Volume Information array. 
Each Volume Information array contains information about the volume as well as an NTFS file references array, and a directory strings array.

Volume Information entries are 96 bytes each. Offsets are shown from the start of the Volume Information entry record.

| Offset | Length | Value Format                       | Notes |
| ------ | ------ | ---------------------------------- | ----- |
| 0      | 4      | Unsigned 32-bit Integer            | Offset from start of Volume Information Array to volume device path |
| 4      | 4      | Unsigned 32-bit Integer            | Length of volume device path in Unicode characters |
| 8      | 8      | Unsigned 64-bit Integer Epoch time | Volume Creation Time |
| 16     | 4      | Hexadecimal String                 | Volume serial number |
| 20     | 4      | Unsigned 32-bit Integer            | Offset from start of Volume Information Array to NTFS File References Array |
| 24     | 4      | Unsigned 32-bit Integer            | Number of entries in NTFS File References Array |
| 28     | 4      | Unsigned 32-bit Integer            | Offset from start of Volume Information Array to Directory Strings Array |
| 32     | 4      | Unsigned 32-bit Integer            | Number of strings in Directory Strings Array |
| 36     | 4      |                                    | Unknown |
| 40     | 24     |                                    | Unknown |
| 68     | 4      |                                    | Unknown |
| 72     | 24     |                                    | Unknown |
| 100    | 4      |                                    | Unknown |

### NTFS File Reference Array
NTFS File reference entries vary in size.

| Offset | Length | Notes |
| ------ | ------ | ----- |
| 0      | 4      | Unknown |
| 4      | 4      | Number of file reference entries |
| 8      |        | Array of file references |

### Directory Strings Array
An array of Unicode directory strings associated with files accessed by the executable. The number of string entries is stored in the Volume Information array.

Each directory string entry has the following structure:

| Offset | Length | Value Format            | Notes |
| ------ | ------ | ----------------------- | ----- |
| 0      | 2      | Unsigned 16-bit Integer | Length of directory string in Unicode characters |
| 2      |        | Unicode string          | Directory Name |
|        | 2      | Unicode                 | U+0000 end-of-string character |
