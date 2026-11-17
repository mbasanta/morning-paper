# Windows setup and delivery

Use native Windows PowerShell 5.1 or later on the computer that will render and print. No WSL, Bash,
CUPS or Python is needed for the Windows scripts. If Claude can only run code in a remote or Linux
sandbox, it cannot access the Windows printer: have the reader run the local commands, or offer
email/save-only delivery. Do not claim a local setup or print succeeded without checking it.

## Setup

1. Use Chrome, Edge or Chromium to render PDFs. The script checks PATH and the usual per-user,
   Program Files and Program Files (x86) installation locations. Use `-BrowserPath` for a custom
   browser location.
2. Resolve the actual Documents folder, including OneDrive or other redirection:
   ```powershell
   $paper = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Morning Paper'
   New-Item -ItemType Directory -Path (Join-Path $paper 'editions') -Force | Out-Null
   ```
   Record its absolute path in `config.md`; use a different folder if the reader requests one.
3. If printing, list the installed Windows printers:
   ```powershell
   Get-Printer | Select-Object Name, PrinterStatus
   ```
   Let the reader pick the exact name. Avoid file-output printers such as Microsoft Print to PDF
   for unattended delivery: they may prompt for a filename.
4. Automatic printing uses [SumatraPDF](https://www.sumatrapdfreader.org/free-pdf-reader), not the
   default PDF app's Print verb (which may open a dialog or ignore the selected printer). Ask the
   reader to install it if needed; a portable copy also works with `-SumatraPdfPath`. It is optional
   for email/save-only delivery. Never silently change delivery modes if it is missing.

The examples below assume the Claude Code install location. For an uploaded skill, replace `$skill`
with the actual local skill folder. Replace `YYYY-MM-DD` with the edition's date. Record the working
commands, with absolute quoted paths, in `config.md`.

```powershell
$skill = Join-Path $HOME '.claude\skills\morning-paper'
$paper = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Morning Paper'
& "$skill\scripts\render_pdf.ps1" -HtmlPath "$paper\editions\YYYY-MM-DD.html"
```

The renderer writes the PDF next to the HTML and reports `path: N page(s)`. Check the count against
the configured length and trim/re-render if needed, just as on macOS/Linux. Stop delivery if rendering
fails; an older PDF may still exist and must not be sent as today's edition.

If downloaded scripts are blocked, review them first. Where local policy permits, invoke the script
in a separate PowerShell process with a process-only execution policy:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$skill\scripts\render_pdf.ps1" -HtmlPath "$paper\editions\YYYY-MM-DD.html"
if ($LASTEXITCODE -ne 0) { throw 'Rendering failed; do not deliver this edition.' }
```

The same invocation works for `print_pdf.ps1`. Do not change the machine-wide execution policy.
If organizational policy blocks scripts, ask the administrator rather than trying to bypass it.

## Print

```powershell
& "$skill\scripts\print_pdf.ps1" -PdfPath "$paper\editions\YYYY-MM-DD.pdf" -PrinterName "Office printer" -PaperSize Letter
```

Use `-PaperSize A4` if configured (and set the template's CSS `@page` size to A4). Add `-Duplex` for
two-sided, long-edge printing only when the printer supports it. For a portable or custom install,
add `-SumatraPdfPath "C:\Tools\SumatraPDF\SumatraPDF.exe"`.

The script waits for SumatraPDF and checks its exit code. Success means the job was submitted, not
that paper physically came out: offline, out-of-paper and spooler errors can happen afterward.
On failure, inspect that printer's queue:

```powershell
Get-PrintJob -PrinterName "Office printer"
```

Only remove a job confirmed to be this skill's failed edition, using its specific ID:

```powershell
Remove-PrintJob -PrinterName "Office printer" -ID 123
```

Never clear the whole queue or another person's jobs. Retry at most once after checking whether
the original job already printed; otherwise leave the PDF saved and report the failure.
SumatraPDF's [command-line reference](https://www.sumatrapdfreader.org/docs/Command-line-arguments)
describes the print options and exit codes.

## Schedule and keep awake

Use Claude desktop's `create_scheduled_task` when available, with the absolute Windows paper-folder
path in the prompt. Leave the app running, the reader signed in, and the computer plugged in and
awake. On Windows 11, use Settings > System > Power & battery > Screen and sleep (called "Screen,
sleep & hibernate timeouts" on some versions); set plugged-in sleep to Never. On Windows 10, use
Settings > System > Power & sleep. The screen may still turn off.

If Claude's scheduling tool is unavailable, explain that the schedule has not been created.
Windows Task Scheduler can launch an already configured local Claude Code build command, but
running only `render_pdf.ps1` does not gather calendar, inbox or news data and is not a daily build.
Agree on a working build command and verify a one-off run before scheduling it. Do not change power
settings or create a persistent Windows task without the reader's approval.
