function Get-BootRecord {
	﻿<#
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
	$MD5 = New-Object System.Security.Cryptography.MD5CryptoServiceProvider

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
}
