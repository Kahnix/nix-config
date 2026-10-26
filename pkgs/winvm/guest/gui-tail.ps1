# winvm gui-tail: stream C:\winvm\gui\out.log raw to stdout until exit.txt appears,
# then exit with the recorded exit code.
$ErrorActionPreference = 'Stop'

$guiDir = 'C:\winvm\gui'
$outLog = Join-Path $guiDir 'out.log'
$exitFile = Join-Path $guiDir 'exit.txt'

$stdout = [Console]::OpenStandardOutput()
$offset = 0L
$buffer = New-Object byte[] 65536

while ($true) {
    # Check for completion first: once exit.txt exists the log is final, so one more drain is complete.
    $finished = Test-Path -Path $exitFile

    if (Test-Path -Path $outLog) {
        $fs = [IO.File]::Open($outLog, 'Open', 'Read', 'ReadWrite')
        try {
            if ($fs.Length -gt $offset) {
                [void]$fs.Seek($offset, 'Begin')
                while ($true) {
                    $n = $fs.Read($buffer, 0, $buffer.Length)
                    if ($n -le 0) { break }
                    $stdout.Write($buffer, 0, $n)
                    $offset += $n
                }
                $stdout.Flush()
            }
        } finally {
            $fs.Dispose()
        }
    }

    if ($finished) { break }
    Start-Sleep -Milliseconds 300
}

$code = 1
$raw = (Get-Content -Raw -Path $exitFile)
if ($raw) {
    $parsed = 0
    if ([int]::TryParse($raw.Trim(), [ref]$parsed)) { $code = $parsed }
}
exit $code
