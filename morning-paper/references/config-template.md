# {{PAPER_NAME}}: editorial rules

A printed morning newspaper for {{READER_NAME}}. Built by the scheduled task at {{TIME}}
({{DAYS}}), saved in `editions/`, and delivered by: {{print / email / both / save only}}.
Email address (the reader's own, only): {{address or none}}.
Computer: {{macOS / Linux / Windows}}.
Paper folder (absolute path): {{path}}. Skill folder (absolute path): {{path}}.
Edit this file to change the paper. Every morning run reads it fresh.

## House rules
- Length: {{1 page / 2 pages / no limit}} ({{PAPER_SIZE}}). Never go over it: trim words first.
- Time zone: {{TIME_ZONE}}. All times shown in local time.
- Never invent facts. If a source fails, print a short honest "unavailable" line.
- Read only while building: no creating events or editing the to-do list, and no email except
  delivering the paper to the reader's own address (if email delivery is on).
- Style preferences: {{STYLE_NOTES, e.g. "no em dashes", "casual tone", or "none"}}

## Sections (in page order)
List only the chosen sections. Delete the rest of this list.

- **masthead:** {{on/off}}. Paper name "{{PAPER_NAME}}", left ear "{{EAR_LEFT}}", home city {{CITY}}.
- **lead:** on.
- **schedule:** calendars: {{calendar ids and names}}. Work calendar that only shows Busy:
  {{id or none}}. Daily routines to suggest: {{e.g. Workout 45 min, mornings; Writing 50 min before 9}}.
- **countdown:** events:
  - {{Event name, date, time, place}}
  Scan calendar for new big events in the next 60 days: {{yes/no}}.
- **inbox:** account {{email}}. Always lead with: {{people / domains}}.
- **todos:** source {{Notion database id / Todoist project / file path}}. Property mapping:
  project = {{}}, priority = {{}} (order: {{}}), status = {{}} (done value: {{}}), due = {{}},
  owner = {{}}. Groups shown: {{list}}.
- **news:** topics (one story each): {{up to 4}}. Preferred sources: {{list, or none}}.
  Business column: {{on/off}}, industry: {{}}.
- **ideas:** source {{}}, statuses to pull: {{}}.
- **writein:** on (Monday uses "This Week").
- **people:** goals to rotate: {{e.g. mentors, investors, hires}}. Values / avoid: {{}}.

## Build steps
1. Read this file and `template.html`.
2. Gather each section's data (rules in the skill's `references/sections.md`).
3. Write `editions/YYYY-MM-DD.html` from the template, removing sections not listed above.
4. Render and check pages: {{exact command with quoted absolute paths: Bash `render_pdf.sh` on
   macOS/Linux, or PowerShell `render_pdf.ps1 -HtmlPath` on Windows; see `references/windows.md`}}.
   Stop delivery on render failure; do not send an older PDF.
5. Deliver. Email (if on): send to {{address}} only, per the skill's "Delivery" section.
   Print: {{exact command for the chosen printer and paper size: `lp` on macOS/Linux, or PowerShell
   `print_pdf.ps1 -PdfPath ... -PrinterName ... -PaperSize ...` on Windows; include duplex if supported
   and chosen, or "do not print"}}.
   If it fails, inspect the queue using the operating system's instructions in the skill. On Windows,
   remove only this edition's confirmed failed job, never the whole queue. Try at most once more after
   checking for an already printed/submitted copy; no loops.
6. Append today's people to `people-log.md` (if the people section is on).

## Reply rules (photo of the paper, or a reply to the emailed edition)
- Note on a to-do line: update or add that item in {{todo source}}. New items default to
  priority {{}}, owner {{}}.
- Circled person: Gmail draft only, never sent, about 75 words, tone: {{e.g. "warm, asking for advice"}}.
  Add a to-do "Reach out to <name>".
- Ticked boxes: mark done where they clearly match.
- This Week list: one to-do per line for this week; ask when the group is unclear.
- Notes about the paper: edit this file or the template (back up the old copy first).
