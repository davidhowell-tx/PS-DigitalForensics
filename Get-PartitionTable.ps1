<#
.SYNOPSIS
	Returns partition table entries from the boot sector.

.DESCRIPTION
	Uses .NET Reflection to assemble C# code used to platform invoke a Windows API command to acquire a read handle on the physical drive.
	Parses information directly from the disk.

.PARAMETER DriveNumber
	The drive number of the physical drive for which to return the Partition Table.
	Default is to return for all connected physical drives.

.PARAMETER ShowExtended
	Extended Boot Record entries are hidden by default. This allows them to be displayed.

.NOTES
	Author: David Howell
	Last Modified: 01/19/2016
	
	Most of the partition entry structure information pulled from Invoke-IR:
	https://github.com/Invoke-IR/ForensicPosters
	
	Extended Boot Record information mostly from here:
	https://en.wikipedia.org/wiki/Extended_boot_record
#>
[CmdletBinding()]Param(
	[Parameter(Mandatory=$False)]
	[Int]$DriveNumber,
	
	[Parameter(Mandatory=$False)]
	[Boolean]$ShowExtended
)
# Create a function to parse partition table entries from a sector
function Parse-MBRPartitionTable {
	<#
	.SYNOPSIS
		Parses MBR Partition entries from a byte array.
	
	.PARAMETER PartitionTableBytes
		The byte array containing partition entries
	
	.PARAMETER DriveSignature
		The drive signature of the physical drive pulled from the MBR.
		
	.PARAMETER PhysicalDevice
		The physical device number
	
	.PARAMETER Optional EBRStartSector
		The start sector of the Extended Boot Record (start sector for the 1st EBR entry)
	#>
	[CmdletBinding()]Param(
		[Parameter(Mandatory=$True)][Byte[]]$PartitionTableBytes,
		[Parameter(Mandatory=$True)][String]$DriveSignature,
		[Parameter(Mandatory=$True)][String]$PhysicalDevice,
		[Parameter(Mandatory=$False)]$EBRStartSector
	)
	# Loop through and parse each partition table entry
	for ($i=0; $i -lt 4; $i++) {
		# Read the Partition Entry into a byte array
		[Byte[]]$PartitionEntry = $PartitionTableBytes[($i*16)..(($i*16)+16)]
						
		$TempObject = New-Object PSObject
		# Add MBR Metadata to each entry
		Add-Member -InputObject $TempObject -MemberType NoteProperty -Name "DriveSignature" -Value $DriveSignature
		Add-Member -InputObject $TempObject -MemberType NoteProperty -Name "PhysicalDevice" -Value $PhysicalDevice

		# 1st Byte - Is Bootable Flag - 0x80 means Bootable (Decimal 128)
		if ($PartitionEntry[0] -eq 128) {
			Add-Member -InputObject $TempObject -MemberType NoteProperty -Name "Bootable" -Value $True
		} else {
			Add-Member -InputObject $TempObject -MemberType NoteProperty -Name "Bootable" -Value $False
		}
		
		# Parse Starting Head, Sector, and Cylinder
		Add-Member -InputObject $TempObject -MemberType NoteProperty -Name "StartingHead" -Value $PartitionEntry[1]
		[Int]$StartingSector = $PartitionEntry[2]
		[Int]$StartingCylinder = $PartitionEntry[3]
		if ($StartingSector -gt 128) {
			$StartingCylinder = $StartingCylinder + 512
			$StartingSector = $StartingSector - 128
		}
		if ($StartingSector -gt 64) {
			$StartingCylinder = $StartingCylinder + 256
			$StartingSector = $StartingSector - 64
		}
		Add-Member -InputObject $TempObject -MemberType NoteProperty -Name "StartingSector" -Value $StartingSector
		Add-Member -InputObject $TempObject -MemberType NoteProperty -Name "StartingCylinder" -Value $StartingCylinder
		
		# Parse the Partition Type, and convert it to a readable form from a list of known values
		$PartitionCode = [System.BitConverter]::ToString($PartitionEntry[4]) -replace "-", ""
		switch -regex ($PartitionCode) {
			"00" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "Empty" }
			"01" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "FAT12" }
			"(04|06|0E)" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "FAT16" }
			"(05|0F)" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "MS_Extended" }
			"07" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "NTFS" }
			"(0B|0C)" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "FAT32" }
			"11" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "Hidden FAT12" }
			"(14|16|1E)" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "Hidden FAT16" }
			"(1B|1C)" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "Hidden FAT32" }
			"42" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "MS_MBR_Dynamic" }
			"82" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "Linux Swap/Solaris x86" }
			"83" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "Linux" }
			"84" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "Hibernation" }
			"85" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "Linux Extended" }
			"86" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "NTFS Volume Set" }
			"87" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "NTFS Volume Set1" }
			"A0" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "Hibernation1" }
			"A1" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "Hibernation2" }
			"A5" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "FreeBSD" }
			"A6" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "OpenBSD" }
			"A8" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "MacOSX" }
			"A9" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "NetBSD" }
			"AB" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "MacOSX Boot" }
			"B7" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "BSDI" }
			"B8" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "BSDI Swap" }
			"D8" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "Restore Partition" }
			"EE" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "EFI GPT Disk" }
			"EF" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "EFI System Partition" }
			"FB" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "VMWare File System" }
			"FC" { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "VMWare Swap" }
			Default { Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionType -Value "Unknown" }
		}

		# Parse Ending Head, Sector, and Cylinder
		Add-Member -InputObject $TempObject -MemberType NoteProperty -Name EndingHead -Value $PartitionEntry[5]
		[Int]$EndingSector = $PartitionEntry[6]
		[Int]$EndingCylinder = $PartitionEntry[7]
		if ($EndingSector -gt 128) {
			$EndingCylinder = $EndingCylinder + 512
			$EndingSector = $EndingSector - 128
		}
		if ($EndingSector -gt 64) {
			$EndingCylinder = $EndingCylinder + 256
			$EndingSector = $EndingSector - 64
		}
		Add-Member -InputObject $TempObject -MemberType NoteProperty -Name EndingSector -Value $EndingSector
		Add-Member -InputObject $TempObject -MemberType NoteProperty -Name EndingCylinder -Value $EndingCylinder
		
		# Parse relative start and Total sectors
		Add-Member -InputObject $TempObject -MemberType NoteProperty -Name RelativeStartSector -Value ([System.BitConverter]::ToUInt32($PartitionEntry[8..11],0))
		Add-Member -InputObject $TempObject -MemberType NoteProperty -Name TotalSectors -Value ([System.BitConverter]::ToUInt32($PartitionEntry[12..15],0))
		
		# Calculate non-relative start sector
		if ($EBRStartSector) {
			Add-Member -InputObject $TempObject -MemberType NoteProperty -Name StartSector -Value ($TempObject.RelativeStartSector + $EBRStartSector)
		} else {
			Add-Member -InputObject $TempObject -MemberType NoteProperty -Name StartSector -Value $TempObject.RelativeStartSector
		}
		# Calculate end sector
		Add-Member -InputObject $TempObject -MemberType NoteProperty -Name EndSector -Value ($TempObject.StartSector + $TempObject.TotalSectors)
		
		# Add a metadata field for extended partition entries to note once it has been parsed
		if ($TempObject.PartitionType -eq "MS_Extended") {
			Add-Member -InputObject $TempObject -MemberType NoteProperty -Name ExtendedParsed -Value $False
		}
		if ($TempObject.PartitionType -ne "Empty") {
			$TempObject
		}
		Remove-Variable -Name TempObject
		Remove-Variable -Name PartitionEntry
	}
}

# Create a function to convert little endian GPT GUIDs to readable format
function Parse-GPTGUID {
	<#
	.SYNOPSIS
		Converts a byte array into a GPT GUID
	#>
	[CmdletBinding()]Param(
		[Parameter(Mandatory=$True)][Byte[]]$GUIDBytes
	)
	$GUID = [System.BitConverter]::ToString($GUIDBytes) -split "-"
	"$($GUID[3])$($GUID[2])$($GUID[1])$($GUID[0])-$($GUID[5])$($GUID[4])-$($GUID[7])$($GUID[6])-$($GUID[8])$($GUID[9])-$($GUID[10])$($GUID[11])$($GUID[12])$($GUID[13])$($GUID[14])$($GUID[15])"
}

# Check Admin Privileges
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())
if ($CurrentPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
	$UnicodeEncoding = New-Object System.Text.UnicodeEncoding
	# Use .Net Reflection to P/Invoke CreateFile and CloseHandle from kernel32
	#region .Net Reflection
	$Domain = [AppDomain]::CurrentDomain
	$DynAssembly = New-Object System.Reflection.AssemblyName("Forensics")
	$AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
	$ModuleBuilder = $AssemblyBuilder.DefineDynamicModule("MasterBootRecord", $False)
	$TypeBuilder = $ModuleBuilder.DefineType("kernel32", "Public, Class")

	#region Build CreateFile Method
	$CreateFileMethod = $TypeBuilder.DefineMethod(
		"CreateFile", # Method Name
		[System.Reflection.MethodAttributes] "Public, Static", # Method Attributes
		[IntPtr], # Method Return Type
		[Type[]] @(
			[String], # lpFileName
			[UInt32], # dwDesiredAccess
			[UInt32], # dwShareMode
			[IntPtr], # SecurityAttributes
			[UInt32], # dwCreationDisposition
			[UInt32] # dwFlagsAndAttributes
		)
	) # Method Parameters
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
	#endregion Build CreateFile Method

	#region Build CloseHandle Method
	$CloseHandleMethod = $TypeBuilder.DefineMethod(
		"CloseHandle", # Method Name
		[System.Reflection.MethodAttributes] "Public, Static", # Method Attributes
		[Boolean], # Method Return Type
		[Type[]] @(
			[IntPtr] # hObject
		) # Method Parameters
	)
	$CloseHandleDllImport = [System.Runtime.InteropServices.DllImportAttribute].GetConstructor(@([String]))
	$CloseHandleFieldArray = [System.Reflection.FieldInfo[]] @(
		[System.Runtime.InteropServices.DllImportAttribute].GetField("EntryPoint"),
		[System.Runtime.InteropServices.DllImportAttribute].GetField("PreserveSig"),
		[System.Runtime.InteropServices.DllImportAttribute].GetField("SetLastError"),
		[System.Runtime.InteropServices.DllImportAttribute].GetField("CallingConvention"),
		[System.Runtime.InteropServices.DllImportAttribute].GetField("CharSet")
	)
	$CloseHandleFieldValueArray = [Object[]] @(
		"CloseHandle",
		$True,
		$True,
		[System.Runtime.InteropServices.CallingConvention]::Winapi,
		[System.Runtime.InteropServices.CharSet]::Auto
	)
	$CloseHandleCustomAttribute = New-Object System.Reflection.Emit.CustomAttributeBuilder(
		$CloseHandleDllImport,
		@("kernel32.dll"),
		$CloseHandleFieldArray,
		$CloseHandleFieldValueArray
	)
	$CloseHandleMethod.SetCustomAttribute($CloseHandleCustomAttribute)
	#endregion Build CloseHandle Method

	$Kernel32 = $TypeBuilder.CreateType()
	#endregion .Net Reflection

	# Get a listing of Physical Drives. If the user provided a drive number, filter by it
	if ($DriveNumber) {
		$PhysicalDrives = Get-WmiObject -Class Win32_DiskDrive | Where-Object { $_.DeviceID -eq "\\.\PHYSICALDRIVE$($DriveNumber)" }
	} else {
		$PhysicalDrives = Get-WmiObject -Class Win32_DiskDrive
	}
	# Initialize an empty array to store partition table entries
	$PartitionTable = @()
	ForEach ($PhysicalDrive in $PhysicalDrives) {
		# Use Kernel32.dll's CreateFile to get a read handle on the device
		[IntPtr]$Handle = $Kernel32::CreateFile($PhysicalDrive.DeviceID, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read, [System.IntPtr]::Zero, [System.IO.FileMode]::Open, [System.UInt32]0x02000000)
		
		if ($Handle -ne -1) {
			$SafeHandle = New-Object Microsoft.Win32.SafeHandles.SafeFileHandle $Handle, $True
			$FileStream = New-Object System.IO.FileStream $SafeHandle, ([System.IO.FileAccess]::Read)
			$BinReader = New-Object System.IO.BinaryReader $FileStream
			
			# Skip first 440 bytes of the MBR
			$BinReader.ReadBytes(440) | Out-Null			

			# Next 4 bytes is the drive's signature. Should match the REG_BINARY key at HKLM\System\MountedDevices under the key for the drive letter
			$DriveSignature = [System.BitConverter]::ToString($BinReader.ReadBytes(4)) -replace "-",""

			# Next 2 bytes is 0x0000
			$BinReader.ReadBytes(2) | Out-Null

			# Read the Partition Table into a byte array
			[Byte[]]$PartitionTableBytes = $BinReader.ReadBytes(64)

			# Determine if this is a GPT Disk or normal MBR Partition Table
			if ([System.BitConverter]::ToString($PartitionTableBytes[4]) -eq "EE") {
				# It is a GPT Disk
				
				$GPTOffset = [System.BitConverter]::ToUInt32($PartitionEntry[8],0)
				$FileStream.Position = $GPTOffset * 512
				$BinReader.ReadBytes(72) | Out-Null
				
				$PartitionTableLBA = [System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)
				$PartitionEntries = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
				$PartitionEntrySize = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
				
				# Move to Partition Table LBA
				$FileStream.Position = $PartitionTableLBA * 512
				for ($i=1; $i -le $PartitionEntries; $i++) {
					if ($PartitionEntrySize -eq 128) {
						$TempObject = New-Object PSObject
						Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionTypeGUID -Value (Parse-GPTGUID -GUIDBytes $BinReader.ReadBytes(16))
						Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionGUID -Value (Parse-GPTGUID -GUIDBytes $BinReader.ReadBytes(16))
						Add-Member -InputObject $TempObject -MemberType NoteProperty -Name StartLBA -Value [System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)
						Add-Member -InputObject $TempObject -MemberType NoteProperty -Name EndLBA -Value [System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)
						Add-Member -InputObject $TempObject -MemberType NoteProperty -Name Attributes	 -Value [System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)
						Add-Member -InputObject $TempObject -MemberType NoteProperty -Name PartitionName -Value $UnicodeEncoding.GetString($BinReader.ReadBytes(72))
						$PartitionTable += $TempObject
						Remove-Variable -Name TempObject
					}
				}
			} else {
				# It is a MBR Disk
				$PartitionTable += Parse-MBRPartitionTable -PartitionTableBytes $PartitionTableBytes -DriveSignature $DriveSignature -PhysicalDevice $PhysicalDrive.DeviceID
				
				# While loop to continue parsing Extended Boot Records in an EBR chain (if present)
				while ($Exit -ne $True) {
					$PartitionTable | Where-Object { $_.PartitionType -eq "MS_Extended" } | ForEach-Object {
						if ($_.ExtendedParsed -eq $False) {
							if (-not($EBRStartSector)) {
								$EBRStartSector = $_.StartSector
							}
							
							# Move to the sector containing the extended partition and read the data
							$FileStream.Position = $_.StartSector * 512
							$BinReader.ReadBytes(446) | Out-Null
							[Byte[]]$PartitionTableBytes = $BinReader.ReadBytes(64)
							$TemporaryTable = Parse-MBRPartitionTable -PartitionTableBytes $PartitionTableBytes -DriveSignature $DriveSignature -PhysicalDevice $PhysicalDrive.DeviceID -EBRStartSector $EBRStartSector
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
			Remove-Variable -Name BinReader
			Remove-Variable -Name FileStream
			Remove-Variable -Name SafeHandle
			$Kernel32::CloseHandle($Handle)
			
			if ($ShowExtended) {
				$PartitionTable
			} else {
				$PartitionTable | Where-Object { $_.PartitionType -ne "MS_Extended" }
			}
		}
	}
}