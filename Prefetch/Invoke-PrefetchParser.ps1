<#
.SYNOPSIS
	Parses the data within a Prefetch file (.pf)

.NOTES
	Author: David Howell
	Last Modified:12/18/2015
	
	Info regarding Prefetch data structures was pulled from the following articles:
	http://www.forensicswiki.org/wiki/Windows_Prefetch_File_Format
	Thanks to Yogesh Khatri for this info.
	http://www.swiftforensics.com/2010/04/the-windows-prefetchfile.html
	http://www.swiftforensics.com/2013/10/windows-prefetch-pf-files.html
#>

[CmdletBinding()]Param(
	[Parameter(Mandatory=$True)][String]$FilePath
)

$ASCIIEncoding = New-Object System.Text.ASCIIEncoding
$UnicodeEncoding = New-Object System.Text.UnicodeEncoding

$PrefetchArray = @()

if (Test-Path -Path $FilePath) {
	# Open a FileStream to read the file, and a BinaryReader so we can read chunks and parse the data
	$FileStream = New-Object System.IO.FileStream -ArgumentList ($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
	$BinReader = New-Object System.IO.BinaryReader $FileStream
	
	# First 4 Bytes - Version Indicator
	$Version = [System.BitConverter]::ToString($BinReader.ReadBytes(4)) -replace "-",""
	
	# Next 8 Bytes are "SCCA" Signature, and 4 Bytes for unknown purpose either 0x0F000000 for WinXP or 0x11000000 for Win7/8
	[System.BitConverter]::ToString($BinReader.ReadBytes(8)) -replace "-","" | Out-Null
	
	switch ($Version) {
		# Windows XP Structure
		"11000000" {
			# Create a Custom Object to store prefetch info
			$TempObject = "" | Select-Object -Property Name, LastExecutionTime
			
			$TempObject | Add-Member -MemberType NoteProperty -Name "PrefetchSize" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
			$TempObject.Name = $UnicodeEncoding.GetString($BinReader.ReadBytes(60))
			$TempObject.Hash = [System.BitConverter]::ToString($BinReader.ReadBytes(4)) -replace "-",""
			$FileStream.Position = 100
			$TempObject | Add-Member -MemberType NoteProperty -Name "FilePathsOffset" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
			$TempObject | Add-Member -MemberType NoteProperty -Name "FilePathsLength" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
			$TempObject | Add-Member -MemberType NoteProperty -Name "VolumeInfoOffset" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
			$TempObject | Add-Member -MemberType NoteProperty -Name "VolumeInfoCount" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
			$TempObject | Add-Member -MemberType NoteProperty -Name "VolumeInfoSize" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
			$BinReader.ReadBytes(8) | Out-Null
			$TempObject.LastExecutionTime = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
			
			# Parse File Names
			$FileStream.Position = $TempObject.FilePathsOffset
			$FilePathsBlob = $UnicodeEncoding.GetString($BinReader.ReadBytes($TempObject.FilePathsLength)) -split "\\DEVICE\\" | Where-Object { $_ }
			for ($k=0; $k -lt $FilePathsBlob.Count; $k++) {
				$TempObject | Add-Member -MemberType NoteProperty -Name "FilePathsBlob_File$($k)" -Value $FilePathsBlob[$k]
			}
			
			$FileStream.Position = $TempObject.VolumeInfoOffset
			for ($i=1; $i -le $TempObject.VolumeInfoCount; $i++) {
				# Parse Volume Info
				$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_PathOffset" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
				$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_PathLength" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
				$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_CreationTime" -Value ([DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G"))
				$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_SerialNumber" -Value ([System.BitConverter]::ToString($BinReader.ReadBytes(4),0) -replace "-","")
				$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_OffsetToBlob1" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
				$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_LengthOfBlob1" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
				$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_OffsetToFolderPaths" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
				$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_NumberOfFolderPaths" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
				$FileStream.Position = ($FileStream.Position + $($TempObject."Volume$($i)_PathOffset") - 36)
				$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_Path" -Value ($UnicodeEncoding.GetString($BinReader.ReadBytes($($TempObject."Volume$($i)_PathLength") * 2)))
				$BinReader.ReadBytes(($($TempObject."Volume$($i)_OffsetToBlob1") - $($TempObject."Volume$($i)_PathOffset") - ($($TempObject."Volume$($i)_PathLength") * 2))) | Out-Null
				$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_Blob1" -Value ($ASCIIEncoding.GetString($BinReader.ReadBytes($($TempObject."Volume$($i)_LengthOfBlob1"))))
				
				for ($j=1; $j -le $($TempObject."Volume$($i)_NumberOfFolderPaths"); $j++) {
					$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_FolderPath$($j)Length" -Value ([System.BitConverter]::ToUInt16($BinReader.ReadBytes(2),0))
					$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_FolderPath$($j)" -Value ($UnicodeEncoding.GetString($BinReader.ReadBytes($($TempObject."Volume$($i)_FolderPath$($j)Length") * 2)))
					$BinReader.ReadBytes(2) | Out-Null
				}
			}
		}
		
		# Windows 7 Structure
		"17000000" {
			# Create a Custom Object to store prefetch info
			$TempObject = "" | Select-Object -Property Name, Hash, LastExecutionTime, NumberOfExecutions
			
			$TempObject | Add-Member -MemberType NoteProperty -Name "PrefetchSize" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
			$TempObject.Name = $UnicodeEncoding.GetString($BinReader.ReadBytes(60))
			$TempObject.Hash = [System.BitConverter]::ToString($BinReader.ReadBytes(4)) -replace "-",""
			
			# Unknown
			$BinReader.ReadBytes(4) | Out-Null
			# Offset to Section A (Metrics Array)
			$MetricsArrayOffset = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
			# Number of Entries in Section A (Metrics Array)
			$MetricsArrayEntries  = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
			# Offset to Section B (Trace Chains Array)
			$BinReader.ReadBytes(4) | Out-Null
			# Number of Entries in Section B (Trace Chains Array)
			$BinReader.ReadBytes(4) | Out-Null
			# Offset to Section C (File Names Array)
			$FilenamesArrayOffset = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
			# Length of Section C (File Names Array)
			$FilenamesArrayLength = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
			# Offset to Section D (Volume Information Array)
			$VolumeInfoArrayOffset = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
			# Number of Entries in Section D (Volume Information Array)
			$VolumeInfoArrayEntries = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
			# Length of Section D (Volume Information Array)
			$VolumeInfoArrayLength = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
			# Unknown
			$BinReader.ReadBytes(8) | Out-Null
			# Last Execution Time
			$TempObject.LastExecutionTime = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
			# Unknown
			$BinReader.ReadBytes(16) | Out-Null
			# Execution Count
			$TempObject.NumberOfExecutions = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
			# Unknown
			$BinReader.ReadBytes(4) | Out-Null
			# Unknown
			$BinReader.ReadBytes(80) | Out-Null
			
			# Parse Metrics (Section A) and the associated File Names
			for ($i=1; $i -le $MetricsArrayEntries; $i++) {
				# Start Time in Milliseconds
				$BinReader.ReadBytes(4) | Out-Null
				# Duration in Milliseconds
				$BinReader.ReadBytes(4) | Out-Null
				# Average Duration in Milliseconds
				$BinReader.ReadBytes(4) | Out-Null
				
				$FileNameOffset = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
				$FileNameLength = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
				
				# Unknown Flags
				$BinReader.ReadBytes(4) | Out-Null
				# NTFS File Reference
				$BinReader.ReadBytes(8) | Out-Null
				
				# Read the File Name out of Section C using the Offset and Length we just parsed
				
				# Store Current Location in Section A so we can come back
				$CurrentLocation = $FileStream.Position
				# Change File Stream Position to File Name Offset
				$FileStream.Position = $FilenamesArrayOffset + $FileNameOffset
				# Read the File Name
				$TempObject | Add-Member -MemberType NoteProperty -Name "Filename$($i)" -Value ($UnicodeEncoding.GetString($BinReader.ReadBytes($FileNameLength)))
				# Change back to location in Section A
				$FileStream.Position = $CurrentLocation
				
				Remove-Variable -Name FileNameOffset
				Remove-Variable -Name FileNameLength
				Remove-Variable -Name CurrentLocation
			}
			Remove-Variable -Name i
			
			# Parse Section D (Volume Information)
			$FileStream.Position = $VolumeInfoArrayOffset
			for ($i=1; $i -le $VolumeInfoArrayEntries; $i++) {
				$VolumePathOffset = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
				$VolumePathLength = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
				
				$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_CreationTime" -Value ([DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G"))
				$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_SerialNumber" -Value ([System.BitConverter]::ToString($BinReader.ReadBytes(4),0) -replace "-","")
				
				# Offset to Subsection E (NTFS File References)
				[System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0) | Out-Null
				# Length of Subsection E (NTFS File References)
				[System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0) | Out-Null
				
				$DirectoryStringsArrayOffset = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
				$DirectoryStringsArrayEntries = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
				
				$BinReader.ReadBytes(4) | Out-Null
				$BinReader.ReadBytes(28) | Out-Null
				$BinReader.ReadBytes(4) | Out-Null
				$BinReader.ReadBytes(28) | Out-Null
				$BinReader.ReadBytes(4) | Out-Null

				# Read the Volume Path String
				$FileStream.Position = $VolumeInfoArrayOffset + $VolumePathOffset
				$TempObject | Add-Member -MemberType NoteProperty -Name "Voluem$($i)_Path" -Value ($UnicodeEncoding.GetString($BinReader.ReadBytes($VolumePathLength * 2)))
				
				# Move to the Directory Strings Array and read the strings
				$FileStream.Position = $VolumeInfoArrayOffset + $DirectoryStringsArrayOffset
				for ($j=1; $j -le $DirectoryStringsArrayEntries; $j++) {
					$DirectoryStringLength = [System.BitConverter]::ToUInt16($BinReader.ReadBytes(2),0)
					$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_Directory$($j)" -Value $UnicodeEncoding.GetString($BinReader.ReadBytes($DirectoryStringLength * 2 + 2))
					Remove-Variable -Name DirectoryStringLength
				}
				Remove-Variable -Name VolumePathOffset
				Remove-Variable -Name VolumePathLength
				Remove-Variable -Name DirectoryStringsArrayOffset
				Remove-Variable -Name DirectoryStringsArrayEntries
				Remove-Variable -Name j
			}
		}
		
		# Windows 8 Structure
		"1A000000" {
			# Create a Custom Object to store prefetch info
			$TempObject = "" | Select-Object -Property Name, Hash, LastExecutionTime_1, LastExecutionTime_2, LastExecutionTime_3, LastExecutionTime_4, LastExecutionTime_5, LastExecutionTime_6, LastExecutionTime_7, LastExecutionTime_8
			
			$TempObject | Add-Member -MemberType NoteProperty -Name "PrefetchSize" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
			$TempObject.Name = $UnicodeEncoding.GetString($BinReader.ReadBytes(60))
			$TempObject.Hash = [System.BitConverter]::ToString($BinReader.ReadBytes(4)) -replace "-",""
			$BinReader.ReadBytes(8) | Out-Null
			$TempObject | Add-Member -MemberType NoteProperty -Name "NumberOfFilePaths" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
			$BinReader.ReadBytes(8) | Out-Null
			$TempObject | Add-Member -MemberType NoteProperty -Name "FilePathsOffset" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
			$TempObject | Add-Member -MemberType NoteProperty -Name "FilePathsLength" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
			$TempObject | Add-Member -MemberType NoteProperty -Name "VolumeInfoOffset" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
			$TempObject | Add-Member -MemberType NoteProperty -Name "VolumeInfoCount" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
			$TempObject | Add-Member -MemberType NoteProperty -Name "VolumeInfoSize" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
			$BinReader.ReadBytes(8) | Out-Null
			$TempObject.LastExecutionTime_1 = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
			$TempObject.LastExecutionTime_2 = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
			$TempObject.LastExecutionTime_3 = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
			$TempObject.LastExecutionTime_4 = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
			$TempObject.LastExecutionTime_5 = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
			$TempObject.LastExecutionTime_6 = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
			$TempObject.LastExecutionTime_7 = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
			$TempObject.LastExecutionTime_8 = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
			$BinReader.ReadBytes(16) | Out-Null
			$TempObject | Add-Member -MemberType NoteProperty -Name "NumberOfExecutions" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
			
			# Parse File Names
			$FileStream.Position = $TempObject.FilePathsOffset
			$FilePathsBlob = $UnicodeEncoding.GetString($BinReader.ReadBytes($TempObject.FilePathsLength)) -split "\\DEVICE\\" | Where-Object { $_ }
			for ($k=0; $k -lt $FilePathsBlob.Count; $k++) {
				$TempObject | Add-Member -MemberType NoteProperty -Name "FilePathsBlob_File$($k)" -Value $FilePathsBlob[$k]
			}
			
			$FileStream.Position = $TempObject.VolumeInfoOffset
			for ($i=1; $i -le $TempObject.VolumeInfoCount; $i++) {
				# Parse Volume Info
				$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_PathOffset" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
				$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_PathLength" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
				$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_CreationTime" -Value ([DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G"))
				$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_SerialNumber" -Value ([System.BitConverter]::ToString($BinReader.ReadBytes(4),0) -replace "-","")
				$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_OffsetToBlob1" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
				$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_LengthOfBlob1" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
				$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_OffsetToFolderPaths" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
				$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_NumberOfFolderPaths" -Value ([System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0))
				$FileStream.Position = ($FileStream.Position + $($TempObject."Volume$($i)_PathOffset") - 36)
				$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_Path" -Value ($UnicodeEncoding.GetString($BinReader.ReadBytes($($TempObject."Volume$($i)_PathLength") * 2)))
				$BinReader.ReadBytes(($($TempObject."Volume$($i)_OffsetToBlob1") - $($TempObject."Volume$($i)_PathOffset") - ($($TempObject."Volume$($i)_PathLength") * 2))) | Out-Null
				$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_Blob1" -Value ($ASCIIEncoding.GetString($BinReader.ReadBytes($($TempObject."Volume$($i)_LengthOfBlob1"))))
				
				for ($j=1; $j -le $($TempObject."Volume$($i)_NumberOfFolderPaths"); $j++) {
					$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_FolderPath$($j)Length" -Value ([System.BitConverter]::ToUInt16($BinReader.ReadBytes(2),0))
					$TempObject | Add-Member -MemberType NoteProperty -Name "Volume$($i)_FolderPath$($j)" -Value ($UnicodeEncoding.GetString($BinReader.ReadBytes($($TempObject."Volume$($i)_FolderPath$($j)Length") * 2)))
					$BinReader.ReadBytes(2) | Out-Null
				}
			}
		}
		
		# Windows 10 Structure
		"1E000000" {
		
		}
		
		
	}
	
	$TempObject
}