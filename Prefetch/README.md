# Invoke-PrefetchParser
Invoke-PrefetchParser is my attempt to parse information out of Prefetch files.

I've performed only limited testing with Windows 8 and PowerShell version 4 at this time.

Currently hoping to get a copy of some prefetch files from WinXP, Vista, 7, and 10 to extend testing.

# Usage
.\Invoke-PrefetchParser.ps1 -Path C:\Windows\Prefetch\executable-hash.pf

Get-ChildItem -Path C:\Windows\Prefetch -Filter *.pf | ForEach-Object { .\Invoke-PrefetchParser.ps1 -FilePath $_.FullName }

# Thanks
Info regarding Prefetch data structures was pulled from the following articles:

Thanks to Yogesh Khatri for this info.

http://www.swiftforensics.com/2010/04/the-windows-prefetchfile.html

http://www.swiftforensics.com/2013/10/windows-prefetch-pf-files.html