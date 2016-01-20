<#
.SYNOPSIS
	Returns information about the Master Boot Record, including bootstrap code.

.DESCRIPTION
	Uses .NET Reflection to assemble C# code used to platform invoke a Windows API command to acquire a read handle on the physical drive.
	Parses information directly from the disk.

.PARAMETER DriveNumber
	The drive number of the physical drive for which to return the MBR.
	Default is to return for all connected physical drives.

.NOTES
	Author: David Howell
	Last Modified: 01/19/2016
	Most of the information pulled from Invoke-IR:
	https://github.com/Invoke-IR/ForensicPosters
#>
[CmdletBinding()]Param(
	[Parameter(Mandatory=$False)]
	[Int]$DriveNumber
)

# Check Admin
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())
# Needs to return true
if ($CurrentPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
	if ($DriveNumber) {
		$PhysicalDrives = Get-WmiObject -Class Win32_DiskDrive | Where-Object { $_.DeviceID -eq "\\.\PHYSICALDRIVE$($DriveNumber)" }
	} else {
		# Get a listing of Physical Drives
		$PhysicalDrives = Get-WmiObject -Class Win32_DiskDrive
	}

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

$MD5 = New-Object System.Security.Cryptography.MD5CryptoServiceProvider
	ForEach ($PhysicalDrive in $PhysicalDrives) {
		# Use Kernel32.dll's CreateFile to get a read handle on the device
		[IntPtr]$Handle = $Kernel32::CreateFile($PhysicalDrive.DeviceID, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read, [System.IntPtr]::Zero, [System.IO.FileMode]::Open, [System.UInt32]0x02000000)
		
		if ($Handle -ne -1) {
			$SafeHandle = New-Object Microsoft.Win32.SafeHandles.SafeFileHandle $Handle, $True
			$FileStream = New-Object System.IO.FileStream $SafeHandle, ([System.IO.FileAccess]::Read)
			$BinReader = New-Object System.IO.BinaryReader $FileStream
			
			#region Parse MBR
			$MasterBootRecord = New-Object PSObject
			# Read first 440 bytes of the drive. This is the Bootstrap code
			$MBR = $BinReader.ReadBytes(440)
			$MBRMD5Hash = [System.BitConverter]::ToString($MD5.ComputeHash($MBR)) -replace "-",""
			Add-Member -InputObject $MasterBootRecord -MemberType NoteProperty -Name "BootstrapCode" -Value ([System.BitConverter]::ToString($MBR) -replace "-","")
			Remove-Variable -Name MBR

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
			Add-Member -InputObject $MasterBootRecord -MemberType NoteProperty -Name "MBRType" -Value $MBRType
			Remove-Variable -Name MBRMD5Hash
			Remove-Variable -Name MBRType

			# Next 4 bytes is the drive's signature. Should match the REG_BINARY key at HKLM\System\MountedDevices under the key for the drive letter
			Add-Member -InputObject $MasterBootRecord -MemberType NoteProperty -Name DriveSignature -Value ([System.BitConverter]::ToString($BinReader.ReadBytes(4)) -replace "-","")

			# Next 2 bytes is 0x0000
			$BinReader.ReadBytes(2) | Out-Null
			$BinReader.ReadBytes(4) | Out-Null
			if (([System.BitConverter]::ToString($BinReader.ReadBytes(1)) -replace "-","") -eq "EE") {
				Add-Member -InputObject $MasterBootRecord -MemberType NoteProperty -Name PartitionTableType -Value "GPT"
				$BinReader.ReadBytes(3) | Out-Null
				$GPTOffset = [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
				$FileStream.Position = $GPTOffset * 512
				$BinReader.ReadBytes(56) | Out-Null
				
				$GUID = [System.BitConverter]::ToString($BinReader.ReadBytes(16)) -split "-"
				Add-Member -InputObject $MasterBootRecord -MemberType NoteProperty -Name GPTGUID -Value ("$($GUID[3])$($GUID[2])$($GUID[1])$($GUID[0])-$($GUID[5])$($GUID[4])-$($GUID[7])$($GUID[6])-$($GUID[8])$($GUID[9])-$($GUID[10])$($GUID[11])$($GUID[12])$($GUID[13])$($GUID[14])$($GUID[15])")
				Remove-Variable -Name GUID
				Add-Member -InputObject $MasterBootRecord -MemberType NoteProperty -Name PartitionTableLBA -Value [System.BitConverter]::ToUInt64($BinReader.ReadBytes(8),0)
				Add-Member -InputObject $MasterBootRecord -MemberType NoteProperty -Name PartitionEntries -Value [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
				Add-Member -InputObject $MasterBootRecord -MemberType NoteProperty -Name PartitionEntrySize -Value [System.BitConverter]::ToUInt32($BinReader.ReadBytes(4),0)
			} else {
				Add-Member -InputObject $MasterBootRecord -MemberType NoteProperty -Name PartitionTableType -Value "MBR"
			}
			Remove-Variable -Name BinReader
			Remove-Variable -Name FileStream
			Remove-Variable -Name SafeHandle
			$Kernel32::CloseHandle($Handle)

			return $MasterBootRecord
		}
	}
}