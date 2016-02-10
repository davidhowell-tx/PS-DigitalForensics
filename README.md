# PS-WindowsForensics
PowerShell scripts for parsing forensic artifacts in the Windows operating system, and the documentation I've created along the way.  

Information regarding data structures have been pulled from a number of sources including the ForensicsWiki, Harlan Carvey's RegRipper code, and various whitepapers and forensic professionals.  I have done my best to cite all of my sources in each of the scripts, and in this readme.  I apologize for any I've forgotten.

# UPDATE
I've shifted my focus towards Hard Drive forensics, rather than just Windows OS forensics. My initial thought was to come up with a method to access files to parse forensic artifacts in a manner that will not modify accessed timestamps.  This led to a full scale hard disk and file system forensics project.
My current goals are to complete this task by coding completely in PowerShell, not in any other language such as C# (like PowerForensics) so I can easily execute the scripts against remote hosts through WinRM.
Additionally, I do not want to use Add-Type to p\invoke managed code, as doing so causes runtime compiling.  Instead, I've rewritten C# P\Invoke code to use .NET Reflection inside of PowerShell to create the code in memory at runtime.

# Scripts
| Full Version | Lite Version (for Kansa or Invoke-LiveResponse) |
| --- | --- |
| Invoke-AppCompatCacheParser.ps1 | Get-AppCompatCache.ps1 |
| Invoke-JavaCacheParser.ps1 | Get-JavaCache.ps1 |
| Invoke-PrefetchParser.ps1 | Get-Prefetch.ps1 |
| Get-BootRecord.ps1 | |
| Get-PartitionTable.ps1 | |
| Get-VolumeBootRecord.ps1 | |

# Goals
1. Provide scripts that can be run on Windows systems without requiring any additional software download/installation
2. Provide scripts that can be run against live Windows systems
3. Provide scripts that can be run against most Windows systems
  * PowerShell Version 3 if possible
  * Lowest version of .NET possible, but most everything I find has at least 4
4. Provide scripts that can easily be run, or modified to run, in a PowerShell session.

# Thanks
Thanks to Harlan Carvey and his RegRipper tool for providing a lot of help working through the data structures (and for providing a great tool): https://github.com/keydet89/RegRipp2.8
Thanks to the Forensics Wiki: http://forensicswiki.org/wiki/Main_Page


