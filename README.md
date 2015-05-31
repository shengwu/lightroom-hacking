Lightroom hacking
=================

The problem
-----------
So Google Photos is awesome. It has already backed up all of the photos on my phone, but I want to upload all of the photos I've exported from Lightroom in the past. The problem is they've all been exported with a maximum dimension of 1600 since that's the most you really need when uploading to Facebook. And there's no easy way in Lightroom to re-export all of your previously exported photos.

The solution
------------
Well, I thought about going through and flagging each of the exported photos manually. But there has to be a better way. Maybe the catalog files would be a good place to start. Hopefully they're not incomprehensible binary blobs.

```
➜  Lightroom  head Lightroom\ 5\ Catalog.lrcat
SQLite format 3@  9▒X▒9-▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒7K%indexsqlite_autoindex_Adobe_images_1Adobe_images▒H77▒/tableAgLibraryKeywordImageAgLibraryKeywordImageCREATE TABLE AgLibraryKeywordImage (
    id_local INTEGER PRIMARY KEY,
    image INTEGER NOT NULL DEFAULT 0,
    tag INTEGER NOT NULL DEFAULT 0
)▒A==▒tableAdobe_imageProofSettingsAdobe_imageProofSettingsCREATE TABLE Adobe_imageProofSettings (
    id_local INTEGER PRIMARY KEY,
    colorProfile,
    image INTEGER,
    renderingIntent
)▒NUU▒tableAdobe_libraryImageDevelopHistoryStepAdobe_libraryImageDevelopHistoryStepCREATE TABLE Adobe_libraryImageDevelopHistoryStep (
```

Bingo! They're sqlite3 files. Let's poke around.

```
➜  Lightroom  sqlite3 Lightroom\ 5\ Catalog.lrcat
SQLite version 3.8.10.2 2015-05-20 18:17:19
Enter ".help" for usage hints.
sqlite> .tables
Adobe_AdditionalMetadata
Adobe_faceProperties
Adobe_imageDevelopBeforeSettings
Adobe_imageDevelopSettings
Adobe_imageProofSettings
Adobe_imageProperties
Adobe_images
Adobe_libraryImageDevelopHistoryStep
Adobe_libraryImageDevelopSnapshot
Adobe_libraryImageFaceProcessHistory
Adobe_namedIdentityPlate
Adobe_variables
Adobe_variablesTable
AgDNGProxyInfo
AgDeletedOzAlbumAssetIds
AgDeletedOzAlbumIds
AgDeletedOzAssetIds
AgFolderContent
AgHarvestedDNGMetadata
...
```

I have no idea what any of the tables are for, but the `Adobe_images` and `Adobe_libraryImageDevelopHistoryStep` tables look promising.

```
sqlite> .headers on
sqlite> select * from Adobe_images limit 1;
id_local|id_global|aspectRatioCache|bitDepth|captureTime|colorChannels|colorLabels|colorMode|copyCreationTime|copyName|copyReason|developSettingsIDCache|fileFormat|fileHeight|fileWidth|hasMissingSidecars|masterImage|orientation|originalCaptureTime|originalRootEntity|panningDistanceH|panningDistanceV|pick|positionInFolder|propertiesCache|pyramidIDCache|rating|rootFile|sidecarStatus|touchCount|touchTime
29|65012D8B-C8F1-415E-BBC9-980E54FC4C98|0.666666666666667|16.0|2010-10-09T13:23:50.02|3.0||32803.0|-63113817600.0|||35.0|RAW|2848.0|4272.0|||DA|||||0.0|z||none||30|1.0|0.0|0.0
sqlite> select * from Adobe_libraryImageDevelopHistoryStep limit 1;
id_local|id_global|dateCreated|digest|hasDevelopAdjustments|image|name|relValueString|text|valueString
33|44F3381B-A851-4C34-9CC0-96926E8FEE13|308384619.894662|3b8c8abdf590866313ed1fb62129c904|-1.0|29|Import (10/10/2010 1:23:39 AM)||s = { AutoGrayscaleMix = true,
Brightness = 50,
CameraProfile = "Adobe Standard",
CameraProfileDigest = "162E063AD6FEDE4357249927BD89FB79",
ColorNoiseReduction = 25,
Contrast = 25,
ConvertToGrayscale = false,
Exposure = 0,
GrainSize = 25,
LensManualDistortionAmount = 0,
LensProfileEnable = 0,
LensProfileSetup = "LensDefaults",
LuminanceNoiseReductionContrast = 0,
PerspectiveHorizontal = 0,
PerspectiveRotate = 0,
PerspectiveScale = 100,
PerspectiveVertical = 0,
ProcessVersion = "5.7",
RedEyeInfo = {  },
RetouchInfo = {  },
Shadows = 5,
SharpenDetail = 25,
SharpenEdgeMasking = 0,
SharpenRadius = 1,
Sharpness = 25,
ToneCurve = { 0,
0,
32,
22,
64,
56,
128,
128,
192,
196,
255,
255 },
ToneCurveName = "Medium Contrast",
Version = "6.1",
WhiteBalance = "As Shot" }
|
```

These two tables should be enough to give us the ids of all images that we've exported. Plan: filter the develop steps by keeping the ones that have a `name` field containing the word "Export".

But where are the flags kept? After exploring a bunch of the other tables, I look at `Adobe_images` again and suspect that it's in the `pick` column. To confirm, let's look at the possible values:

```
sqlite> select distinct pick from Adobe_images;
pick
0.0
-1.0
1.0
```

Excellent. Finally, we make a backup copy of the catalog file and run the following to flag all previously exported images. (probably not the best SQL)

```
UPDATE Adobe_images
SET pick = 1.0
WHERE id_local IN 
(SELECT image.id_local FROM Adobe_images AS image
JOIN Adobe_libraryImageDevelopHistoryStep AS step
WHERE image.id_local = step.image AND step.name NOT LIKE "%Export%");
```

With fingers crossed, I open Lightroom. Yes, it worked! All that remains is to remove the images that I've exported for HDR processing and other photos that I don't want to include in my library.

Note: please proceed carefully and make backups before running any commands on your catalog. I'm not responsible if this deletes all of your edit history or sets your cat on fire.

License
-------
MIT LICENSE

Copyright (c) 2015 Sheng Wu

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
