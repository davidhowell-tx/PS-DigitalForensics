# Invoke-AppCompatCacheParser
Invoke-AppCompatCacheParser is my attempt to parse the Shim Cache (or Application Compatibility Cache) using PowerShell.

I've only performed limited testing of this script on Windows 7 and Windows 8.1, with PowerShell version 3 and 4 respectively.  If issues arise from other Operating Systems and PowerShell versions, please let me know and I will see if I can fix it.

# Usage
.\Invoke-AppCompatCacheParser.ps1

.\Invoke-AppCompatCacheParser.ps1 -Path C:\Temp\AppCompatCache.reg

# Thanks
Thanks to Mandiant for their Whitepaper on Shim Cache:
(https://dl.mandiant.com/EE/library/Whitepaper_ShimCacheParser.pdf)

Thanks to Harlan Carvey for his Perl Script that performs the same task, AppCompatCache.pl.  This is what really helped me port this over to PowerShell:
(https://github.com/keydet89/RegRipper2.8/blob/master/plugins/appcompatcache.pl)