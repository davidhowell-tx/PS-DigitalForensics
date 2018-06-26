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
		Last Modified: 02/18/2016
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
	}
}
