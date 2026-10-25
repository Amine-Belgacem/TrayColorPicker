Tray Color Picker v3
====================

A tiny Windows tray color picker.

HOW TO RUN
1. Extract the folder somewhere permanent.
2. Double-click: Start Tray Color Picker.vbs
3. A color-wheel icon appears in the Windows system tray.

HOW TO USE
- Left-click the tray icon to start picking.
- The mouse pointer becomes an eyedropper.
- A live floating preview follows the pointer and shows:
  * a square filled with the exact pixel color under the pointer
  * the live HEX value (#RRGGBB)
- Click anywhere to copy that HEX color to the clipboard.
- Press Esc to cancel.
- Right-click the tray icon for Pick color, Last color, About, and Exit.

CHANGES IN V3
- Removed all normal pick/copy/cancel notification popups.
- Added a live color preview beside the mouse pointer.
- Added a live HEX readout under the preview square.
- The preview stays out of the way of the pixel being sampled.

START WITH WINDOWS
Run "Enable Start with Windows.vbs" once.
Use "Disable Start with Windows.vbs" to remove it from startup.

NOTES
- The VBS file is only a silent launcher so no PowerShell console stays open.
- The utility itself is implemented in TrayColorPicker.ps1 using Windows Forms and native Windows APIs.
- No Python or extra runtime installation is required on normal Windows 10/11 systems.

V4 note: the live color hint now uses a normal always-on-top painted window for better Windows compatibility.
