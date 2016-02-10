<#
.SYNOPSIS
	Returns information about the Volume Boot Record.

.PARAMETER DeviceID
.PARAMETER DriveNumber
.PARAMETER VolumeLetter

.NOTES
	Author: David Howell
	Last Modified: 02/10/2016
	Most of the information pulled from Invoke-IR:
	https://github.com/Invoke-IR/ForensicPosters
#>
[CmdletBinding(DefaultParameterSetName="Default")]
Param(
	[Parameter(Mandatory=$True,ParameterSetName="FileStream")]
	[System.IO.FileStream]
	$FileStream,
	
	[Parameter(Mandatory=$True,ParameterSetName="DeviceID")]
	[ValidatePattern("^\\\\\.\\PHYSICALDRIVE[0-9]{1,2}$")]
	[String]$DeviceID,
	
	[Parameter(Mandatory=$True,ParameterSetName="DriveNumber")]
	[ValidatePattern("^[0-9]{1,2}$")]
	[Int]$DriveNumber,
	
	[Parameter(Mandatory=$True,ParameterSetName="VolumeLetter")]
	[ValidatePattern("^[A-Za-z]$")]
	[String]$VolumeLetter
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

function Get-NTFSVolumeBootRecord {
	<#
	.SYNOPSIS
		Parses the volume boot record of an NTFS formatted volume.
	
	.PARAMETER ByteArray
		Byte array of sector 0 for the volume
	
	.NOTES
		Author: David Howell
		Last Modified: 01/25/2016
	#>
	[CmdletBinding()]Param(
		[Parameter(Mandatory=$True)]
		[Byte[]]$ByteArray
	)
	$ASCIIEncoding = New-Object System.Text.ASCIIEncoding
	$MD5 = New-Object System.Security.Cryptography.MD5CryptoServiceProvider
	$BootstrapHash = [System.BitConverter]::ToString($MD5.ComputeHash($ByteArray[84..510])) -replace "-",""
	if ($BootstrapHash -eq "8AF358413491D24AC15DF3D9A0904A26") {
		$BootstrapHashValue = "Known - $BootstrapHash"
	} else {
		$BootstrapHashValue = "Unknown - $BootstrapHash"
	}
	if ($ByteArray[64] -ge [Byte]128) {
		$FileRecordSize = [Math]::Pow(2,(($ByteArray[64] -bxor 0xFF) + 1))
	} else {
		$FileRecordSize = $ByteArray[64] * $ByteArray[13] * [System.BitConverter]::ToUInt16($ByteArray[11..12],0)
	}
	if ($ByteArray[68] -ge [Byte]128) {
		$IndexRecordSize = [Math]::Pow(2,(($ByteArray[68] -bxor 0xFF) + 1))
	} else {
		$IndexRecordSize = $ByteArray[68] * $ByteArray[13] * [System.BitConverter]::ToUInt16($ByteArray[11..12],0)
	}
	if ($ByteArray[21] -eq 248) {
		$MediaDescriptor = "Hard Drive"
	} elseif ($ByteArray[21] -eq 240){
		$MediaDescriptor = "Floppy Disk"
	}
	$VolumeSerialNumber = ([System.BitConverter]::ToString(($ByteArray[78], $ByteArray[77])) -replace "-","") + "-" + ([System.BitConverter]::ToString(($ByteArray[73], $ByteArray[72]))  -replace "-","")
	[PSCustomObject]@{
		VolumeSerialNumber = $VolumeSerialNumber
		MediaDescriptor = $MediaDescriptor
		TotalSectors = [System.BitConverter]::ToUInt64($ByteArray[40..47],0)
		HiddenSectors = [System.BitConverter]::ToUInt32($ByteArray[28..31],0)
		ReservedSectors = [System.BitConverter]::ToUInt16($ByteArray[14..15],0)
		BytesPerSector = [System.BitConverter]::ToUInt16($ByteArray[11..12],0)
		BytesPerCluster = [System.BitConverter]::ToUInt16($ByteArray[11..12],0) * $ByteArray[13]
		BytesPerFileRecord = $FileRecordSize
		BytesPerIndexRecord = $IndexRecordSize
		SectorsPerCluster = $ByteArray[13]
		MFTClusterOffset = [System.BitConverter]::ToUInt64($ByteArray[48..55],0)
		MFTMirrorClusterOffset = [System.BitConverter]::ToUInt64($ByteArray[56..63],0)
		MFTByteOffset = [System.BitConverter]::ToUInt16($ByteArray[11..12],0) * $ByteArray[13] * [System.BitConverter]::ToUInt64($ByteArray[48..55],0)
		BootstrapCode = [System.BitConverter]::ToString($ByteArray[84..510]) -replace "-",""
		BootstrapHash = $BootstrapHashValue
		BootstrapErrorCode = $ASCIIEncoding.GetString($ByteArray[396..477])
	}
}

function Get-FAT32VolumeBootRecord {
	<#
	.SYNOPSIS
		Parses the Volume Boot Record of a FAT32 formatted volume.
	
	.PARAMETER ByteArray
		The byte array containing the Volume Boot Record.
	#>
	[CmdletBinding()]Param(
		[Parameter(Mandatory=$True)]
		[ValidateCount(512,512)]
		[Byte[]]$ByteArray
	)
	[PSCustomObject]@{
	
	}
}

$ASCIIEncoding = New-Object System.Text.ASCIIEncoding
$PartitionTable = @()
$TargetArray = @()

switch ($PSCmdlet.ParameterSetName) {
	"DriveNumber" {
		$PartitionTable += Get-PartitionTable -DriveNumber $DriveNumber
	}
	
	"DeviceID" {
		$PartitionTable += Get-PartitionTable -DeviceID $DeviceID
	}
	
	"Default" {
		Get-WmiObject -Class Win32_DiskDrive | ForEach-Object {
			$PartitionTable += Get-PartitionTable -DeviceID $_.DeviceID
		}
	}
	
	"VolumeLetter" {
		$TargetArray += [PSObject]@{
			DeviceID = "\\.\$VolumeLetter`:"
			FileStream = Get-FileStream -VolumeLetter $VolumeLetter
		}
	}
	
	"FileStream" {
		$TargetArray += [PSObject]@{
			DeviceID = ""
			FileStream = $FileStream
		}
	}
}


if ($PartitionTable) {
	$PartitionTable | Select-Object -ExpandProperty DeviceID -Unique | ForEach-Object {
		$TargetArray += [PSObject]@{
			DeviceID = $_
			FileStream = Get-FileStream -DeviceID $_
		}
	}
}

ForEach ($Target in $TargetArray) {
	if ($Target.DeviceID -match "\\\\\.\\PHYSICALDRIVE[0-9]{1,2}") {
		$Partitions = $PartitionTable | Where-Object { $_.DeviceID -eq $Target.DeviceID }
		ForEach ($Partition in $Partitions) {
			$PartitionSectorZero = Get-BytesFromStream -Stream $Target.FileStream -Length 512 -Offset ($Partition.StartSector * 512)
			switch ($Partition.PartitionTypeName) {
				"NTFS" {
					Get-NTFSVolumeBootRecord -ByteArray $PartitionSectorZero
				}
				
				"FAT32" {
					Get-FAT32VolumeBootRecord -ByteArray $PartitionSectorZero
				}
			}
		}
	} elseif ($Target.DeviceID -match "\\\\\.\\[A-Za-z]`:" -or $Target.DeviceID -eq "") {
		$PartitionSectorZero = Get-BytesFromStream -Stream $Target.FileStream -Length 512 -Offset 0
		switch ($ASCIIEncoding.GetString($PartitionSectorZero[3..10])) {	
			"NTFS    " {
				Get-NTFSVolumeBootRecord -ByteArray $PartitionSectorZero
			}
			
			"MSDOS5.0" {
				Get-FAT32VolumeBootRecord -ByteArray $PartitionSectorZero
			}
		}
	}
}