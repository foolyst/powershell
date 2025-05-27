# Number Order Tool

## Overview

The `number-order.ps1` script is a utility for processing lists of numeric codes in text files. It offers two primary modes of operation:

1. **Default mode**: Reads individual numbers, sorts them, and groups sequential numbers into ranges
2. **Reverse mode**: Expands ranges back into individual numbers

This tool is useful for compressing numeric lists into a more compact representation or expanding abbreviated ranges for processing by other systems.

## Features

- Bidirectional conversion between individual numbers and ranges
- Support for both hyphenated (100-102) and pipe-delimited (100|102) range formats
- Sorting of numbers before processing
- Customizable input and output file paths

## Usage

```powershell
.\number-order.ps1 [-reverse] [-inputFile <path>] [-outputFile <path>] [-help]
```

### Parameters

- `-reverse`, `-r`: Switch to reverse mode (expand ranges into individual numbers)
- `-inputFile`: Path to the input file (default: "numbers.txt")
- `-outputFile`: Path to the output file (default: "results.txt")
- `-help`, `-h`, `-?`: Display help information and exit

## Operating Modes

### Default Mode: Group Numbers into Ranges

In the default mode, the script:
1. Reads a file containing one number per line
2. Sorts the numbers numerically
3. Groups sequential numbers into ranges
4. Outputs the ranges to the specified file

For example, if the input file contains:
```
101
102
103
105
106
110
```

The output would be:
```
101-103
105-106
110
```

### Reverse Mode: Expand Ranges into Individual Numbers

In reverse mode (`-reverse` switch), the script:
1. Reads a file containing ranges like "100-102" or "100|102"
2. Expands these ranges into individual numbers
3. Sorts the resulting numbers
4. Outputs one number per line to the specified file

For example, if the input file contains:
```
101-103
105-106
110
```

The output would be:
```
101
102
103
105
106
110
```

## Examples

### Group Numbers into Ranges

```powershell
.\number-order.ps1 -inputFile numbers.txt -outputFile grouped.txt
```

### Expand Ranges into Individual Numbers

```powershell
.\number-order.ps1 -reverse -inputFile ranges.txt -outputFile expanded.txt
```

## Error Handling

The script checks for the existence of the input file and provides appropriate error messages if the file is not found. It also handles invalid input gracefully.
