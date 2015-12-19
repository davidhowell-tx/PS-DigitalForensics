# Invoke-PrefetchParser
Invoke-PrefetchParser is my attempt to parse information out of Prefetch files.

I've performed only limited testing with Windows 8.1 and Windows 7 and PowerShell version 4 at this time.

Currently hoping to get a copy of some prefetch files from WinXP, Vista, and 10 to extend testing.

# Usage
.\Invoke-PrefetchParser.ps1 -Path C:\Windows\Prefetch\executable-hash.pf

Get-ChildItem -Path C:\Windows\Prefetch -Filter *.pf | ForEach-Object { .\Invoke-PrefetchParser.ps1 -FilePath $_.FullName }

# Notes
I don't parse all of the availabe information in the prefetch file for output, though the script does read through the structures as if it were going to parse each piece of information, with a lot of information being sent to a null output (look for Out-Null in the script).  I only did this for completeness sake, and just in case anyone wants to modify this script to parse everything it should be a little bit easier.

# Thanks
Info regarding Prefetch data structures was pulled from the following articles:

http://www.forensicswiki.org/wiki/Windows_Prefetch_File_Format

Thanks to Yogesh Khatri for this info.

http://www.swiftforensics.com/2010/04/the-windows-prefetchfile.html

http://www.swiftforensics.com/2013/10/windows-prefetch-pf-files.html