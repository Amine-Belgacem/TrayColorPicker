Option Explicit
Dim shell, fso, baseDir, sourcePath, startupDir, shortcutPath, shortcut
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
baseDir = fso.GetParentFolderName(WScript.ScriptFullName)
sourcePath = baseDir & "\Start Tray Color Picker.vbs"
startupDir = shell.SpecialFolders("Startup")
shortcutPath = startupDir & "\Tray Color Picker.lnk"
Set shortcut = shell.CreateShortcut(shortcutPath)
shortcut.TargetPath = "wscript.exe"
shortcut.Arguments = Chr(34) & sourcePath & Chr(34)
shortcut.WorkingDirectory = baseDir
shortcut.Description = "Start Tray Color Picker with Windows"
shortcut.Save
MsgBox "Tray Color Picker will now start with Windows.", 64, "Tray Color Picker"
