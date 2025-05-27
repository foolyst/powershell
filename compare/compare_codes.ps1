<#
.SYNOPSIS
    Compares codes from multiple .txt files in the script's directory.
    Identifies common codes, codes unique to each file, and codes shared by specific subsets of files.
.DESCRIPTION
    This script processes all .txt files (excluding 'results.txt') found in the same
    directory as the script. It reads codes from these files, where codes can be
    single entries per line or ranges (e.g., "100-102" or "100|102").

    The script analyzes these codes to find and report:
    - Codes present in ALL processed files.
    - Codes present ONLY in specific combinations of files (e.g., only in fileA.txt and fileB.txt).
    - Codes unique to EACH individual file.

    The findings are written to 'results.txt' in the script's directory, with codes sorted
    and grouped by the exact set of files they appear in.
.INPUT FILE SETUP
    - Place your input text files (with a .txt extension) in the same directory as this script.
    - The script will attempt to process all .txt files in its directory, except for a
      file named 'results.txt' (which is its output file).
    - Each line in your .txt files should contain either:
        - A single code (e.g., "99214", "ABCDE").
        - A range of numerical codes, using either a hyphen '-' or a pipe '|' as a delimiter
          (e.g., "100-102" will be treated as 100, 101, 102; "200|202" as 200, 201, 202).
    - Codes are treated as case-insensitive strings.
    - Blank lines and leading/trailing whitespace around codes are ignored.
    - The script is optimized for up to 10 input files. If more than 10 files are found,
      a warning will be displayed as processing may be extensive.
.OUTPUT FILE (results.txt)
    - The script creates or overwrites 'results.txt' in its directory.
    - The report includes:
        - A list of all .txt files that were processed.
        - Sections for each unique combination of files that share one or more codes.
          The heading will indicate which files share those codes.
        - Codes listed within each section are sorted alphabetically/numerically.
.USAGE
    .\compare_codes.ps1
.PARAMETERS
    -Help, -h, -?
        Displays this help message and exits the script.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Display this help message and exit.")]
    [Alias('h', '?')]
    [switch]$Help
)

if ($Help) {
    Write-Output @"
NAME:
    compare_codes.ps1

SYNOPSIS:
    Compares codes from multiple .txt files in the script's directory.
    Identifies common codes, codes unique to each file, and codes shared by specific subsets of files.

DESCRIPTION:
    This script processes all .txt files (excluding 'results.txt') found in the same
    directory as the script. It reads codes from these files, where codes can be
    single entries per line or ranges (e.g., "100-102" or "100|102").

    The script analyzes these codes to find and report:
    - Codes present in ALL processed files.
    - Codes present ONLY in specific combinations of files (e.g., only in fileA.txt and fileB.txt).
    - Codes unique to EACH individual file.

    The findings are written to 'results.txt' in the script's directory, with codes sorted
    and grouped by the exact set of files they appear in.

INPUT FILE SETUP:
    - Place your input text files (with a .txt extension) in the same directory as this script.
    - The script will attempt to process all .txt files in its directory, except for a
      file named 'results.txt' (which is its output file).
    - Each line in your .txt files should contain either:
        - A single code (e.g., "99214", "ABCDE").
        - A range of numerical codes, using either a hyphen '-' or a pipe '|' as a delimiter
          (e.g., "100-102" will be treated as 100, 101, 102; "200|202" as 200, 201, 202).
    - Codes are treated as case-insensitive strings.
    - Blank lines and leading/trailing whitespace around codes are ignored.
    - The script is optimized for up to 10 input files. If more than 10 files are found,
      a warning will be displayed as processing may be extensive.

OUTPUT FILE (results.txt):
    - The script creates or overwrites 'results.txt' in its directory.
    - The report includes:
        - A list of all .txt files that were processed.
        - Sections for each unique combination of files that share one or more codes.
          The heading will indicate which files share those codes.
        - Codes listed within each section are sorted alphabetically/numerically.

USAGE:
    .\compare_codes.ps1

PARAMETERS:
    -Help, -h, -?
        Displays this help message and exits the script.

"@
    exit 0 # Exit successfully after displaying help
}

# --- Script Configuration ---
$OutputFileName = "results.txt"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -Path $ScriptDir # Ensure script operates in its own directory

# Collection to store information about invalid ranges
$InvalidRanges = [System.Collections.Generic.List[PSCustomObject]]::new()

# --- Helper Function to Parse Codes from a Line ---
function Parse-CodesFromLine {
    param (
        [string]$Line
    )

    $ExtractedCodes = [System.Collections.Generic.List[string]]::new()
    # Regex to find numbers or number ranges (e.g., 123, 100-102)
    # It will find these patterns even if embedded in other text.
    $Regex = "\b(\d+)(?:-(\d+))?\b" # Simple double-quoted string for regex

    $Matches = [regex]::Matches($Line, $Regex)

    foreach ($Match in $Matches) {
        $StartNumStr = $Match.Groups[1].Value
        if ($Match.Groups[2].Success) {
            # It's a range
            $EndNumStr = $Match.Groups[2].Value
            try {
                $StartNum = [int]$StartNumStr
                $EndNum = [int]$EndNumStr
                if ($StartNum -le $EndNum) {
                    for ($i = $StartNum; $i -le $EndNum; $i++) {
                        $ExtractedCodes.Add($i.ToString()) | Out-Null
                    }
                } else {
                    # Record invalid range information with detailed context
                    $InvalidRanges.Add([PSCustomObject]@{
                        FileName = $CurrentFileObject.Name
                        LineNumber = $LineNumber
                        Line = $CurrentLine
                        Range = "$StartNum-$EndNum"
                        StartValue = $StartNum
                        EndValue = $EndNum
                        MatchText = $Match.Value
                        Reason = "Start value greater than end value"
                    }) | Out-Null
                    # Skip invalid ranges (where start > end)
                    # For example, a range like "10-5" will not be processed
                    # This ensures consistent and predictable behavior with numerical ranges
                }
            } catch {
                # Record parsing errors as well
                $InvalidRanges.Add([PSCustomObject]@{
                    FileName = $CurrentFileObject.Name
                    LineNumber = $LineNumber
                    Line = $CurrentLine
                    Range = "$StartNumStr-$EndNumStr"
                    Error = "Failed to parse as integers: '$StartNumStr-$EndNumStr'"
                    MatchText = $Match.Value
                    Reason = "Failed to convert to integers"
                }) | Out-Null
            }
        } else {
            # It's a single number
            $ExtractedCodes.Add($StartNumStr) | Out-Null
        }
    }
    return $ExtractedCodes
}

# --- Main Script Logic ---

Write-Host "Starting code comparison..."

# 1. Find input files
$InputFiles = Get-ChildItem -Path $ScriptDir -Filter "*.txt" | Where-Object {$_.Name -ne $OutputFileName}

if ($InputFiles.Count -gt 10) {
    Write-Warning "More than 10 input files found ($($InputFiles.Count)). The script will proceed, but report generation might be very extensive and take a significant amount of time."
}

if ($InputFiles.Count -lt 2) {
    Write-Warning "At least two .txt files (excluding '$OutputFileName') are required for comparison."
    Write-Host "Found $($InputFiles.Count) input file(s)."
    if ($InputFiles.Count -eq 1) {
        Write-Host "File found: $($InputFiles[0].Name)"
    }
    exit 1
}

Write-Host "Found $($InputFiles.Count) input files to process:"
$InputFiles | ForEach-Object { Write-Host "- $($_.Name)" }

# 2. Read and parse codes from each file
$FileCodes = @{} # Hashtable to store codes for each file: $FileCodes[\'fileA.txt\'] = @(\'1\', \'2\')
$AllUniqueCodes = [System.Collections.Generic.HashSet[string]]::new()

Write-Host "Processing input files..."
foreach ($CurrentFileObject in $InputFiles) {
    $FileName = $CurrentFileObject.Name
    $CurrentFileCodes = [System.Collections.Generic.List[string]]::new()
    $LineNumber = 0
    Get-Content $CurrentFileObject.FullName | ForEach-Object {
        $LineNumber++
        $CurrentLine = $_.Trim()

        if ($CurrentLine -eq "" -or $CurrentLine.StartsWith('#')) {
            # Skip empty lines and comment lines
            return # Skips to the next line in ForEach-Object
        }

        $CodesFromLine = Parse-CodesFromLine -Line $CurrentLine
        
        if ($CodesFromLine.Count -gt 0) {
            foreach($Code in $CodesFromLine){
                if (-not $CurrentFileCodes.Contains($Code)) {
                    $CurrentFileCodes.Add($Code) | Out-Null
                }
                $AllUniqueCodes.Add($Code) | Out-Null
            }
        }
    }
    $FileCodes[$FileName] = $CurrentFileCodes
    Write-Host "  Finished processing $($FileName) - $($CurrentFileCodes.Count) unique numeric codes found."
}

if ($FileCodes.Count -lt 2) {
    Write-Error "Processing resulted in less than two files with valid codes. Cannot perform comparison."
    exit 1
}

# 3. Prepare output
$OutputContent = [System.Collections.Generic.List[string]]::new()
$OutputContent.Add("Results:") | Out-Null
$OutputContent.Add("") | Out-Null
$OutputContent.Add("Files searched on:") | Out-Null
$SortedFileNamesForHeader = $FileCodes.Keys | Sort-Object
$SortedFileNamesForHeader | ForEach-Object { $OutputContent.Add("- $_") | Out-Null }
$OutputContent.Add("") | Out-Null

# Add invalid ranges section if any were found
if ($InvalidRanges.Count -gt 0) {
    $OutputContent.Add("----------------------") | Out-Null
    $OutputContent.Add("INVALID RANGES FOUND:") | Out-Null
    $OutputContent.Add("----------------------") | Out-Null
    $OutputContent.Add("The following ranges were detected but ignored during processing:") | Out-Null
    $OutputContent.Add("") | Out-Null
    
    # Group invalid ranges by filename for better organization
    $GroupedInvalidRanges = $InvalidRanges | Group-Object -Property FileName
    
    foreach ($Group in $GroupedInvalidRanges) {
        $OutputContent.Add("File: $($Group.Name)") | Out-Null
        $OutputContent.Add("----------------") | Out-Null
        
        foreach ($Invalid in $Group.Group) {
            $OutputContent.Add("  • Line $($Invalid.LineNumber): Range '$($Invalid.Range)'") | Out-Null
            if ($Invalid.Reason) {
                $OutputContent.Add("    Reason: $($Invalid.Reason)") | Out-Null
            }
            if ($Invalid.Error) {
                $OutputContent.Add("    Error: $($Invalid.Error)") | Out-Null
            }
            $OutputContent.Add("    Context: $($Invalid.Line)") | Out-Null
            $OutputContent.Add("") | Out-Null
        }
    }
    $OutputContent.Add("") | Out-Null
}

# 4. Comparison Logic - New Signature-Based Approach
$CodeSignatures = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.HashSet[string]]]::new()
$FileNamesArray = $FileCodes.Keys | Sort-Object # Ensure consistent order for signature generation

foreach ($code in ($AllUniqueCodes | Sort-Object)) { # Iterate sorted codes for deterministic behavior if needed, though HashSet order isn't guaranteed for $AllUniqueCodes itself
    $filesContainingCode = [System.Collections.Generic.List[string]]::new()
    foreach ($fileNameKey in $FileNamesArray) {
        if ($FileCodes[$fileNameKey].Contains($code)) {
            $filesContainingCode.Add($fileNameKey) | Out-Null
        }
    }
    
    if ($filesContainingCode.Count -gt 0) {
        # The $filesContainingCode list is already sorted because $FileNamesArray is sorted.
        $signatureKey = $filesContainingCode -join ", " # Create a string key

        if (-not $CodeSignatures.ContainsKey($signatureKey)) {
            $CodeSignatures[$signatureKey] = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        }
        $CodeSignatures[$signatureKey].Add($code) | Out-Null
    }
}

# Order signatures for reporting: by number of files (descending), then by signature string (alphabetically)
$OrderedSignatures = $CodeSignatures.GetEnumerator() | Sort-Object @{Expression={$_.Key.Split(',').Count}; Descending=$true}, @{Expression={$_.Key}; Ascending=$true}

foreach ($SignatureEntry in $OrderedSignatures) {
    $SignatureKey = $SignatureEntry.Key # e.g., "fileA.txt, fileB.txt" or "fileC.txt"
    $CodesInSignature = $SignatureEntry.Value | Sort-Object
    $FileCountInSignature = $SignatureKey.Split(',').Count

    if ($CodesInSignature.Count -gt 0) {
        $OutputHeader = ""
        if ($FileCountInSignature -eq $FileNamesArray.Count) {
            # Case: Codes common to ALL files
            $OutputHeader = "Codes common to ALL $($FileNamesArray.Count) files ($($CodesInSignature.Count) codes):"
        } elseif ($FileCountInSignature -eq 1) {
            # Case: Codes unique to a single file
            # $SignatureKey here is just the single file name, e.g., "fileA.txt"
            $OutputHeader = "Codes unique to file '$SignatureKey' ($($CodesInSignature.Count) codes):"
        } else {
            # Case: Codes common to a subset of files (more than 1, but not all)
            $OutputHeader = "Codes common to $FileCountInSignature files ($SignatureKey) ($($CodesInSignature.Count) codes):"
        }
        
        $OutputContent.Add($OutputHeader) | Out-Null
        $CodesInSignature | ForEach-Object { $OutputContent.Add("    - $_") | Out-Null } # Indent codes for readability
        $OutputContent.Add("") | Out-Null # Add a blank line for readability between sections
    }
}

# Remove old comparison logic sections (4a, 4b, 4c)
# The new loop above handles all cases.

# 5. Write to output file
try {
    $OutputContent | Set-Content -Path (Join-Path $ScriptDir $OutputFileName) -Encoding UTF8 -ErrorAction Stop | Out-Null
    Write-Host "Comparison complete. Results written to '$OutputFileName'."
}
catch {
    Write-Error "Error writing to output file '$OutputFileName': $_"
}

Write-Host "Script finished."

