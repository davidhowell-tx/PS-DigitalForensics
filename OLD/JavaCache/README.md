

# Invoke-JavaCacheParser
Invoke-JavaCacheParser is my attempt to parse forensic artifacts from .idx files (Java Cache) using PowerShell.

I tested and wrote this on Windows 7 with PowerShell version 3.0.  I am unsure if this works on other PowerShell versions or OS versions.

I have only allocated enough time to parse through some of the "Section 2" data which tells you the source of the original java file.  There is more that can be parsed that I have not added yet.

# Features
* Multiple Input Options
  * Default run with no switches will look in default locations for .idx files to parse.
  * Use -FullName switch to specify a specific .idx files to parse, if you have a one off (-FilePath is an alias that works this way also).
  * Use the Pipeline Input if you have a directory full of .idx files to parse.
    * For Example: Get-ChildItem -Path "C:\IDXFiles" -Recurse -Filter *.idx | Select-Object -Property FullName | Invoke-JavaCacheParser.ps1
* Modified Version to work with Dave Hull's Kansa project (https://github.com/davehull/Kansa)

# Goals
* Modify LocalHost processing to work on more than just Windows 7

# Thanks
Thanks to GitHub user "woanware" for his amazing documentation on .idx format
(https://github.com/woanware/javaidx)

Also Thanks to Forensics Wiki for information on Java Cache:
(http://www.forensicswiki.org/wiki/Java)

Thanks to Dave Hull and his Kansa project for motivating me to write PowerShell scripts for use in Incident Response.
