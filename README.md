# Morning Paper

A Claude skill that builds you a newspaper-style briefing (one page by default) every morning from your calendar,
inbox, to-do list and the news, then prints it (or emails it to you). You scribble on it, snap a
photo, send it back to Claude, and your notes turn into done items, new to-dos and email drafts.

![A sample edition](docs/preview.png)

## Play around with it

This is a base idea, not a finished product. It started as one person's printed morning paper, and it
is meant for you to expand on yourself: add sections, cut the ones you never read, change the news
topics, restyle the template. Just tell Claude what you want different and it edits your setup.

Don't have a printer, or rather not print? Pick email delivery during setup. The paper arrives in your
inbox and you reply to it with your notes instead.

## What it asks you when you set it up

1. **Sections:** tick the ones you want: Today's Lead, Schedule, Countdown (to anything you like: a
   trip, a launch, a race), Inbox Overnight, To-Do Desk, Ideas File, People Worth Meeting, Write-in box.
2. **Time, delivery and length:** when it arrives, which days, print, email, both, or just save the
   PDF, and how long (one page, two pages, or as long as it needs).
3. **News:** yes or no (with an optional Business column).
4. **Sources and topics:** your favourite outlets and up to 4 topics.
5. **To-do list:** where yours lives (Notion, Todoist, Google Tasks, Apple Reminders, a file).
6. **Keeping your computer awake:** do you need help setting that up? (See below.)

Then it builds your first edition on the spot and schedules the rest.

## Heads up: your computer has to be awake

The paper is made by a scheduled task that runs on your computer, in the Claude desktop app. If the
computer is asleep or the app is closed at print time, the paper waits until you open it and arrives
late. Setup offers to walk you through keeping it awake (a power setting, or a scheduled wake just
before print time). Keep it plugged in and leave the Claude app open.

## Install

**Claude desktop app or claude.ai:** download [`morning-paper.skill`](morning-paper.skill), then in
Claude go to Customize > Skills > + > Upload a skill. (Skills need code execution turned on under
Settings > Capabilities.)

**Claude Code:** copy the [`morning-paper`](morning-paper) folder into `~/.claude/skills/` on
macOS/Linux, or `%USERPROFILE%\.claude\skills\` on Windows.

Then say: **"Set up my morning paper."**

## What you need

- Claude with connectors for whatever sections you choose (calendar, email, your to-do app). Setup
  only offers sources you have connected.
- Google Chrome or Chromium to render PDFs. On Windows or macOS, Microsoft Edge also works;
  Windows can use its existing Edge installation.
- On macOS/Linux: Bash and Python 3 for the renderer, and `lp`/CUPS for printing.
- On Windows: PowerShell 5.1 or later (included with Windows). For automatic printing, also install
  [SumatraPDF](https://www.sumatrapdfreader.org/free-pdf-reader), or use its portable version.
  Windows does not need WSL, Bash or Python. See the [Windows guide](morning-paper/references/windows.md)
  for rendering, printer selection, duplex printing and troubleshooting.
- For printing: a printer your computer can reach from its local execution environment. A remote
  code-execution sandbox cannot access your Windows printer.
- For a paper that is ready when you wake up: the Claude desktop app open and your computer awake at
  print time. On a Mac: System Settings > Battery > Options > "Prevent automatic sleeping on power
  adapter when the display is off". On Windows: Settings > System > Power & battery > Screen and sleep
  (Power & sleep on Windows 10), then set plugged-in sleep to Never and stay signed in.

## Privacy

Your paper is built from your own calendar, inbox and to-do list, so treat it as private.
The skill reads your data while building and does not change anything. The only email it ever sends
is your own paper, to your own address, if you choose email delivery. Replies to people you circle are
saved as drafts for you to review, never sent. Everything it makes stays in a folder on your computer
(`~/Documents/Morning Paper/` by default on macOS/Linux; `Morning Paper` inside your Windows Documents
folder, including a redirected/OneDrive Documents folder, on Windows).

## What's inside

- [`morning-paper/SKILL.md`](morning-paper/SKILL.md): the setup interview, daily build and reply loop
- [`morning-paper/assets/template.html`](morning-paper/assets/template.html): the one-page layout
- [`morning-paper/references/`](morning-paper/references/): sections, config skeleton and Windows guide
- [`morning-paper/scripts/render_pdf.sh`](morning-paper/scripts/render_pdf.sh): macOS/Linux HTML to PDF, with a page count
- [`morning-paper/scripts/render_pdf.ps1`](morning-paper/scripts/render_pdf.ps1): Windows HTML to PDF, with a page count
- [`morning-paper/scripts/print_pdf.ps1`](morning-paper/scripts/print_pdf.ps1): Windows automatic printing

## Windows checks

From Windows PowerShell with its bundled Pester module and Chrome or Edge installed:

```powershell
$result = Invoke-Pester -Script .\tests\windows.Tests.ps1 -PassThru
if ($result.FailedCount -gt 0) { throw 'Windows tests failed.' }
```

The tests render local sample HTML and check failure handling. Printing uses mocks and a test
executable; no jobs are sent to a real printer.

MIT licensed. Fork it and make it yours.
