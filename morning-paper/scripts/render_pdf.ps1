#requires -Version 5.1
# Usage: .\render_pdf.ps1 -HtmlPath "editions\YYYY-MM-DD.html"
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$HtmlPath,
    [string]$BrowserPath
)

$ErrorActionPreference = 'Stop'

$html = Get-Item -LiteralPath ($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($HtmlPath))
if ($html.PSIsContainer -or $html.Extension -notin @('.html', '.htm')) {
    throw 'HtmlPath must be an HTML file.'
}
$pdf = [System.IO.Path]::ChangeExtension($html.FullName, '.pdf')

if (-not $BrowserPath) {
    $candidates = @(
        Get-Command chrome.exe, msedge.exe, chromium.exe -CommandType Application -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty Source
    )
    foreach ($root in @($env:LOCALAPPDATA, $env:ProgramFiles, ${env:ProgramFiles(x86)})) {
        if ($root) {
            foreach ($relative in @('Google\Chrome\Application\chrome.exe', 'Microsoft\Edge\Application\msedge.exe', 'Chromium\Application\chrome.exe')) {
                $candidates += Join-Path $root $relative
            }
        }
    }
    $BrowserPath = $candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
}
if (-not $BrowserPath) {
    throw 'No Chrome, Chromium or Edge found. Install one, or supply -BrowserPath with its executable path.'
}
$browser = Get-Item -LiteralPath ($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($BrowserPath))
if ($browser.PSIsContainer) {
    throw 'BrowserPath must be a browser executable.'
}

$work = Join-Path ([System.IO.Path]::GetTempPath()) ('morning-paper-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
try {
    $temporaryPdf = Join-Path $work 'edition.pdf'
    $profile = Join-Path $work 'browser-profile'
    $stderr = Join-Path $work 'browser.stderr.log'
    $stdout = Join-Path $work 'browser.stdout.log'
    # An isolated profile keeps an open browser from swallowing the headless request.
    $arguments = @(
        '--headless=new'
        '--disable-gpu'
        '--no-first-run'
        '--no-pdf-header-footer'
        '--virtual-time-budget=8000'
        "--user-data-dir=`"$profile`""
        "--print-to-pdf=`"$temporaryPdf`""
        ([uri]$html.FullName).AbsoluteUri
    )
    $process = Start-Process -FilePath $browser.FullName -ArgumentList $arguments -Wait -PassThru `
        -WorkingDirectory ([System.Management.Automation.WildcardPattern]::Escape($work)) `
        -RedirectStandardError $stderr -RedirectStandardOutput $stdout
    if ($process.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $temporaryPdf -PathType Leaf)) {
        $diagnostics = Get-Content -LiteralPath $stderr -Raw
        throw "Browser failed to render the PDF (exit code $($process.ExitCode)). $diagnostics"
    }

    $contents = [System.Text.Encoding]::GetEncoding(28591).GetString([System.IO.File]::ReadAllBytes($temporaryPdf))
    $pages = [regex]::Matches($contents, '/Type\s*/Page\b').Count
    if (-not $contents.StartsWith('%PDF-') -or $pages -lt 1) {
        throw 'Could not verify the rendered PDF page count. The previous edition PDF was not replaced.'
    }
    Move-Item -LiteralPath $temporaryPdf -Destination $pdf -Force
}
finally {
    Remove-Item -LiteralPath $work -Recurse -Force
}

Write-Output ("{0}: {1} page(s)" -f $pdf, $pages)
