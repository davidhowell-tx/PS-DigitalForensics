function Get-BytesFromStream {
	<#
	.SYNOPSIS
		Reads bytes from a filestream and returns a byte array.
	
	.PARAMETER Stream
	.PARAMETER Length
	.PARAMETER Optional Offset
	
	.NOTES
		Author: David Howell
		Last Modified: 02/15/2016
	#>
	Param(
		[Parameter(Mandatory=$True)]
		[ValidateScript({ $_.GetType().BaseType.FullName -eq "System.IO.Stream"})]
		$Stream,
		
		[Parameter(Mandatory=$True)]
		[System.Int64]
		$Length,
		
		[Parameter(Mandatory=$False)]
		[System.Int64]
		$Offset
	)
	
	if ($Offset -ge 0 ) {
		$Stream.Seek($Offset,[System.IO.SeekOrigin]::Begin) | Out-Null
	} elseif (-not ($Offset)) {
		$Offset = $Stream.Position
	}

	[Byte[]]$ByteArray = New-Object Byte[] $Length
	$Stream.Read($ByteArray, 0, $Length) | Out-Null
	$ByteArray
}