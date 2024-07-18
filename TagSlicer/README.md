Tyson Lin
tysonlin@umich.edu

This is the Tag Slicer tool. 

You would want to use this tool for one of two reasons:
1. There are multiple different trials in one data collection session that you want to split up.
2. There is a lot of junk data at the end of a data collection seesion, i.e the tag sitting on a
   boat for a while. You can use this tool to extract a certain portion of the data.

How do I use this tool?
1. Open up the example script
2. Verify that the depid and filepath are correct
3. Modify the partition_names array.
4. Run the example script
5. A window will pop up, and will ask you to draw a rectangle around each parition you want.
   So if you want to split your data into three parts, you will need to draw 3 rectangles.
   If you only want a portion of the data, you will have to draw 1 rectangle. This is all
   determined by the number of names provided in the partition_names array.
6. After drawing your rectangles, type 'y' to confirm them. If you are not satisfied with your 
   rectangles, 'n' will let you redraw the rectangles.

The resulting data will be saved into the directory where the data came from. There will be one 
.mat file per partition. 

The tag slicer outputs standardTag objects. So you must use the standardTag constructor on the resulting
partitions. 