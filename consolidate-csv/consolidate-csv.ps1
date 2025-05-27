# Get the current directory
$currentDirectory = Get-Location

# Define the output file path in the current directory
$outputFilePath = Join-Path -Path $currentDirectory -ChildPath "combined.csv"

# Get all CSV files in the current directory
$csvFiles = Get-ChildItem -Path $currentDirectory -Filter *.csv

# Check if there are any CSV files in the directory
if ($csvFiles.Count -eq 0) {
    Write-Host "No CSV files found in the current directory."
    exit
}

# Initialize a variable to track if the header has been written
$headerWritten = $false

# Open the output file for writing
foreach ($csvFile in $csvFiles) {
    # Read the CSV file content
    $csvContent = Import-Csv -Path $csvFile.FullName

    # Check if the header has already been written
    if (-not $headerWritten) {
        # Write the content to the output file including the header
        $csvContent | Export-Csv -Path $outputFilePath -NoTypeInformation
        $headerWritten = $true
    } else {
        # Append the content to the output file without the header
        $csvContent | Export-Csv -Path $outputFilePath -NoTypeInformation -Append
    }
}

Write-Host "CSV files combined successfully into $outputFilePath"