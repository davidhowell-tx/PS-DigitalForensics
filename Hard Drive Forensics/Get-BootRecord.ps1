<#
.SYNOPSIS
	Returns information about the Master Boot Record, including bootstrap code.

.NOTES
	Author: David Howell
	Last Modified: 02/10/2016
#>
[CmdletBinding(DefaultParameterSetName="Default")]
Param(
	[Parameter(Mandatory=$True,ParameterSetName="DriveNumber")]
	[ValidatePattern("^[0-9]{1,2}$")]
	[Int]$DriveNumber
)
$Variables = Get-Variable | Select-Object -ExpandProperty Name
$MD5 = New-Object System.Security.Cryptography.MD5CryptoServiceProvider

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

$Drives = @()
if ($PSCmdlet.ParameterSetName -eq "DriveNumber") {
	$Drives += [PSCustomObject]@{
		FileStream = Get-FileStream -DriveNumber $DriveNumber
		DeviceID = "\\.\PHYSICALDRIVE$DriveNumber"
	}
}
if ($PSCmdlet.ParameterSetName -eq "Default") {
	Get-WmiObject -Class Win32_DiskDrive | ForEach-Object {
		$Drives += [PSCustomObject]@{
			FileStream = Get-FileStream -DeviceID $_.DeviceID
			DeviceID = $_.DeviceID
		}
	}
}

ForEach ($Drive in $Drives) {
	# Read 1st Sector
	$SectorData = Get-BytesFromStream -Stream $Drive.FileStream -Length 512 -Offset 0
	if ($SectorData[450] -eq [Byte]238) {
		# Disk is GPT
		$BootstrapCode = [System.BitConverter]::ToString($SectorData[0..439]) -replace "-",""
		$DriveSignature = [System.BitConverter]::ToString($SectorData[440..443]) -replace "-",""
		$GPTOffset = [System.BitConverter]::ToUInt32($SectorData[454..457],0)
		
		$SectorData = Get-BytesFromStream -Stream $Drive.FileStream -Length 512 -Offset ($GPTOffset * 512) | Out-Null
		$FirstLBA = [System.BitConverter]::ToUInt64($SectorData[40..47],0)
		$LastLBA = [System.BitConverter]::ToUInt64($SectorData[48..55],0)
		$GUID = [System.BitConverter]::ToString($SectorData[56..71]) -split "-"
		$PartitionTableLBA = [System.BitConverter]::ToUInt64($SectorData[72..79],0)
		$PartitionEntries = [System.BitConverter]::ToUInt32($SectorData[80..83],0)
		$PartitionEntrySize = [System.BitConverter]::ToUInt32($SectorData[84..87],0)
		[PSCustomObject]@{
			PartitionTableType = "GPT"
			MBRType = "N/A"
			DriveSignature = $DriveSignature
			GPTGUID = Invoke-GuidParser -ByteArray $GUID
			PartitionTableLBA = $PartitionTableLBA
			BootstrapCode = $BootstrapCode
		}
	} else {
		$MBRMD5Hash = [System.BitConverter]::ToString($MD5.ComputeHash($SectorData[0..439])) -replace "-",""
		$BootstrapCode = [System.BitConverter]::ToString($SectorData[0..439]) -replace "-",""
		# Known MBR Hashes retrieved from PowerForensics project @ https://github.com/Invoke-IR/PowerForensics
		switch ($MBRMD5Hash) {
			"8F558EB6672622401DA993E1E865C861" {
				$MBRType = "Windows 5.X"
			}
			"5C616939100B85E558DA92B899A0FC36" {
				$MBRType = "Windows 6.0"
			}
			"A36C5E4F47E84449FF07ED3517B43A31" {
				$MBRType = "Windows 6.1+"
			}
			"A6C7E63CA46F1CB2307E0F10AD897BDE" {
				$MBRType = "Grub"
			}
			"B40C0E49689A0ABD2A51379FED1800F3" {
				$MBRType = "Bootkit Nyan Cat"
			}
			"72B8CE41AF0DE751C946802B3ED844B4" {
				$MBRType = "Bootkit StonedV2"
			}
			"5C7DE5F58B276CBE84B8B7E25F08318E" {
				$MBRType = "Bootkit StonedV2"
			}
			Default {
				$MBRType = "Unknown MBR Code"
			}
		}
		$DriveSignature = [System.BitConverter]::ToString($SectorData[440..443]) -replace "-",""

		[PSCustomObject]@{
			PartitionTableType = "MBR"
			MBRType = $MBRType
			DriveSignature = $DriveSignature
			GPTGUID = "N/A"
			PartitionTableLBA = "N/A"
			BootstrapCode = $BootstrapCode
		}
	}
}
Get-Variable | Where-Object { $Variables -notcontains $_.Name -and $_.Name -ne "Get-BootRecord" } | ForEach-Object { Remove-Variable $_.Name -ErrorAction SilentlyContinue }