

# PowerShell Application Compatibility Cache Parser
Invoke-AppCompatCacheParser is my attempt to parse the Shim Cache (or Application Compatibility Cache) using PowerShell.

I've only performed limited testing of this script on Windows 7 and Windows 8, with PowerShell version 3 and 4 respectively.  If issues arise from other Operating Systems and PowerShell versions, please let me know and I will see if I can fix it.

# Features
* Multiple Input Options
  * Default run with no switches will pull the AppCompatCache from the Registry on the current system
  * Use -Reg switch to specify a .reg file to parse.  
    * This can be acquired by performing reg export "HKLM\System\CurrentControlSet\Control\Session Manager\AppCompatCache" C:\ExportPath\AppCompat.reg

# Thanks
Thanks to Mandiant for their Whitepaper on Shim Cache:
(https://dl.mandiant.com/EE/library/Whitepaper_ShimCacheParser.pdf)

Thanks to Harlan Carvey for his Perl Script that performs the same task, AppCompatCache.pl.  This is what really helped me port this over to PowerShell:
(https://github.com/keydet89/RegRipper2.8/blob/master/plugins/appcompatcache.pl)

Thanks to Dave Hull and his Kansa project for motivating me to write PowerShell scripts for use in Live Incident Response.
