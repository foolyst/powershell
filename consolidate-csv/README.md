# CSV File Consolidation Tool

## Overview

The `consolidate-csv.ps1` script is a utility for combining multiple CSV files in a directory into a single consolidated file. This is particularly useful when you have data split across multiple CSV files with the same structure and need to analyze them as a single dataset.

## Features

- Automatically processes all CSV files in the current directory
- Preserves the header row from the first file
- Skips repeating headers from subsequent files
- Creates a single output file with all data combined

## Usage

```powershell
# Navigate to the directory containing your CSV files
cd path/to/your/csv/files

# Run the script
.\consolidate-csv.ps1
```

### Requirements

- The CSV files should have the same structure (same columns)
- All CSV files must be in the current working directory
- Files must have the `.csv` extension

### Output

The script creates a single output file named `combined.csv` in the current directory, containing all rows from the input files with a single header row.

## How It Works

1. The script first identifies all CSV files in the current directory
2. It reads the first file and writes its content (including the header) to the output file
3. For each subsequent file, it reads the content but skips the header when writing to the output
4. The result is a single CSV file with one header row followed by all data rows from all files

## Example

If you have three CSV files with the following content:

**file1.csv**:
```
Name,Age,Location
John,30,New York
Alice,25,Boston
```

**file2.csv**:
```
Name,Age,Location
Bob,45,Chicago
Carol,33,Denver
```

**file3.csv**:
```
Name,Age,Location
Dave,28,Seattle
Eve,39,Portland
```

Running the script will produce a single `combined.csv` file:
```
Name,Age,Location
John,30,New York
Alice,25,Boston
Bob,45,Chicago
Carol,33,Denver
Dave,28,Seattle
Eve,39,Portland
```

## Limitations

- The script assumes that all CSV files have the same column structure
- It does not perform any data validation or transformation
- The script will overwrite any existing `combined.csv` file in the directory
