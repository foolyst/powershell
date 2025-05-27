# Code Comparison Tool

## Overview

The `compare_codes.ps1` script is a utility that compares numeric codes across multiple text files. It identifies:

- Codes common to all processed files
- Codes unique to each individual file
- Codes shared by specific subsets of files

This is particularly useful for comparing code sets, such as billing codes, feature flags, or any numeric identifiers across different systems or data sources.

## Features

- Process multiple text files containing numeric codes
- Support for various code formats:
  - Single numbers (e.g., "100")
  - Hyphenated ranges (e.g., "100-102" expands to 100, 101, 102)
  - Pipe-delimited values (e.g., "100|102")
- Intelligent grouping by file combinations
- Validation and reporting of invalid ranges
- Detailed output organization

## Usage

```powershell
.\compare_codes.ps1 [-Help]
```

### Parameters

- `-Help`, `-h`, `-?`: Display help information and exit

### Input File Requirements

1. Place your input text files (with a `.txt` extension) in the same directory as the script
2. Each line in the text files should contain either:
   - A single code (e.g., "99214")
   - A range of numerical codes using a hyphen (e.g., "100-102")
   - Pipe-delimited values (e.g., "100|102")
3. Blank lines and lines starting with '#' are ignored
4. Leading/trailing whitespace is trimmed

### Output

The script generates a `results.txt` file in the same directory with:

1. A list of all processed files
2. A section showing any invalid ranges found during processing
3. Sections for each unique combination of files sharing codes
4. Sorted lists of codes within each section

## Example

Given three files with the following codes:

**fileA.txt**:
```
100
101
102
200
```

**fileB.txt**:
```
100
101
300
```

**fileC.txt**:
```
100
400
```

The output would show:
- Code 100 is common to all three files
- Codes 101 is common to fileA and fileB
- Code 102, 200 is unique to fileA
- Code 300 is unique to fileB
- Code 400 is unique to fileC

## Invalid Range Handling

The script detects and reports invalid ranges, such as:
- Ranges where the start value is greater than the end value (e.g., "10-5")
- Ranges with non-numeric components
- Malformed ranges

Invalid ranges are reported in the results file with detailed information about their location and context.

## Performance Considerations

The script is optimized for processing up to 10 input files. With more files, the script will still work but may take longer to process due to the exponential growth in possible file combinations.
