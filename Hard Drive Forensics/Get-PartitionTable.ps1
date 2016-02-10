<#
.SYNOPSIS
	Returns partition table entries.

.PARAMETER DeviceID

.PARAMETER DriveNumber

.PARAMETER ShowExtended
	Extended Boot Record entries are hidden by default. This allows them to be displayed.

.NOTES
	Author: David Howell
	Last Modified: 02/10/2016
	
	Most of the partition entry structure information pulled from Invoke-IR:
	https://github.com/Invoke-IR/ForensicPosters
	
	Extended Boot Record information mostly from here:
	https://en.wikipedia.org/wiki/Extended_boot_record
#>
[CmdletBinding(DefaultParameterSetName="Default")]
Param(
	[Parameter(Mandatory=$True,ParameterSetName="DeviceID")]
	[ValidatePattern("^\\\\\.\\PHYSICALDRIVE[0-9]{1,2}$")]
	[String]$DeviceID,
	
	[Parameter(Mandatory=$True,ParameterSetName="DriveNumber")]
	[ValidatePattern("^[0-9]{1,2}$")]
	[Int]$DriveNumber,
	
	[Parameter(Mandatory=$False)]
	[Switch]$ShowExtended
)

function Get-FileStream {
	<#
	.SYNOPSIS
		Returns a filestream for a drive or volume
	
	.DESCRIPTION
		Uses .NET Reflection to Platform Invoke Kernel32's CreateFile method to attain a read handle, then returns a file stream using the handle.
	
	.PARAMETER DeviceID
	
	.PARAMETER DriveNumber
	
	.PARAMETER VolumeLetter
	
	.NOTES
		Author: David Howell
		Last Modified: 01/25/2016
		https://msdn.microsoft.com/en-us/library/windows/desktop/aa363858(v=vs.85).aspx
	#>
	[CmdletBinding()]Param(
		[Parameter(Mandatory=$False,ParameterSetName="DriveNumber")]
		[ValidatePattern("^[0-9]{1,2}$")]
		[Int]$DriveNumber,
		
		[Parameter(Mandatory=$False,ParameterSetName="DeviceID")]
		[ValidatePattern("^\\\\\.\\PHYSICALDRIVE[0-9]{1,2}$")]
		[String]$DeviceID,
		
		[Parameter(Mandatory=$False,ParameterSetName="VolumeLetter")]
		[ValidatePattern("^[A-Za-z]$")]
		[String]$VolumeLetter
	)
	if (([System.Security.Principal.WindowsPrincipal][System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
		# Note current variables to perform cleanup later
		$Variables = Get-Variable | Select-Object -ExpandProperty Name

		#region .NET Reflection
		$Domain = [AppDomain]::CurrentDomain
		$DynAssembly = New-Object System.Reflection.AssemblyName("Forensics")
		$AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
		$ModuleBuilder = $AssemblyBuilder.DefineDynamicModule("MasterBootRecord", $False)
		$TypeBuilder = $ModuleBuilder.DefineType("kernel32", "Public, Class")

		$CreateFileMethod = $TypeBuilder.DefineMethod(
			"CreateFile", # Method Name
			[System.Reflection.MethodAttributes] "Public, Static", # Method Attributes
			[Microsoft.Win32.SafeHandles.SafeFileHandle], # Method Return Type
			[Type[]] @(
				[String], # lpFileName
				[UInt32], # dwDesiredAccess
				[UInt32], # dwShareMode
				[IntPtr], # SecurityAttributes
				[UInt32], # dwCreationDisposition
				[UInt32], # dwFlagsAndAttributes
				[IntPtr] # hTemplateFile
			) # Method Parameters
		)
		$CreateFileDllImport = [System.Runtime.InteropServices.DllImportAttribute].GetConstructor(@([String]))
		$CreateFileFieldArray = [System.Reflection.FieldInfo[]] @(
			[System.Runtime.InteropServices.DllImportAttribute].GetField("EntryPoint"),
			[System.Runtime.InteropServices.DllImportAttribute].GetField("PreserveSig"),
			[System.Runtime.InteropServices.DllImportAttribute].GetField("SetLastError"),
			[System.Runtime.InteropServices.DllImportAttribute].GetField("CallingConvention"),
			[System.Runtime.InteropServices.DllImportAttribute].GetField("CharSet")
		)
		$CreateFileFieldValueArray = [Object[]] @(
			"CreateFile",
			$True,
			$True,
			[System.Runtime.InteropServices.CallingConvention]::Winapi,
			[System.Runtime.InteropServices.CharSet]::Auto
		)
		$CreateFileCustomAttribute = New-Object System.Reflection.Emit.CustomAttributeBuilder(
			$CreateFileDllImport,
			@("kernel32.dll"),
			$CreateFileFieldArray,
			$CreateFileFieldValueArray
		)
		$CreateFileMethod.SetCustomAttribute($CreateFileCustomAttribute)

		$Kernel32 = $TypeBuilder.CreateType()
		#endregion .NET Reflection
		
		if ($PSCmdlet.ParameterSetName -eq "DriveNumber") {
			$Handle = $Kernel32::CreateFile("\\.\PHYSICALDRIVE$DriveNumber", [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite, [IntPtr]::Zero, [System.IO.FileMode]::Open, [System.UInt32]0x02000000, [IntPtr]::Zero)
		} elseif ($PSCmdlet.ParameterSetName -eq "DeviceID") {
			$Handle = $Kernel32::CreateFile($DeviceID, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite, [IntPtr]::Zero, [System.IO.FileMode]::Open, [System.UInt32]0x02000000, [IntPtr]::Zero)
		} elseif ($PSCmdlet.ParameterSetName -eq "VolumeLetter") {
			$Handle = $Kernel32::CreateFile("\\.\$VolumeLetter`:", [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite, [IntPtr]::Zero, [System.IO.FileMode]::Open, [System.UInt32]0x02000000, [IntPtr]::Zero)
		}
		if ($Handle -ne -1) {
			if ($Handle.GetType().Name -ne "SafeFileHandle") {
				$SafeHandle = New-Object Microsoft.Win32.SafeHandles.SafeFileHandle $Handle, $True
				$FileStream = New-Object System.IO.FileStream $SafeHandle, ([System.IO.FileAccess]::Read)
			} else {
				$FileStream = New-Object System.IO.FileStream $Handle, ([System.IO.FileAccess]::Read)
			}
			$FileStream
		}
		Get-Variable | Where-Object { $Variables -notcontains $_.Name } | ForEach-Object { Remove-Variable $_.Name -ErrorAction SilentlyContinue }
	}
}

function Get-BytesFromStream {
	<#
	.SYNOPSIS
		Reads bytes from a filestream and returns a byte array.
	
	.PARAMETER Stream
	.PARAMETER Length
	.PARAMETER Optional Offset
	
	.NOTES
		Author: David Howell
		Last Modified: 02/06/2016
	#>
	Param(
		[Parameter(Mandatory=$True)]
		[ValidateScript({ $_.GetType().BaseType.FullName -eq "System.IO.Stream"})]
		$Stream,
		
		[Parameter(Mandatory=$True)]
		[System.UInt64]
		$Length,
		
		[Parameter(Mandatory=$False)]
		[System.UInt64]
		$Offset
	)
	
	if ($Offset -ge 0 ) {
		$Stream.Seek($Offset,[System.IO.SeekOrigin]::Begin) | Out-Null
	}

	[Byte[]]$ByteArray = New-Object Byte[] $Length
	$Stream.Read($ByteArray, 0, $Length) | Out-Null
	$ByteArray
}

# Note current variables to perform cleanup later 
$Variables = Get-Variable | Select-Object -ExpandProperty Name
$UnicodeEncoding = New-Object System.Text.UnicodeEncoding

function Parse-MBRPartitionTable {
		<#
	.SYNOPSIS
		Parses MBR Partition entries from a byte array.
	
	.PARAMETER PartitionTableBytes
		The byte array containing partition entries
	
	.PARAMETER Optional EBRStartSector
		The start sector of the Extended Boot Record (start sector for the 1st EBR entry)
	#>
	[CmdletBinding()]Param(
		[Parameter(Mandatory=$True)][Byte[]]$PartitionTableBytes,
		[Parameter(Mandatory=$True)][String]$DeviceID,
		[Parameter(Mandatory=$False)]$EBRStartSector
	)
	# Loop through and parse each partition table entry
	for ($i=0; $i -lt 4; $i++) {
		# Read the Partition Entry into a byte array
		[Byte[]]$PartitionEntry = $PartitionTableBytes[($i*16)..(($i*16)+16)]
		
		# Parse the Partition Type, and convert it to a readable form from a list of known values
		switch -regex ([System.BitConverter]::ToString($PartitionEntry[4]) -replace "-", "") {
			"00" { $PartitionType = "Empty" }
			"01" { $PartitionType = "FAT12" }
			"(04|06|0E)" { $PartitionType = "FAT16" }
			"(05|0F)" { $PartitionType = "MS_Extended" }
			"07" { $PartitionType = "NTFS" }
			"(0B|0C)" { $PartitionType = "FAT32" }
			"11" { $PartitionType = "Hidden FAT12" }
			"(14|16|1E)" { $PartitionType = "Hidden FAT16" }
			"(1B|1C)" { $PartitionType = "Hidden FAT32" }
			"42" { $PartitionType = "MS_MBR_Dynamic" }
			"82" { $PartitionType = "Linux Swap/Solaris x86" }
			"83" { $PartitionType = "Linux" }
			"84" { $PartitionType = "Hibernation" }
			"85" { $PartitionType = "Linux Extended" }
			"86" { $PartitionType = "NTFS Volume Set" }
			"87" { $PartitionType = "NTFS Volume Set1" }
			"A0" { $PartitionType = "Hibernation1" }
			"A1" { $PartitionType = "Hibernation2" }
			"A5" { $PartitionType = "FreeBSD" }
			"A6" { $PartitionType = "OpenBSD" }
			"A8" { $PartitionType = "MacOSX" }
			"A9" { $PartitionType = "NetBSD" }
			"AB" { $PartitionType = "MacOSX Boot" }
			"B7" { $PartitionType = "BSDI" }
			"B8" { $PartitionType = "BSDI Swap" }
			"D8" { $PartitionType = "Restore Partition" }
			"EE" { $PartitionType = "EFI GPT Disk" }
			"EF" { $PartitionType = "EFI System Partition" }
			"FB" { $PartitionType = "VMWare File System" }
			"FC" { $PartitionType = "VMWare Swap" }
			Default { $PartitionType = "Unknown" }
		}
		# Calculate non-relative start sector
		if ($EBRStartSector) {
			$StartSector = [System.BitConverter]::ToUInt32($PartitionEntry[8..11],0) + $EBRStartSector
		} else {
			$StartSector = [System.BitConverter]::ToUInt32($PartitionEntry[8..11],0)
		}
		#Calculate End Sector
		$EndSector = $StartSector + [System.BitConverter]::ToUInt32($PartitionEntry[12..15],0)
		
		$TempObject = [PSCustomObject]@{
			DeviceID = $DeviceID
			StartSector = $StartSector
			EndSector = $EndSector
			TotalSectors = [System.BitConverter]::ToUInt32($PartitionEntry[12..15],0)
			PartitionTypeName = $PartitionType
			Bootable = if ($PartitionEntry[0] -eq 128) { $True } else { $False }
			RelativeStartSector = [System.BitConverter]::ToUInt32($PartitionEntry[8..11],0)
			PartitionGUID = "N/A"
			PartitionTypeGUID = "N/A"
		}

		# Add a metadata field for extended partition entries to note once it has been parsed
		if ($TempObject.PartitionType -eq "MS_Extended") {
			Add-Member -InputObject $TempObject -MemberType NoteProperty -Name ExtendedParsed -Value $False
		}
		if ($TempObject.PartitionTypeName -ne "Empty") {
			$TempObject
		}
	}
}

$Drives = @()
if ($PSCmdlet.ParameterSetName -eq "DeviceID") {
	$Drives += [PSCustomObject]@{
		FileStream = Get-FileStream -DeviceID $DeviceID
		DeviceID = $DeviceID
	}
} elseif ($PSCmdlet.ParameterSetName -eq "DriveNumber") {
	$Drives += [PSCustomObject]@{
		FileStream = Get-FileStream -DriveNumber $DriveNumber
		DeviceID = "\\.\PHYSICALDRIVE$DriveNumber"
	}
} elseif ($PSCmdlet.ParameterSetName -eq "Default") {
	Get-WmiObject -Class Win32_DiskDrive | ForEach-Object {
		$Drives += [PSCustomObject]@{
			FileStream = Get-FileStream -DeviceID $_.DeviceID
			DeviceID = $_.DeviceID
		}
	}
}

$PartitionTable = @()
ForEach ($Drive in $Drives) {
	# Read Sector 0
	$SectorData = Get-BytesFromStream -Stream $Drive.FileStream -Length 512 -Offset 0
	if ($SectorData[450] -eq [Byte]238) {
		# GUID Partition Table
		
		$GPTOffset = [System.BitConverter]::ToUInt32($SectorData[454..457],0)
		# Read GPT Sector
		$SectorData = Get-BytesFromStream -Stream $Drive.FileStream -Length 512 -Offset ($GPTOffset * 512) | Out-Null
		$FirstLBA = [System.BitConverter]::ToUInt64($SectorData[40..47],0)
		$LastLBA = [System.BitConverter]::ToUInt64($SectorData[48..55],0)
		$GUID = [System.BitConverter]::ToString($SectorData[56..71]) -split "-"
		$PartitionTableLBA = [System.BitConverter]::ToUInt64($SectorData[72..79],0)
		$PartitionEntries = [System.BitConverter]::ToUInt32($SectorData[80..83],0)
		$PartitionEntrySize = [System.BitConverter]::ToUInt32($SectorData[84..87],0)
		
		for ($i=0; $i -lt $PartitionEntries; $i++) {
			if ($PartitionEntrySize -eq 128) {
				$PartitionEntry = Get-BytesFromStream -Stream $Drive.FileStream -Length 128 -Offset (($PartitionTableLBA * 512) + ($i * 128)) | Out-Null
				if ((Invoke-GuidParser -ByteArray $PartitionEntry[16..31]) -ne "00000000-0000-0000-0000-000000000000") {
					$PartitionTable += [PSCustomObject]@{
						DeviceID = $Drive.DeviceID
						StartSector = [System.BitConverter]::ToUInt64($PartitionEntry[32..39],0)
						EndSector = [System.BitConverter]::ToUInt64($PartitionEntry[40..47],0)
						TotalSectors = [System.BitConverter]::ToUInt64($PartitionEntry[40..47],0) - [System.BitConverter]::ToUInt64($PartitionEntry[32..39],0)
						PartitionTypeName = $UnicodeEncoding.GetString($PartitionEntry[56..127])
						Bootable = ""
						RelativeStartSector = ""
						PartitionGUID = Invoke-GuidParser -ByteArray $PartitionEntry[16..31]
						PartitionTypeGUID = Invoke-GuidParser -ByteArray $PartitionEntry[0..15]
					}
				}
			}
		}
	} else {
		# MBR Partition Table
		
		# Read the Partition Table into a byte array
		[Byte[]]$PartitionTableBytes = $SectorData[446..510]
		$PartitionTable += Parse-MBRPartitionTable -PartitionTableBytes $PartitionTableBytes -DeviceID $Drive.DeviceID
		
		# While loop to continue parsing Extended Boot Records in an EBR chain (if present)
		while ($Exit -ne $True) {
			$PartitionTable | Where-Object { $_.PartitionType -eq "MS_Extended" } | ForEach-Object {
				if ($_.ExtendedParsed -eq $False) {
					if (-not($EBRStartSector)) {
						$EBRStartSector = $_.StartSector
					}
					
					# Move to the sector containing the extended partition and read the data
					[Byte[]]$PartitionTableBytes = Get-BytesFromStream -Stream $Drive.FileStream -Length 64 -Offset (($_.StartSector * 512) + 446) | Out-Null
					$TemporaryTable = Parse-MBRPartitionTable -PartitionTableBytes $PartitionTableBytes -DeviceID $Drive.DeviceID -EBRStartSector $EBRStartSector
					ForEach ($Entry in $TemporaryTable) {
						#$Entry.RelativeStartSector = $Entry.RelativeStartSector + $_.RelativeStartSector
						$PartitionTable += $Entry
					}
					$_.ExtendedParsed = $True
				}
			}
			if ($PartitionTable.ExtendedParsed -notcontains $False) {
				$Exit = $True
			}
		}
	}
}
if ($ShowExtended) {
	$PartitionTable
} else {
	$PartitionTable | Where-Object { $_.PartitionType -ne "MS_Extended" }
}
Get-Variable | Where-Object { $Variables -notcontains $_.Name } | ForEach-Object { Remove-Variable $_.Name -ErrorAction SilentlyContinue }