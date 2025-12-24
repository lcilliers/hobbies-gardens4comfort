# Gardens4Comfort - Plant Journey Website

Source code for the Gardens4Comfort.uk website - a personal documentation of a plant journey using Sphinx and reStructuredText.

## Overview

This project generates a static HTML website from reStructuredText (RST) source files using Sphinx. The content includes:
- Plant collections organized by type
- Growing journals and diaries
- Garden design notes
- Greenhouse management
- Propagation techniques
- And more...

## Project Structure

- **Source/** - RST source files organized by topic
  - **Source/Images/** - Plant photos and documentation images (referenced in RST files)
- **Build/** - Generated HTML output (not tracked in Git)
- **Images/** - Local temporary folder for staging new images before adding to Source/Images (not tracked in Git)

## Technology Stack

- **Python 3.14+**
- **Sphinx** - Documentation generator
- **sphinx_rtd_theme** - Read the Docs theme
- **PowerShell** - Build automation
- **SQL Server** - Plant database (local dependency)

## Setup

1. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Build the website:
   ```bash
   cd Source
   sphinx-build -b html . ../Build
   ```

   Or use the PowerShell automation:
   ```powershell
   cd RSThtmlCreate
   .\PlantWeb_main.ps1
   ```

## Configuration

- **Source/conf.py** - Sphinx configuration
- **RSThtmlCreate/PlantWeb.xml** - Build automation settings

## Author

le Roux Cilliers  
© 2023-2025 Gardens4Comfort

## License

Private project - All rights reserved
