-- Count images that have been previously exported
SELECT COUNT(*) FROM Adobe_images AS image
JOIN Adobe_libraryImageDevelopHistoryStep AS step
WHERE image.id_local = step.image AND step.name LIKE "%Export%";

-- I think flagging corresponds to the 'pick' column in Adobe_images.
-- Evidence:
sqlite> select distinct pick from Adobe_images;
pick
0.0
-1.0
1.0

-- Flag all images that have been previously exported

UPDATE Adobe_images
SET pick = 1.0
WHERE local_id IN 
(SELECT image.id_local FROM Adobe_images AS image
JOIN Adobe_libraryImageDevelopHistoryStep AS step
WHERE image.id_local = step.image AND step.name NOT LIKE "%Export%");
