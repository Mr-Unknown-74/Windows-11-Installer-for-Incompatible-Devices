$drvlet = Get-ChildItem function:[d-z]: -n | Where-Object{ !(test-path $_) } | Select-Object -First 1
$path = $PSScriptRoot
$isoImgFolder = "$path\Copy the ISO file here\"
$isoImg = Get-ChildItem $isoImgFolder -Name -Recurse -Include *.iso | Select-Object -First 1
$isoImgPath = "$isoImgFolder$isoImg"
$IsoFiles = "$path\Code\ISO"
$diskImg = Mount-DiskImage -ImagePath "C:\Users\MrUnk\OneDrive\Coding Projects\Windows 11 installer for incompatible divices\Copy the ISO file here\Windows.iso"  -NoDriveLetter
$volInfo = $diskImg | Get-Volume
mountvol $drvlet $volInfo.UniqueId
Write-Output ("Extracting files... This may take a while.")
cmd.exe /c Xcopy "$drvlet\" "$IsoFiles" /E /F /Q
Start-Process "$path\Code\Install.cmd"
DisMount-DiskImage -ImagePath $isoImgPath  