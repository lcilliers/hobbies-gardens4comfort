# Image Discrepancies - Investigation Required

**Date Identified**: December 24, 2025

## Summary
- **Source/Images**: 2,546 total files
- **Build/_images**: 2,455 total files  
- **Matching images**: 2,439 files (96%)

## Issue 1: 16 Images in Build but NOT in Source ⚠️

These images appear in Build/_images but are missing from Source/Images:

```
Image1119.JPG
Image1339.JPG
Image1358.JPG
Image140.JPG
Image1830.JPG
Image1849.JPG
Image1977.jpg
Image2072.JPG
Image2187.jpg
Image2247.JPG
(plus 6 more)
```

**Possible Causes:**
- Images were deleted from Source but Build wasn't regenerated
- Images were manually placed in Build directory
- Images may be in the temporary /Images/ folder and need to be moved to Source/Images

**Action Required:**
1. Check if these images exist in the temporary /Images/ folder
2. Verify if these images are still referenced in RST files
3. If referenced, copy them to Source/Images
4. If not referenced, investigate why they're in Build

## Issue 2: 107 Images in Source but NOT in Build

These images exist in Source/Images but aren't copied to Build (not referenced in any RST files):

**Examples:**
```
Image106.png, Image1159.png, Image118.png, Image1265.jpg
Image1300.JPG, Image1383.JPG, Image1680.png, Image1741.jpg
Image1822.jpe, Image2011.jpg, Image2038.jpg, Image2154.jpg
Image2201.jpg, Image2214.jpg, Image2218.jpg, Image2220.jpg
Image2243.jpg, Image2258.JPG, Image2262.jpg, Image2266.jpg
(plus 87 more)
```

**Possible Causes:**
- Old/unused images no longer referenced in content
- Images prepared for future use
- Images from deleted/archived content

**Action Required:**
1. Review if these images should be removed to reduce repository size
2. Or document them as archived/legacy images
3. Consider moving truly unused images to a separate archive location

## Investigation Steps

1. Generate list of all 16 missing images in Source
2. Search RST files for references to these images
3. Check temporary /Images/ folder for these files
4. Run full Sphinx rebuild to verify discrepancies
5. Clean up orphaned images if desired
