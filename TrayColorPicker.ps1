Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$source = @'
using System;
using System.Diagnostics;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace TrayColorPicker
{
    internal static class NativeMethods
    {
        public const int WH_MOUSE_LL = 14;
        public const int WH_KEYBOARD_LL = 13;
        public const int WM_LBUTTONDOWN = 0x0201;
        public const int WM_KEYDOWN = 0x0100;
        public const int WM_SYSKEYDOWN = 0x0104;
        public const int VK_ESCAPE = 0x1B;

        public const uint SPI_SETCURSORS = 0x0057;
        public const int IDC_CROSS = 32515;

        [StructLayout(LayoutKind.Sequential)]
        public struct POINT
        {
            public int X;
            public int Y;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct MSLLHOOKSTRUCT
        {
            public POINT pt;
            public uint mouseData;
            public uint flags;
            public uint time;
            public UIntPtr dwExtraInfo;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct KBDLLHOOKSTRUCT
        {
            public uint vkCode;
            public uint scanCode;
            public uint flags;
            public uint time;
            public UIntPtr dwExtraInfo;
        }

        public delegate IntPtr LowLevelMouseProc(int nCode, IntPtr wParam, IntPtr lParam);
        public delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr SetWindowsHookEx(int idHook, LowLevelMouseProc lpfn, IntPtr hMod, uint dwThreadId);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool UnhookWindowsHookEx(IntPtr hhk);

        [DllImport("user32.dll")]
        public static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern IntPtr GetModuleHandle(string lpModuleName);

        [DllImport("user32.dll")]
        public static extern IntPtr GetDC(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC);

        [DllImport("gdi32.dll")]
        public static extern uint GetPixel(IntPtr hdc, int nXPos, int nYPos);

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool GetCursorPos(out POINT lpPoint);

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetProcessDPIAware();

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern IntPtr LoadCursorFromFile(string lpFileName);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr LoadCursor(IntPtr hInstance, IntPtr lpCursorName);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr CopyIcon(IntPtr hIcon);

        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetSystemCursor(IntPtr hcur, uint id);

        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);
    }

    internal sealed class ColorPreviewForm : Form
    {
        private Color currentColor = Color.Black;
        private string currentHex = "#000000";

        private const int PreviewWidth = 92;
        private const int PreviewHeight = 112;
        private const int SwatchSize = 76;
        private const int Gap = 24;

        public ColorPreviewForm()
        {
            FormBorderStyle = FormBorderStyle.None;
            ShowInTaskbar = false;
            TopMost = true;
            StartPosition = FormStartPosition.Manual;
            Size = new Size(PreviewWidth, PreviewHeight);
            BackColor = Color.White;
            DoubleBuffered = true;
        }

        protected override bool ShowWithoutActivation
        {
            get { return true; }
        }

        protected override CreateParams CreateParams
        {
            get
            {
                const int WS_EX_NOACTIVATE = 0x08000000;
                const int WS_EX_TOOLWINDOW = 0x00000080;

                CreateParams cp = base.CreateParams;
                cp.ExStyle |= WS_EX_NOACTIVATE | WS_EX_TOOLWINDOW;
                return cp;
            }
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);

            e.Graphics.Clear(Color.White);

            Rectangle swatchRect = new Rectangle(7, 7, SwatchSize, SwatchSize);
            using (SolidBrush brush = new SolidBrush(currentColor))
                e.Graphics.FillRectangle(brush, swatchRect);

            using (Pen swatchBorder = new Pen(Color.FromArgb(35, 35, 35), 2.0f))
                e.Graphics.DrawRectangle(swatchBorder, swatchRect);

            using (Font font = new Font("Segoe UI", 9.0f, FontStyle.Bold, GraphicsUnit.Point))
            using (SolidBrush textBrush = new SolidBrush(Color.FromArgb(28, 28, 28)))
            using (StringFormat format = new StringFormat())
            {
                format.Alignment = StringAlignment.Center;
                format.LineAlignment = StringAlignment.Center;
                RectangleF textRect = new RectangleF(2, 86, Width - 4, 22);
                e.Graphics.DrawString(currentHex, font, textBrush, textRect, format);
            }

            using (Pen border = new Pen(Color.FromArgb(75, 75, 75), 1.0f))
                e.Graphics.DrawRectangle(border, 0, 0, Width - 1, Height - 1);
        }

        public void UpdatePreview(int cursorX, int cursorY, Color color, string hex)
        {
            currentColor = color;
            currentHex = hex;

            Point cursor = new Point(cursorX, cursorY);
            Rectangle bounds = Screen.FromPoint(cursor).WorkingArea;

            int left = cursorX + Gap;
            int top = cursorY + Gap;

            if (left + Width > bounds.Right)
                left = cursorX - Gap - Width;

            if (top + Height > bounds.Bottom)
                top = cursorY - Gap - Height;

            if (left < bounds.Left)
                left = bounds.Left;
            if (top < bounds.Top)
                top = bounds.Top;

            Location = new Point(left, top);

            if (!Visible)
                Show();

            BringToFront();
            Invalidate();
            Update();
        }
    }

    public static class App
    {
        private static NotifyIcon tray;
        private static ContextMenuStrip menu;
        private static ToolStripMenuItem pickItem;
        private static ToolStripMenuItem lastItem;
        private static IntPtr mouseHook = IntPtr.Zero;
        private static IntPtr keyboardHook = IntPtr.Zero;
        private static bool picking = false;
        private static bool cursorsChanged = false;
        private static string lastHex = null;
        private static string pickerCursorPath = null;
        private static ColorPreviewForm preview;
        private static Timer previewTimer;

        private static readonly NativeMethods.LowLevelMouseProc mouseProc = MouseHookCallback;
        private static readonly NativeMethods.LowLevelKeyboardProc keyboardProc = KeyboardHookCallback;

        private static readonly uint[] CursorIds = new uint[]
        {
            32512, // OCR_NORMAL
            32513, // OCR_IBEAM
            32514, // OCR_WAIT
            32515, // OCR_CROSS
            32516, // OCR_UP
            32640, // OCR_SIZE
            32641, // OCR_ICON
            32642, // OCR_SIZENWSE
            32643, // OCR_SIZENESW
            32644, // OCR_SIZEWE
            32645, // OCR_SIZENS
            32646, // OCR_SIZEALL
            32648, // OCR_NO
            32649, // OCR_HAND
            32650, // OCR_APPSTARTING
            32651  // OCR_HELP
        };

        public static void Run(string iconPath, string cursorPath)
        {
            try { NativeMethods.SetProcessDPIAware(); } catch { }

            pickerCursorPath = cursorPath;

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            tray = new NotifyIcon();
            tray.Text = "Tray Color Picker";
            tray.Visible = true;

            try
            {
                if (!String.IsNullOrWhiteSpace(iconPath) && System.IO.File.Exists(iconPath))
                    tray.Icon = new Icon(iconPath);
                else
                    tray.Icon = SystemIcons.Application;
            }
            catch
            {
                tray.Icon = SystemIcons.Application;
            }

            menu = new ContextMenuStrip();

            pickItem = new ToolStripMenuItem("Pick color");
            pickItem.Click += delegate { StartPicking(); };
            menu.Items.Add(pickItem);

            lastItem = new ToolStripMenuItem("Last color: -");
            lastItem.Enabled = false;
            lastItem.Click += delegate
            {
                if (!String.IsNullOrEmpty(lastHex))
                    CopyToClipboard(lastHex);
            };
            menu.Items.Add(lastItem);

            menu.Items.Add(new ToolStripSeparator());

            ToolStripMenuItem aboutItem = new ToolStripMenuItem("About");
            aboutItem.Click += delegate
            {
                MessageBox.Show(
                    "Left-click the tray icon to pick a color.\n\n" +
                    "Move the eyedropper anywhere on screen. A live preview shows the color under the pointer and its HEX value.\n\n" +
                    "Click to copy #RRGGBB to the clipboard. Press Esc to cancel.",
                    "Tray Color Picker",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information);
            };
            menu.Items.Add(aboutItem);

            ToolStripMenuItem exitItem = new ToolStripMenuItem("Exit");
            exitItem.Click += delegate { Exit(); };
            menu.Items.Add(exitItem);

            tray.ContextMenuStrip = menu;
            tray.MouseClick += Tray_MouseClick;

            preview = new ColorPreviewForm();

            previewTimer = new Timer();
            previewTimer.Interval = 30;
            previewTimer.Tick += delegate { UpdateLivePreview(); };

            Application.ApplicationExit += delegate { Cleanup(); };
            Application.Run();
        }

        private static void Tray_MouseClick(object sender, MouseEventArgs e)
        {
            if (e.Button == MouseButtons.Left)
                StartPicking();
        }

        private static void StartPicking()
        {
            if (picking)
                return;

            picking = true;
            pickItem.Text = "Picking... (Esc to cancel)";
            tray.Text = "Tray Color Picker - click a pixel";

            IntPtr moduleHandle = IntPtr.Zero;
            try
            {
                using (Process currentProcess = Process.GetCurrentProcess())
                using (ProcessModule currentModule = currentProcess.MainModule)
                {
                    moduleHandle = NativeMethods.GetModuleHandle(currentModule.ModuleName);
                }
            }
            catch { }

            mouseHook = NativeMethods.SetWindowsHookEx(NativeMethods.WH_MOUSE_LL, mouseProc, moduleHandle, 0);
            keyboardHook = NativeMethods.SetWindowsHookEx(NativeMethods.WH_KEYBOARD_LL, keyboardProc, moduleHandle, 0);

            if (mouseHook == IntPtr.Zero)
            {
                picking = false;
                FinishPickingState();
                MessageBox.Show(
                    "Could not start the color picker.",
                    "Tray Color Picker",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
                return;
            }

            ApplyPickerCursor();
            UpdateLivePreview();
            previewTimer.Start();
        }

        private static void UpdateLivePreview()
        {
            if (!picking || preview == null)
                return;

            NativeMethods.POINT pt;
            if (!NativeMethods.GetCursorPos(out pt))
                return;

            Color color;
            string hex;
            if (!TryReadColor(pt.X, pt.Y, out color, out hex))
                return;

            preview.UpdatePreview(pt.X, pt.Y, color, hex);
        }

        private static bool TryReadColor(int x, int y, out Color color, out string hex)
        {
            color = Color.Black;
            hex = "#000000";

            IntPtr hdc = NativeMethods.GetDC(IntPtr.Zero);
            if (hdc == IntPtr.Zero)
                return false;

            uint colorRef;
            try
            {
                colorRef = NativeMethods.GetPixel(hdc, x, y);
            }
            finally
            {
                NativeMethods.ReleaseDC(IntPtr.Zero, hdc);
            }

            if (colorRef == 0xFFFFFFFF)
                return false;

            int r = (int)(colorRef & 0xFF);
            int g = (int)((colorRef >> 8) & 0xFF);
            int b = (int)((colorRef >> 16) & 0xFF);

            color = Color.FromArgb(r, g, b);
            hex = String.Format("#{0:X2}{1:X2}{2:X2}", r, g, b);
            return true;
        }

        private static void ApplyPickerCursor()
        {
            bool anyChanged = false;

            for (int i = 0; i < CursorIds.Length; i++)
            {
                IntPtr hCursor = IntPtr.Zero;

                try
                {
                    if (!String.IsNullOrWhiteSpace(pickerCursorPath) && System.IO.File.Exists(pickerCursorPath))
                        hCursor = NativeMethods.LoadCursorFromFile(pickerCursorPath);

                    if (hCursor == IntPtr.Zero)
                    {
                        IntPtr cross = NativeMethods.LoadCursor(IntPtr.Zero, new IntPtr(NativeMethods.IDC_CROSS));
                        if (cross != IntPtr.Zero)
                            hCursor = NativeMethods.CopyIcon(cross);
                    }

                    if (hCursor != IntPtr.Zero && NativeMethods.SetSystemCursor(hCursor, CursorIds[i]))
                        anyChanged = true;
                }
                catch { }
            }

            cursorsChanged = anyChanged;
        }

        private static void RestoreSystemCursors()
        {
            if (!cursorsChanged)
                return;

            try
            {
                NativeMethods.SystemParametersInfo(NativeMethods.SPI_SETCURSORS, 0, IntPtr.Zero, 0);
            }
            catch { }

            cursorsChanged = false;
        }

        private static IntPtr MouseHookCallback(int nCode, IntPtr wParam, IntPtr lParam)
        {
            if (nCode >= 0 && picking && wParam.ToInt32() == NativeMethods.WM_LBUTTONDOWN)
            {
                NativeMethods.MSLLHOOKSTRUCT info =
                    (NativeMethods.MSLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(NativeMethods.MSLLHOOKSTRUCT));

                PickAt(info.pt.X, info.pt.Y);
                return new IntPtr(1);
            }

            return NativeMethods.CallNextHookEx(mouseHook, nCode, wParam, lParam);
        }

        private static IntPtr KeyboardHookCallback(int nCode, IntPtr wParam, IntPtr lParam)
        {
            if (nCode >= 0 && picking &&
                (wParam.ToInt32() == NativeMethods.WM_KEYDOWN || wParam.ToInt32() == NativeMethods.WM_SYSKEYDOWN))
            {
                NativeMethods.KBDLLHOOKSTRUCT info =
                    (NativeMethods.KBDLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(NativeMethods.KBDLLHOOKSTRUCT));

                if (info.vkCode == NativeMethods.VK_ESCAPE)
                {
                    CancelPicking();
                    return new IntPtr(1);
                }
            }

            return NativeMethods.CallNextHookEx(keyboardHook, nCode, wParam, lParam);
        }

        private static void PickAt(int x, int y)
        {
            if (!picking)
                return;

            picking = false;

            if (previewTimer != null)
                previewTimer.Stop();

            Color color;
            string hex;
            bool ok = TryReadColor(x, y, out color, out hex);

            if (preview != null)
                preview.Hide();

            FinishPickingState();

            if (!ok)
                return;

            lastHex = hex;
            lastItem.Text = "Last color: " + hex + "  (click to copy)";
            lastItem.Enabled = true;

            CopyToClipboard(hex);
        }

        private static void CopyToClipboard(string text)
        {
            try
            {
                Clipboard.SetText(text);
            }
            catch
            {
                System.Threading.Thread.Sleep(80);
                try { Clipboard.SetText(text); } catch { }
            }
        }

        private static void CancelPicking()
        {
            if (!picking)
                return;

            picking = false;
            FinishPickingState();
        }

        private static void FinishPickingState()
        {
            if (previewTimer != null)
                previewTimer.Stop();

            if (preview != null && preview.Visible)
                preview.Hide();

            RestoreSystemCursors();

            if (mouseHook != IntPtr.Zero)
            {
                NativeMethods.UnhookWindowsHookEx(mouseHook);
                mouseHook = IntPtr.Zero;
            }

            if (keyboardHook != IntPtr.Zero)
            {
                NativeMethods.UnhookWindowsHookEx(keyboardHook);
                keyboardHook = IntPtr.Zero;
            }

            if (pickItem != null)
                pickItem.Text = "Pick color";
            if (tray != null)
                tray.Text = "Tray Color Picker";
        }

        private static void Exit()
        {
            Cleanup();
            Application.Exit();
        }

        private static void Cleanup()
        {
            picking = false;
            FinishPickingState();

            if (previewTimer != null)
            {
                previewTimer.Dispose();
                previewTimer = null;
            }

            if (preview != null)
            {
                preview.Dispose();
                preview = null;
            }

            if (tray != null)
            {
                tray.Visible = false;
                tray.Dispose();
                tray = null;
            }

            if (menu != null)
            {
                menu.Dispose();
                menu = null;
            }
        }
    }
}
'@

Add-Type -TypeDefinition $source -Language CSharp -ReferencedAssemblies @(
    'System.dll',
    'System.Drawing.dll',
    'System.Windows.Forms.dll'
)

$iconPath = Join-Path $PSScriptRoot 'TrayColorPicker.ico'
$cursorPath = Join-Path $PSScriptRoot 'Eyedropper.cur'
[TrayColorPicker.App]::Run($iconPath, $cursorPath)
