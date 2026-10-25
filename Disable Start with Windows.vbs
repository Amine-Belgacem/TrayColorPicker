Option Explicit
Dim shell, fso, startupDir, shortcutPath
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
startupDir = shell.SpecialFolders("Startup")
shortcutPath = startupDir & "\Tray Color Picker.lnk"
If fso.FileExists(shortcutPath) Then
    fso.DeleteFile shortcutPath, True
    MsgBox "Tray Color Picker was removed from Windows startup.", 64, "Tray Color Picker"
Else
    MsgBox "Tray Color Picker is not currently in Windows startup.", 64, "Tray Color Picker"
End If
