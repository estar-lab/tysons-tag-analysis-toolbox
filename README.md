Tyson Lin
tysonlin@umich.edu

This is the data processing pipeline for all tag kinematics data.

-----------------------------------------------------------------------------------------------

If you are working with a D4 tag, you must first run data_extraction_d4.m
The D4 file format is not normal, and must be extracted in a certain way. This
script extracts the data and saves it into a .mat file in the same directory that
the data was found. Set your desired names and filepaths on lines 8-17.  

-----------------------------------------------------------------------------------------------

Next, use the TagSlicer if you want to. See the README inside TagSlicer/ for what this tool does.
Not necessary to use. 

-----------------------------------------------------------------------------------------------

If you are doing a tag verification test, run one of the tag_verification scripts
single_tag_verification.m is an example that uses one tag
multi_tag_verification.m does the same thing but for multiple tags at the same time


