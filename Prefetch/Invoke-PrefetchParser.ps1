<#
.SYNOPSIS
	Parses the data within a Prefetch file (.pf)

.NOTES
	Author: David Howell
	Last Modified: 11/24/2015
	
	Info regarding Prefetch data structures was pulled from the following articles:
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
			$TempObject.LastExecutionTime = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
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