#requires -Version 5.1
# Usage: .\print_pdf.ps1 -PdfPath "editions\YYYY-MM-DD.pdf" -PrinterName "Office printer"
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$PdfPath,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$PrinterName,
    [ValidateSet('Letter', 'A4')]
    [string]$PaperSize = 'Letter',
    [switch]$Duplex,
    [string]$SumatraPdfPath
)

$ErrorActionPreference = 'Stop'

$pdf = Get-Item -LiteralPath ($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($PdfPath))
if ($pdf.PSIsContainer -or $pdf.Extension -ne '.pdf') {
    throw 'PdfPath must be a PDF file.'
}
$printer = Get-Printer -ErrorAction Stop | Where-Object { $_.Name -eq $PrinterName }
if (-not $printer) {
    throw "Printer '$PrinterName' was not found. Run Get-Printer to list installed printers."
}

if (-not $SumatraPdfPath) {
    $candidates = @(
        Get-Command SumatraPDF.exe -CommandType Application -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty Source
    )
    foreach ($root in @($env:LOCALAPPDATA, $env:ProgramFiles, ${env:ProgramFiles(x86)})) {
        if ($root) {
            $candidates += Join-Path $root 'SumatraPDF\SumatraPDF.exe'
        }
    }
    if ($env:LOCALAPPDATA) {
        $candidates += Join-Path $env:LOCALAPPDATA 'Programs\SumatraPDF\SumatraPDF.exe'
    }
    $SumatraPdfPath = $candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
}
if (-not $SumatraPdfPath) {
    throw 'Automatic Windows printing requires SumatraPDF. Install it, or supply -SumatraPdfPath for a portable copy. The PDF is still saved.'
}
$sumatra = Get-Item -LiteralPath ($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($SumatraPdfPath))
if ($sumatra.PSIsContainer) {
    throw 'SumatraPdfPath must be the SumatraPDF executable.'
}

$sides = if ($Duplex) { 'duplexlong' } else { 'simplex' }
# Start-Process joins arguments into a command line; escape quotes and trailing backslashes.
$quotedPrinter = '"' + ($PrinterName -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
$arguments = @(
    '-silent'
    '-print-to'
    $quotedPrinter
    '-print-settings'
    "paper=$($PaperSize.ToLowerInvariant()),$sides"
    "`"$($pdf.FullName)`""
)
# NoNewWindow keeps the native exit code available in Windows PowerShell.
$process = Start-Process -FilePath $sumatra.FullName -ArgumentList $arguments -Wait -PassThru -NoNewWindow `
    -WorkingDirectory ([System.Management.Automation.WildcardPattern]::Escape($sumatra.DirectoryName))
if ($process.ExitCode -ne 0) {
    throw "SumatraPDF failed to submit the print job (exit code $($process.ExitCode)). Check the printer and its queue with Get-PrintJob. The PDF is still saved."
}

Write-Output ("Submitted {0} to printer '{1}'. Check its queue for delivery status." -f $pdf.FullName, $PrinterName)
