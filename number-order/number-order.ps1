# Adjust the input and output file names as needed to match your environment.
[CmdletBinding()]
param (
    [switch]$reverse,
    [string]$inputFile = "numbers.txt",
    [string]$outputFile = "results.txt",
    [Parameter(HelpMessage="Show this help message and exit.")]
    [Alias('h', '?')]
    [switch]$help
)

if ($help) {
    Write-Output @"
This script reads a list of codes from a text file and processes them.

Default mode:
    Reads a file with one number per line, sorts them,
    and groups sequential numbers into ranges.

Reverse mode (-r or --reverse):
    Reads a file with grouped ranges (like 100|102 or 100-102),
    expands these ranges into individual numbers,
    sorts them, and outputs a flat list.

Usage:
    .\\number-order.ps1 [-r|--reverse] [-inputFile <file>] [-outputFile <file>] [--help|-h]

Parameters:
    -r, --reverse  Reverse the grouping: expand ranges into individual numbers
    -inputFile     Path to input file. Default: numbers.txt
    -outputFile    Path to output file. Default: results.txt
    --help, -h     Show this help message and exit.

Examples:
    .\\number-order.ps1 -r -inputFile input.txt -outputFile expanded.txt
    .\\number-order.ps1 -inputFile numbers.txt -outputFile results.txt

"@
    exit 0
}

if (-not (Test-Path $inputFile)) {
    Write-Error "Input file '$inputFile' not found."
    exit 1
}

if ($reverse) {
    # Reverse mode: expand ranges into individual numbers
    $lines = $null
    try {
        $lines = Get-Content $inputFile -ErrorAction Stop
    }
    catch {
        Write-Error "Error reading input file '$inputFile': $_"
        exit 1
    }

    if ($null -eq $lines -or $lines.Count -eq 0) {
        Write-Host "Input file '$inputFile' is empty. Output file '$outputFile' will be empty."
        try {
            Set-Content -Path $outputFile -Value $null -ErrorAction Stop
        }
        catch {
            Write-Error "Error creating empty output file '$outputFile': $_"
        }
        exit 0
    }

    $allNumbers = @()

    foreach ($line in $lines) {
        if ($line -match '^\s*(\d+)\s*[|-]\s*(\d+)\s*$') {
            $startNum = [int]$matches[1]
            $endNum = [int]$matches[2]

            if ($startNum -le $endNum) {
                $allNumbers += $startNum..$endNum
            } else {
                $allNumbers += $endNum..$startNum # Handles reverse order ranges like 102-100
            }
        }
        elseif ($line -match '^\s*(\d+)\s*$') {
            $allNumbers += [int]$matches[1]
        }
        elseif ([string]::IsNullOrWhiteSpace($line)) {
            # Skip empty or whitespace-only lines silently
            continue
        }
        else {
            Write-Warning "Line '$line' in '$inputFile' does not match expected formats (e.g., '100-102', '100|102', or '100') and was skipped."
        }
    }

    if ($allNumbers.Count -eq 0) {
        Write-Host "No valid numbers or ranges found in '$inputFile' after parsing. Output file '$outputFile' will be empty."
        try {
            Set-Content -Path $outputFile -Value $null -ErrorAction Stop
        }
        catch {
            Write-Error "Error creating empty output file '$outputFile': $_"
        }
        exit 0
    }
    
    $allNumbers = $allNumbers | Sort-Object | Get-Unique

    try {
        $allNumbers | Set-Content $outputFile -ErrorAction Stop
        Write-Host "Processed numbers written to '$outputFile'."
    }
    catch {
        Write-Error "Error writing to output file '$outputFile': $_"
        exit 1
    }
}
else {
    # Default mode: group sequential numbers
    $fileContent = $null
    try {
        $fileContent = Get-Content $inputFile -ErrorAction Stop
    }
    catch {
        Write-Error "Error reading input file '$inputFile': $_"
        exit 1
    }

    if ($null -eq $fileContent -or $fileContent.Count -eq 0) {
        Write-Host "Input file '$inputFile' is empty. Output file '$outputFile' will be empty."
        try {
            Set-Content -Path $outputFile -Value $null -ErrorAction Stop
        }
        catch {
            Write-Error "Error creating empty output file '$outputFile': $_"
        }
        exit 0
    }

    $parsedNumbers = @()
    $invalidLineCount = 0
    foreach ($lineInFile in $fileContent) { # Renamed $line to $lineInFile to avoid conflict
        if ([string]::IsNullOrWhiteSpace($lineInFile)) {
            # Skip empty or whitespace-only lines silently
            continue
        }
        $num = 0
        if ([int]::TryParse($lineInFile.Trim(), [ref]$num)) {
            $parsedNumbers += $num
        } else {
            Write-Warning "Line '$lineInFile' in '$inputFile' is not a valid integer and was skipped."
            $invalidLineCount++
        }
    }

    if ($parsedNumbers.Count -eq 0) {
        Write-Host "No valid numbers found in '$inputFile' after filtering. Output file '$outputFile' will be empty."
        if ($invalidLineCount -gt 0) {
             Write-Host "($invalidLineCount line(s) were invalid and skipped.)"
        }
        try {
            Set-Content -Path $outputFile -Value $null -ErrorAction Stop
        }
        catch {
            Write-Error "Error creating empty output file '$outputFile': $_"
        }
        exit 0
    }

    $numbers = $parsedNumbers | Sort-Object

    $result = @()
    $startRange = $null
    $endRange = $null

    foreach ($number in $numbers) {
        if ($startRange -eq $null) {
            $startRange = $number
            $endRange = $number
        } elseif ($number -eq $endRange + 1) {
            $endRange = $number
        } else {
            if ($startRange -eq $endRange) {
                $result += "$startRange"
            } else {
                $result += "$startRange|$endRange"
            }
            $startRange = $number
            $endRange = $number
        }
    }

    if ($startRange -ne $null) {
        if ($startRange -eq $endRange) {
            $result += "$startRange"
        } else {
            $result += "$startRange|$endRange"
        }
    }
    
    try {
        $result | Set-Content $outputFile -ErrorAction Stop
        Write-Host "Processed number ranges written to '$outputFile'."
    }
    catch {
        Write-Error "Error writing to output file '$outputFile': $_"
        exit 1
    }
}
