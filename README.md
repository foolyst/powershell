# PowerShell Utility Scripts

This repository contains utility scripts for processing and analyzing code numbers and ranges in text files.

## Scripts Overview

The repository contains the following utilities:

| Script | Description |
|--------|-------------|
| [`compare/compare_codes.ps1`](compare/README.md) | Compares numeric codes across multiple text files, identifying common codes, unique codes, and codes shared by specific subsets of files. |
| [`consolidate-csv/consolidate-csv.ps1`](consolidate-csv/README.md) | Combines multiple CSV files into a single consolidated file while preserving headers. |
| [`number-order/number-order.ps1`](number-order/README.md) | Processes lists of numbers, either by grouping sequential numbers into ranges or expanding ranges into individual numbers. |

## Getting Started

### Prerequisites

- PowerShell 5.1 or later
- Windows PowerShell or PowerShell Core (cross-platform)

### Running Scripts

Navigate to the script directory and run the script with PowerShell:

```powershell
# Windows
.\script-name.ps1 [parameters]

# macOS/Linux with PowerShell Core
pwsh script-name.ps1 [parameters]
```

Each script has its own parameters and usage instructions. See the README in each script's directory for detailed information.

## License

This project is available under the MIT License. See the LICENSE file for more details.