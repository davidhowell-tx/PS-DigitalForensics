<#
.SYNOPSIS
	Invoke-AppCompatCacheParser.ps1 parses the Application Compatibility Cache, or Shim Cache, and returns the data in an easy to read format.

.PARAMETER Path
	Use this parameter to run against a .reg file export of the Shim Cache.

.EXAMPLE
	Invoke-AppCompatCacheParser.ps1

.EXAMPLE
	Invoke-AppCompatCacheParser.ps1 -Path C:\ShimCache\AppCompatCache.reg

.NOTES
    Author:  David Howell
    Last Updated: 12/25/2015
	
	Thanks to Mandiant's WhitePaper: https://dl.mandiant.com/EE/library/Whitepaper_ShimCacheParser.pdf
	Thanks to Harlan Carvey's Perl AppCompatCache.pl script: https://github.com/keydet89/RegRipper2.8/blob/master/plugins/appcompatcache.pl
	Thanks to Joachim Metz's documentation: https://github.com/libyal/winreg-kb/blob/master/documentation/Application%20Compatibility%20Cache%20key.asciidoc
#>

[CmdletBinding(DefaultParameterSetName='LocalHost')]
Param(
	[Parameter(Mandatory=$True,ParameterSetName='Path')]
	[ValidateNotNullOrEmpty()]
	[String]$Path
)

# Initialize Array to store our data
$EntryArray=@()
$AppCompatCache=$Null

switch($PSCmdlet.ParameterSetName) {
	"Path" {
		if (Test-Path -Path $Path) {
			# Get the Content of the .reg file, only return lines with Hexadecimal values on them, and remove the backslashes, spaces, and wording at the start
			$AppCompatCache = Get-Content -Path $Path | Select-String -Pattern "[A-F0-9][A-F0-9]," | ForEach-Object { $_ -replace "(\\|,|`"AppCompatCache`"=hex:|\s)","" }
			# Join all of the hexadecimal into one big string
			$AppCompatCache = $AppCompatCache -join ""
			# Convert the Hexadecimal string to a byte array
			$AppCompatCache = $AppCompatCache -split "(?<=\G\w{2})(?=\w{2})" | ForEach-Object { [System.Convert]::ToByte( $_, 16 ) }
			# Thanks to beefycode for that code snippet: http://www.beefycode.com/post/Convert-FromHex-PowerShell-Filter.aspx
		}
	}
	
	Default {
		if (!(Get-PSDrive -Name HKLM -PSProvider Registry)) {
			New-PSDrive -Name HKLM -PSProvider Registry -Root HKEY_LOCAL_MACHINE
		}
		# This command gets the current AppCompat Cache, and returns it in a Byte Array.
		if (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Session Manager\AppCompatCache\' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty AppCompatCache) {
			# This is the Windows 2003 and later location of AppCompatCache in the registry
			$AppCompatCache = Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Session Manager\AppCompatCache\' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty AppCompatCache
		} else {
			# If the normal area is not available, try the Windows XP location.
			# Note, this piece is untested as I don't have a Windows XP system to work with.
			$AppCompatCache = Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Session Manager\AppCompatibility\AppCompatCache' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty AppCompatCache
		}
	}
}

if ($AppCompatCache -ne $null) {

	# Initialize a Memory Stream and Binary Reader to scan through the Byte Array
	$MemoryStream = New-Object System.IO.MemoryStream(,$AppCompatCache)
	$BinReader = New-Object System.IO.BinaryReader $MemoryStream
	$UnicodeEncoding = New-Object System.Text.UnicodeEncoding
	$ASCIIEncoding = New-Object System.Text.ASCIIEncoding

	# The first 4 bytes of the AppCompatCache is a Header.  Lets parse that and use it to determine which format the cache is in.
	$Header = ([System.BitConverter]::ToString($BinReader.ReadBytes(4))) -replace "-",""

	switch ($Header) {
		# 0x30 - Windows 10
		"30000000" {
			# Finish Reading Header
			$BinReader.ReadBytes(32) | Out-Null
			$NumberOfEntries = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
			$BinReader.ReadBytes(8) | Out-Null
			
			# Complete loop to parse each entry
			for ($i=0; $i -lt $NumberOfEntries; $i++) {
				$TempObject = "" | Select-Object -Property FileName, LastModifiedTime, Data
				$TempObject | Add-Member -MemberType NoteProperty -Name "Tag" -Value ($ASCIIEncoding.GetString($BinReader.ReadBytes(4)))
				$BinReader.ReadBytes(4) | Out-Null
				$CacheEntrySize = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
				$NameLength = [System.BitConverter]::ToUInt16($BinReader.ReadBytes(2),0)
				# This probably needs to be NameLength * 2 if the length is the number of unicode characters - need to verify
				$TempObject.FileName = $UnicodeEncoding.GetString($BinReader.ReadBytes($NameLength))
				$TempObject.LastModifiedTime = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
				$DataLength = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
				$TempObject.Data = $ASCIIEncoding.GetString($BinReader.ReadBytes($DataLength))
				$EntryArray += $TempObject
			}
		}
	
		# 0x80 - Windows 8
		"80000000" {
			$Offset = [System.BitConverter]::ToUInt32($AppCompatCache[0..3],0)
			$Tag = [System.BitConverter]::ToString($AppCompatCache[$Offset..($Offset+3)],0) -replace "-",""
			
			if ($Tag -eq "30307473" -or $Tag -eq "31307473") {
				# 64-bit
				$MemoryStream.Position = ($Offset)
				
				# Complete loop to parse each entry
				while ($MemoryStream.Position -lt $MemoryStream.Length) {
					# I've noticed some random gaps of space in Windows 8 AppCompatCache
					# We need to verify the tag for each entry
					# If the tag isn't correct, read through until the next correct tag is found
					
					# First 4 Bytes is the Tag
					$EntryTag = [System.BitConverter]::ToString($BinReader.ReadBytes(4),0) -replace "-",""
					
					if ($EntryTag -eq "30307473" -or $EntryTag -eq "31307473") {
						# Skip 4 Bytes
						$BinReader.ReadBytes(4) | Out-Null
						$TempObject = "" | Select-Object -Property Name, Time
						$JMP = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
						$SZ = [System.BitConverter]::ToUInt16($BinReader.ReadBytes(2),0)
						$TempObject.Name = $UnicodeEncoding.GetString($BinReader.ReadBytes($SZ + 2))
						$BinReader.ReadBytes(8) | Out-Null
						$TempObject.Time = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
						$BinReader.ReadBytes(4) | Out-Null
						$TempObject
					} else {
						# We've found a gap of space that isn't an AppCompatCache Entry
						# Perform a loop to read 1 byte at a time until we find the tag 30307473 or 31307473 again
						$Exit = $False
						
						while ($Exit -ne $true) {
							$Byte1 = [System.BitConverter]::ToString($BinReader.ReadBytes(1),0) -replace "-",""
							if ($Byte1 -eq "30" -or $Byte1 -eq "31") {
								$Byte2 = [System.BitConverter]::ToString($BinReader.ReadBytes(1),0) -replace "-",""
								if ($Byte2 -eq "30") {
									$Byte3 = [System.BitConverter]::ToString($BinReader.ReadBytes(1),0) -replace "-",""
									if ($Byte3 -eq "74") {
										$Byte4 = [System.BitConverter]::ToString($BinReader.ReadBytes(1),0) -replace "-",""
										if ($Byte4 -eq "73") {
											# Verified a correct tag for a new entry
											# Scroll back 4 bytes and exit the scan loop
											$MemoryStream.Position = ($MemoryStream.Position - 4)
											$Exit = $True
										} else {
											$MemoryStream.Position = ($MemoryStream.Position - 3)
										}
									} else {
										$MemoryStream.Position = ($MemoryStream.Position - 2)
									}
								} else {
									$MemoryStream.Position = ($MemoryStream.Position - 1)
								}
							}
						}
					}
				}
				
			} elseif ($Tag -eq "726F7473") {
				# 32-bit
				
				$MemoryStream.Position = ($Offset + 8)
				
				# Complete loop to parse each entry
				while ($MemoryStream.Position -lt $MemoryStream.Length) {
					#Parse the metadata for the entry and add to a custom object
					$TempObject = "" | Select-Object -Property Name, Time
					
					$JMP = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
					$TempObject.Time = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
					$SZ = [System.BitConverter]::ToUInt16($BinReader.ReadBytes(2),0)
					$TempObject.Name = $UnicodeEncoding.GetString($BinReader.ReadBytes($SZ))
					$EntryArray += $TempObject
				}
			}
			$EntryArray | Select-Object -Property Name, Time
		}
	
		# BADC0FEE in Little Endian Hex - Windows 7 / Windows 2008 R2
		"EE0FDCBA" {
			# Number of Entries at Offset 4, Length of 4 bytes
			$NumberOfEntries = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
			# Move BinReader to the Offset 128 where the Entries begin
			$MemoryStream.Position=128
			
			# Get some baseline info about the 1st entry to determine if we're on 32-bit or 64-bit OS
			$Length = [System.BitConverter]::ToUInt16($BinReader.ReadBytes(2),0)
			$MaxLength = [System.BitConverter]::ToUInt16($BinReader.ReadBytes(2),0)
			$Padding = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
			
			# Move Binary Reader back to the start of the entries
			$MemoryStream.Position=128
			
			if (($MaxLength - $Length) -eq 2) {
				if ($Padding -eq 0) {
					# 64-bit Operating System
					
					# Use the Number of Entries it says are available and iterate through this loop that many times
					for ($i=0; $i -lt $NumberOfEntries; $i++) {
						# Parse the metadata for the entry and add to a custom object
						$TempObject = "" | Select-Object -Property Name, Length, MaxLength, Padding, Offset0, Offset1, Time, Flag0, Flag1
						$TempObject.Length = [System.BitConverter]::ToUInt16($BinReader.ReadBytes(2),0)
						$TempObject.MaxLength = [System.BitConverter]::ToUInt16($BinReader.ReadBytes(2),0)
						$TempObject.Padding = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
						$TempObject.Offset0 = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
						$TempObject.Offset1 = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
						# calculate the modified date/time in this QWORD
						$TempObject.Time = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
						$TempObject.Flag0 = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
						$TempObject.Flag1 = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
						# Use the Offset and the Length to read the File Name
						$TempObject.Name = ($UnicodeEncoding.GetString($AppCompatCache[$TempObject.Offset0..($TempObject.Offset0+$TempObject.Length-1)])) -replace "\\\?\?\\",""
						# Seek past the 16 Null Bytes at the end of the entry header
						# This is Blob Size and Blob Offset according to: https://dl.mandiant.com/EE/library/Whitepaper_ShimCacheParser.pdf
						$Nothing = $BinReader.ReadBytes(16)
						$EntryArray += $TempObject
					}
				} else {
					# 32-bit Operating System
					
					# Use the Number of Entries it says are available and iterate through this loop that many times
					for ($i=0; $i -lt $NumberOfEntries; $i++) {
						# Parse the metadata for the entry and add to a custom object
						$TempObject = "" | Select-Object -Property Name, Length, MaxLength, Offset, Time, Flag0, Flag1
						$TempObject.Length = [System.BitConverter]::ToUInt16($BinReader.ReadBytes(2),0)
						$TempObject.MaxLength = [System.BitConverter]::ToUInt16($BinReader.ReadBytes(2),0)
						$TempObject.Offset = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
						# calculate the modified date/time in this QWORD
						$TempObject.Time = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
						$TempObject.Flag0 = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
						$TempObject.Flag1 = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
						# Use the Offset and the Length to read the File Name
						$TempObject.Name = ($UnicodeEncoding.GetString($AppCompatCache[$TempObject.Offset0..($TempObject.Offset0+$TempObject.Length-1)])) -replace "\\\?\?\\",""
						# Seek past the 16 Null Bytes at the end of the entry header
						# This is Blob Size and Blob Offset according to: https://dl.mandiant.com/EE/library/Whitepaper_ShimCacheParser.pdf
						$Nothing = $BinReader.ReadBytes(16)
						$EntryArray += $TempObject
					}
					
				}
			}
			
			# Return a Table with the results.  I have to do this in the switch since not all OS versions will have the same interesting fields to return
			$EntryArray | Format-Table -AutoSize -Property Name, Time, Flag0, Flag1
		}
		
		# BADC0FFE in Little Endian Hex - Windows XP 64-bit, Windows Server 2003 through Windows Vista and Windows Server 2008
		"FE0FDCBA" {
		#### THIS AREA NEEDS WORK, TESTING, ETC.
		
			# Number of Entries at Offset 4, Length of 4 bytes
			$NumberOfEntries = [System.BitConverter]::ToUInt32($AppCompatCache[4..7],0)
			
			# Lets analyze the padding of the first entry to determine if we're on 32-bit or 64-bit OS
			$Padding = [System.BitConverter]::ToUInt32($AppCompatCache[12..15],0)
			
			# Move BinReader to the Offset 8 where the Entries begin
			$MemoryStream.Position=8
			
			if ($Padding -eq 0) {
				# 64-bit Operating System
				
				# Use the Number of Entries it says are available and iterate through this loop that many times
				for ($i=0; $i -lt $NumberOfEntries; $i++) {
					# Parse the metadata for the entry and add to a custom object
					$TempObject = "" | Select-Object -Property Name, ModifiedTime, FileSize, Executed
					$Length = [System.BitConverter]::ToUInt16($BinReader.ReadBytes(2),0)
					$MaxLength = [System.BitConverter]::ToUInt16($BinReader.ReadBytes(2),0)
					$Padding = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
					$Offset = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
					$BinReader.ReadBytes(4) | Out-Null
					$TempObject.ModifiedTime = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
					$TempObject.FileSize = [System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)
					$TempObject.Name = $Unicode.GetString($AppCompatCache[$Offset..($Offset + $Length)])
					if ($TempObject.FileSize -gt 0) {
						$TempObject.Executed = $True
					} else {
						$TempObject.Executed = $False
					}
					$EntryArray += $TempObject
					Remove-Variable Length
					Remove-Variable Padding
					Remove-Variable MaxLength
					Remove-Variable Offset
					Remove-Variable TempObject
				}
			} else {
				# 32-bit Operating System
				
				# Use the Number of Entries it says are available and iterate through this loop that many times
				for ($i=0; $i -lt $NumberOfEntries; $i++) {
					# Parse the metadata for the entry and add to a custom object
					$TempObject = "" | Select-Object -Property FileName, ModifiedTime, FileSize
					$Length = [System.BitConverter]::ToUInt16($BinReader.ReadBytes(2),0)
					$MaxLength = [System.BitConverter]::ToUInt16($BinReader.ReadBytes(2),0)
					$Offset = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
					$TempObject.ModifiedTime = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
					$TempObject.FileSize = [System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)
					$TempObject.FileName = $Unicode.GetString($AppCompatCache[$Offset..($Offset + $Length)])
					$EntryArray += $TempObject
					Remove-Variable Length
					Remove-Variable MaxLength
					Remove-Variable Offset
					Remove-Variable TempObject
				}
			}
			
			# Return a Table with the results.  I have to do this in the switch since not all OS versions will have the same interesting fields to return
			$EntryArray | Format-Table -AutoSize -Property Name, Time, Flag0, Flag1
		}
		
		# DEADBEEF in Little Endian Hex - Windows XP 32-bit
		"EFBEADDE" {
			# Number of Entries
			$NumberOfEntries = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
			# Number of LRU Entries
			$NumberOfLRUEntries = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
			# Unknown
			$BinReader.ReadBytes(4) | Out-Null
			# LRU Array Start
			for ($i=0; $i -lt $NumberOfLRUEntries; $i++) {
				$LRUEntry
			}
			
			# Move to the Offset 400 where the Entries begin
			$MemoryStream.Position=400
			
			# Use the Number of Entries it says are available and iterate through this loop that many times
			for ($i=0; $i -lt $NumberOfEntries; $i++) {
				# Parse the metadata for the entry and add to a custom object
				$TempObject = "" | Select-Object -Property FileName, LastModifiedTime, Size, LastUpdatedTime
				# According to Mandiant paper, MAX_PATH + 4 (260 + 4, in unicode = 528 bytes)
				$TempObject.FileName = ($UnicodeEncoding.GetString($BinReader.ReadBytes(528))) -replace "\\\?\?\\",""
				$TempObject.LastModifiedTime = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
				# I'm not fully confident in the Size value without having a Windows XP box to test. Mandiant Whitepaper only says Large_Integer, QWORD File Size. Harlan Carveys' script parses as 2 DWORDS.
				$TempObject.FileSize = [System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)
				$TempObject.LastUpdatedTime = [DateTime]::FromFileTime([System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)).ToString("G")
				$EntryArray += $TempObject
			}
			
			# Return a Table with the results.  I have to do this in the switch since not all OS versions will have the same interesting fields to return
			return $EntryArray
		}
	}
}