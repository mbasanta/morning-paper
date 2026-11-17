#requires -Version 5.1
param([string]$BrowserPath)

$renderer = Join-Path $PSScriptRoot '..\morning-paper\scripts\render_pdf.ps1'
$printerScript = Join-Path $PSScriptRoot '..\morning-paper\scripts\print_pdf.ps1'
$browserArguments = @{}
if ($BrowserPath) {
    $browserArguments.BrowserPath = $BrowserPath
}

Describe 'Windows PDF rendering' {
    It 'renders a relative path with spaces, brackets, a hash and a non-ASCII character' {
        $folder = Join-Path $TestDrive ("Morning Paper [test] # " + [char]0xE9)
        New-Item -ItemType Directory -Path $folder | Out-Null
        $html = Join-Path $folder 'edition #1.html'
        $pdf = Join-Path $folder 'edition #1.pdf'
        Set-Content -LiteralPath $html -Encoding UTF8 -Value @'
<!doctype html>
<html><head><title>Morning Paper path test</title></head><body><h1>Test edition</h1></body></html>
'@

        Push-Location -LiteralPath $folder
        try {
            $result = & $renderer -HtmlPath '.\edition #1.html' @browserArguments
        }
        finally {
            Pop-Location
        }

        $result | Should Be ("{0}: 1 page(s)" -f $pdf)
        (Get-Item -LiteralPath $pdf).Length | Should BeGreaterThan 0
        [System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes($pdf)) |
            Should Match '/Title\s*\(Morning Paper path test\)'
    }

    It 'reports two pages rather than silently accepting an overlong edition' {
        $html = Join-Path $TestDrive 'two pages.html'
        $pdf = Join-Path $TestDrive 'two pages.pdf'
        Set-Content -LiteralPath $html -Encoding UTF8 -Value @'
<!doctype html>
<html><body>
<h1>Page one</h1>
<h1 style="break-before: page">Page two</h1>
</body></html>
'@

        $result = & $renderer -HtmlPath $html @browserArguments

        $result | Should Be ("{0}: 2 page(s)" -f $pdf)
    }
}

Describe 'Windows render failures' {
    BeforeEach {
        $html = Join-Path $TestDrive 'edition.html'
        $pdf = Join-Path $TestDrive 'edition.pdf'
        $fakeBrowser = Join-Path $TestDrive 'browser.exe'
        Set-Content -LiteralPath $html -Value '<html><body>Edition</body></html>'
        Set-Content -LiteralPath $pdf -Value 'previous edition'
        Set-Content -LiteralPath $fakeBrowser -Value ''
    }

    It 'reports a missing browser without replacing the previous PDF' {
        Mock Get-Command {}
        Mock Test-Path { $false } -ParameterFilter { $LiteralPath -like '*.exe' }
        Mock Start-Process {}

        { & $renderer -HtmlPath $html } | Should Throw 'No Chrome, Chromium or Edge found'

        (Get-Content -LiteralPath $pdf) | Should Be 'previous edition'
        Assert-MockCalled Start-Process -Times 0 -Exactly -Scope It
    }

    It 'reports browser errors and keeps the previous PDF' {
        Mock Start-Process {
            Set-Content -LiteralPath $RedirectStandardError -Value 'test browser failure'
            [pscustomobject]@{ ExitCode = 1 }
        }

        { & $renderer -HtmlPath $html -BrowserPath $fakeBrowser } | Should Throw 'test browser failure'

        (Get-Content -LiteralPath $pdf) | Should Be 'previous edition'
        Assert-MockCalled Start-Process -Times 1 -Exactly -Scope It
    }

    It 'rejects a successful browser exit with no new PDF' {
        Mock Start-Process {
            Set-Content -LiteralPath $RedirectStandardError -Value ''
            [pscustomobject]@{ ExitCode = 0 }
        }

        { & $renderer -HtmlPath $html -BrowserPath $fakeBrowser } | Should Throw 'Browser failed to render'

        (Get-Content -LiteralPath $pdf) | Should Be 'previous edition'
    }

    It 'rejects a PDF whose page count cannot be verified' {
        Mock Start-Process {
            $outputArgument = $ArgumentList | Where-Object { $_ -like '--print-to-pdf=*' }
            $outputPath = $outputArgument.Substring('--print-to-pdf='.Length).Trim('"')
            Set-Content -LiteralPath $outputPath -Value '%PDF-1.7'
            [pscustomobject]@{ ExitCode = 0 }
        }

        { & $renderer -HtmlPath $html -BrowserPath $fakeBrowser } | Should Throw 'Could not verify'

        (Get-Content -LiteralPath $pdf) | Should Be 'previous edition'
    }
}

Describe 'Windows print submission' {
    BeforeEach {
        $folder = Join-Path $TestDrive 'Printed Paper [test]'
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        $pdf = Join-Path $folder 'daily paper.pdf'
        $sumatra = Join-Path $folder 'SumatraPDF.exe'
        Set-Content -LiteralPath $pdf -Value '%PDF-1.7'
        Set-Content -LiteralPath $sumatra -Value ''
        Mock Get-Printer { [pscustomobject]@{ Name = 'Office [West] printer' } }
        Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }
    }

    It 'passes the exact printer, quoted PDF path, A4 size and duplex setting to SumatraPDF' {
        Push-Location -LiteralPath $folder
        try {
            $result = & $printerScript -PdfPath '.\daily paper.pdf' -PrinterName 'Office [West] printer' `
                -PaperSize A4 -Duplex -SumatraPdfPath '.\SumatraPDF.exe'
        }
        finally {
            Pop-Location
        }

        $result | Should Match "^Submitted .+ to printer 'Office \[West\] printer'"
        Assert-MockCalled Start-Process -Times 1 -Exactly -Scope It -ParameterFilter {
            $FilePath -eq $sumatra -and $Wait -and $PassThru -and
            ($ArgumentList -join '|') -eq ('-silent|-print-to|"Office [West] printer"|-print-settings|paper=a4,duplexlong|"{0}"' -f $pdf)
        }
    }

    It 'uses Letter and single-sided printing by default' {
        & $printerScript -PdfPath $pdf -PrinterName 'Office [West] printer' -SumatraPdfPath $sumatra | Out-Null

        Assert-MockCalled Start-Process -Times 1 -Exactly -Scope It -ParameterFilter {
            $ArgumentList -contains 'paper=letter,simplex'
        }
    }

    It 'refuses an unknown printer rather than using the default printer' {
        { & $printerScript -PdfPath $pdf -PrinterName 'Unknown printer' -SumatraPdfPath $sumatra } |
            Should Throw "Printer 'Unknown printer' was not found"

        Assert-MockCalled Start-Process -Times 0 -Exactly -Scope It
    }

    It 'reports a missing SumatraPDF instead of silently skipping printing' {
        Mock Get-Command {}
        Mock Test-Path { $false } -ParameterFilter { $LiteralPath -like '*.exe' }

        { & $printerScript -PdfPath $pdf -PrinterName 'Office [West] printer' } |
            Should Throw 'Automatic Windows printing requires SumatraPDF'

        Assert-MockCalled Start-Process -Times 0 -Exactly -Scope It
    }

    It 'surfaces a print failure without retrying or claiming delivery' {
        Mock Start-Process { [pscustomobject]@{ ExitCode = 5 } }

        { & $printerScript -PdfPath $pdf -PrinterName 'Office [West] printer' -SumatraPdfPath $sumatra } |
            Should Throw 'exit code 5'

        (Test-Path -LiteralPath $pdf) | Should Be $true
        Assert-MockCalled Start-Process -Times 1 -Exactly -Scope It
    }
}

Describe 'Windows native print invocation' {
    It 'preserves native arguments and exit codes without sending a print job' {
        $folder = Join-Path $TestDrive ("Native print [test] # " + [char]0xE9)
        New-Item -ItemType Directory -Path $folder | Out-Null
        $pdf = Join-Path $folder 'daily #1.pdf'
        $compiledExe = Join-Path $TestDrive 'PrintProbe.exe'
        $exe = Join-Path $folder 'PrintProbe.exe'
        Set-Content -LiteralPath $pdf -Value '%PDF-1.7'
        Add-Type -OutputType ConsoleApplication -OutputAssembly $compiledExe -TypeDefinition @'
using System;
using System.IO;
public static class PrintProbe {
    public static int Main(string[] args) {
        if (args.Length != 6 || args[0] != "-silent" || args[1] != "-print-to" ||
            args[2] != @"\\server\Office [West]" || args[3] != "-print-settings" ||
            args[4] != "paper=a4,duplexlong" || Path.GetFileName(args[5]) != "daily #1.pdf" ||
            !File.Exists(args[5])) {
            return 99;
        }
        return int.Parse(Environment.GetEnvironmentVariable("MORNING_PAPER_TEST_EXIT"));
    }
}
'@
        Move-Item -LiteralPath $compiledExe -Destination $exe
        Mock Get-Printer { [pscustomobject]@{ Name = '\\server\Office [West]' } }
        $previousExit = $env:MORNING_PAPER_TEST_EXIT

        Push-Location -LiteralPath $folder
        try {
            $env:MORNING_PAPER_TEST_EXIT = '0'
            $result = & $printerScript -PdfPath '.\daily #1.pdf' -PrinterName '\\server\Office [West]' `
                -PaperSize A4 -Duplex -SumatraPdfPath '.\PrintProbe.exe'
            $result | Should Match '^Submitted '

            $env:MORNING_PAPER_TEST_EXIT = '5'
            { & $printerScript -PdfPath '.\daily #1.pdf' -PrinterName '\\server\Office [West]' `
                -PaperSize A4 -Duplex -SumatraPdfPath '.\PrintProbe.exe' } | Should Throw 'exit code 5'
        }
        finally {
            $env:MORNING_PAPER_TEST_EXIT = $previousExit
            Pop-Location
        }
    }
}
