// ------------------------- Status ----------------------------------//
// This script has been created by Jeppe Tranberg Jensen.
// Please contact me at jeppetranbergjensen@gmail.com if you may encounter any problems.
// Please acknowledge my work in any publications.

//-----------------------------------------------------------------------------//
// -------------------------------- Functions ---------------------------------//
//-----------------------------------------------------------------------------//

// make a function to make concentric circles
function makeConcentricCircles(CenterX, CenterY, ImplantDiameter){
	// Set colour of lines and circles
	setColor("Red");

	// unscale to pixels
	toUnscaled(ImplantDiameter);
	toUnscaled(CenterX, CenterY);

	// implant circle
	ImpDia = ImplantDiameter;
	ImpRad = ImpDia / 2;
	xImp = CenterX - ImpRad;
	yImp = CenterY - ImpRad;
	makeOval(xImp, yImp, ImpDia, ImpDia);
	run("Add Selection...");

	// set the spacing between the rings after imp offset
	// um
	DiaSpacing = 2000;
	// pixels
	toUnscaled(DiaSpacing);
	
	// loop to 3 to add 3 circles
	for (i = 0; i < 3; i++) {

		// define parameters
		// for comparative measurements, the diameter of the circles should be constant and independent of the implant diameter. Which I think cannot be used as an reference point
		// Thus fix it at 1000um, as we now have the metadata, this is possible
		// First DIA = implantdiameter + 1000 + 1000
		
		Dia = ImplantDiameter + (DiaSpacing * (i + 1));
		Rad = Dia / 2;
		xR = CenterX - Rad;
		yR = CenterY - Rad;

		// create circle by bounding rectangle
		makeOval(xR, yR, Dia, Dia);

		// Add selection to ROImanager
		roiManager("add");

		// select the latest roimanager addition and rename
		roiManager("select", roiManager("count")-1);
		CircleName = "Circle " + ( i + 1) + "";
		roiManager("Rename", CircleName);
		
		// add to overlay
		run("Add Selection...");

		// deselect in ROIman
		roiManager("deselect");
	}

	// after the circles have been added, now add the lines
	// compute line coordinates 
	Line1EndX = xR + Dia;
	Line1EndY = yR + Dia;

	// from upper left to lower right
	makeLine(xR, yR, Line1EndX, Line1EndY);
	run("Add Selection...");
	
	// from lower left to upper right
	Line2StartY = yR + Dia;
	makeLine(xR, Line2StartY, Line1EndX, yR);
	run("Add Selection...");

	// show overlay
	run("Show Overlay");

	// remove any latent selections
	run("Select None");
}

// used for positioning images in the middle of the screen
function SetCenter(ScrX, ScrY) {
	getLocationAndSize(ImgX, ImgY, ImgWidth, ImgHeight);
	CenterW = ScrX / 2;
	CenterH = ScrY / 2;
	ImgCordX = CenterW - (ImgWidth / 2);
	ImgCordY = CenterH - (ImgHeight / 2);
	setLocation(ImgCordX, ImgCordY);
}

// The function creates a table for the collection of data
function CreateResultsReplica(TableName, TableW, TableH, TableLocX, TableLocYStart){
	ResultsHeading = split(String.getResultsHeadings); // Creates an array of the chosen measurement settings
	TableHeadings = "";
	for (i=0; i<ResultsHeading.length; i++){
		TableHeadings = TableHeadings + ResultsHeading[i] + "\t"; // This loop assembles a string based on the acquired measurement settings, delimited with tabs
	}
	TableHeading = "\\Headings: " + TableHeadings; // Creates the Heading string to be implemented in the tables
	TableNameBrac = "["+ TableName + "]"; // Creates a bracketed name, required to make and print to tables
	run("New... ", "name=" + TableNameBrac + " type=Table"); // Create a table
	Table.setLocationAndSize(TableLocX, TableLocYStart, TableW, TableH, TableName); // Set table location to the right side of the screen with sizes based on the screen size
	print(TableNameBrac, TableHeading); // Insert heading in the table
	wait(100); // we have to wait a bit as printing to the tables takes a while. If the loop starts too early, then the definitions change, and the printing will not work.
	return TableNameBrac; // to create lists need with datatable bracket names
}

// The below function extracts results from the resultstable and transfers them to another table
// This function needs simplification, as it should just take all the measurements. 
function DataGrabberFunction(OutputTableName){ // The function receives the destination table for the data and an array containing the data labels it needs to extract values from
	// check the number of already filed results
	ResultsHeading = split(String.getResultsHeadings);
	// retrieve results and print to output table
	Results = "";
	for (i = 0; i < nResults; i++) {
		for (z=0; z<ResultsHeading.length; z++){ // A loop that runs through the given array containing the result labels, which values are to be extracted.
			Result = getResultString(ResultsHeading[z], i); 
			Results = Results + Result + "\t";	
		}
		print(OutputTableName, Results); // The data is now saved to the output table
		wait(100);
		Results = "";
	}
}

function ArrangeWindows(ImageTitle, SH, SW) { 
	OpenWindows = getList("window.titles");

	// match the active image to the screen width
	selectWindow(ImageTitle);
	getLocationAndSize(x, y, width, height);
	setLocation(0, 0, SW/2, SH);

	// for the open windows and tables
	// figure out how much height the can get
	WindowH = SH/(OpenWindows.length + 1);
	for (i = 0; i < OpenWindows.length; i++) {
		selectWindow(OpenWindows[i]);
		yPos = (i + 1) * WindowH;
		xPos = SW/2;
		Table.setLocationAndSize(xPos, yPos, xPos, WindowH, OpenWindows[i]);
	}
}


//-------------------------------------------------------------------------------------------------//
// -------------------------------- File dialog and configuration ---------------------------------//
//-------------------------------------------------------------------------------------------------//

#@ File (label="Select input directory", style="directory") inDir
#@ File (label="Select output directory", style="directory") outDir

outDir = outDir + "/";
inDir = inDir + "/";

// list the files in the input directory
fileList = getFileList(inDir);

// Finds the number of already processed files based on the number of image files in the output folder
//CurPro = CurrentProgress(outDir);

// get screen dimensions
// get screen dimension
ScreenH = screenHeight;
ScreenW = screenWidth;

// Either open or define file log
LogPath = outDir + "FileLog";
if (File.exists(LogPath) == true) {
	LogString = File.openAsString(LogPath);
	Log = split(LogString, "\n");
} else {
	Log = newArray(0);
}


// Retrive existing data? to make a combined result txt file
// Check if there already exists and existing table in the output folder
ResultPath = outDir + "ResultsCollection.txt";
if (File.exists(ResultPath) == true) {
	Table.open(ResultPath);
	Table.showRowNumbers(0);
	Table.showRowIndexes(0);
	Table.rename("ResultsCollection.txt", "ResultsCollection");

	// Set position

}

//ProcessedFiles = Table.getColumn("Label");
// filter for unique labels
// https://imagej.nih.gov/ij/macros/Array_Functions.txt


// clean filelist for subfolders and already processed files
NewFileList = newArray(0);

for (i = 0; i < fileList.length; i++) {
	file = fileList[i];
	if (endsWith(file, "/") == false) {
		NewFileList = Array.concat(NewFileList, file);
	}
}
if (Log.length > 0) {
	NewFileList2 = NewFileList;
	for (i = 0; i < Log.length; i++) {
		ProcessedFile = Log[i];
		for (t = 0; t < NewFileList.length; t++) {
			if (ProcessedFile.matches(NewFileList[t]) == true) {
				NewFileList2 = Array.deleteValue(NewFileList2, NewFileList[t]);
			}
		}		
	}
} else {
	NewFileList2 = NewFileList;
}

//--------------------------------------------------------------------------//
//----------------------------------- Start --------------------------------//
//--------------------------------------------------------------------------//

// Define dialog choices
BoneChoices = newArray("Developing", "Resting", "Degrading", "NA");
BoneColours = newArray("green", "yellow", "black", "gray");

// clear results
run("Clear Results");

for (j = 0; j < NewFileList2.length; j++) {
	InputPath = inDir + NewFileList2[j];

	// load image 
	open(InputPath);
	
	OriginalImg = getTitle();

	// Log the processed file names. 
	Log = Array.concat(Log, OriginalImg);
	
	// get properties
	numberX = Property.get("PhysicalSizeX");
	numberY = Property.get("PhysicalSizeY");
	PixelX = numberX.substring(1, 20); 
	PixelY = numberY.substring(1, 20); 
	PixelX = parseFloat(PixelX);
	PixelY = parseFloat(PixelY);
	
	// the overall image dimensions are off by  0.5 microns. which isnt a lot in the grand scheme of things. 
	// this is due to the rounding of parse float
	
	// set properties
	run("Properties...", "unit=micron channels=1 slices=1 frames=1 pixel_width=" + PixelX + " pixel_height=" + PixelY + " voxel_depth=" + PixelX);
	
	// set location to center
	SetCenter(ScreenW, ScreenH);
	
	// duplicate
	run("Duplicate...", " ");
	Duplicate = getTitle();
	
	// set location to center
	SetCenter(ScreenW, ScreenH);
	
	// convert to 8 bit
	run("8-bit");
	wait(100);
	
	// make a rectangle around the hole
	setTool("rectangle");
	setColor("Red");
	waitForUser("Make rectangle around implant", "make a small rectangle enclosing the implant");
	
	// clear outside 
	
	//setBackgroundColor(255, 255, 255);
	setBackgroundColor(0, 0, 0);
	run("Clear Outside");
	
	// filter, perhaps a gaussian blur
	run("Gaussian Blur...", "sigma=50");
	
	// deselect
	run("Select None");
	
	// threshold2
	run("Auto Threshold", "method=Li white");
	
	// restore selection
	run("Restore Selection");
	
	// set bg to white
	setBackgroundColor(255, 255, 255); // set bg to white
	
	// make background white
	run("Clear Outside");
	
	// Run analyze particles, set measurements to coordinates
	run("Set Measurements...", "centroid center feret's display add redirect=None decimal=2");
	run("Analyze Particles...", "size=1000000-Infinity circularity=0.60-1.00 show=Nothing display");

	
	// extract results XM and YM, the center coordinates
	xCoordinate = getResult("XM");
	yCoordinate = getResult("YM");

	// extract the diameter
	FeretDia = getResult("Feret");
	FeretMin = getResult("MinFeret");
	ImplantDiameter = (FeretDia + FeretMin)/2;

	// remove the latest result specifically from the results window
	IJ.deleteRows(nResults-1, nResults);

	// close duplicate
	close(Duplicate);
	selectWindow(OriginalImg);
	
	// add grid
	// compute the area in micrometers of one pixel
	PixelArea = PixelX * PixelY;

	// Set grid size to 10.000 µm^2
	GridSizeMicro = 10000;

	// Grid size in pixels
	GridSizePixels = GridSizeMicro / PixelArea;

	// place grid
	run("Grid...", "grid=Lines area=" + GridSizePixels + " color=Cyan");
	
	// add concentric circles
	makeConcentricCircles(xCoordinate, yCoordinate, ImplantDiameter);


	run("Set Measurements...", "centroid display add redirect=None decimal=2");
	
	
	// make sure that the overlay cannot be manipulated
	Overlay.selectable(false);
	
	// begin the measurements

	run("Point Tool...", "type=Dot color=Red size=Small label counter=0");
	setTool("multipoint");

	// rearrange and enlarge windows
	ArrangeWindows(OriginalImg, ScreenH, ScreenW);
	
	// let user set points
	//waitForUser("Place dots of one category", "Mark grid-bone intersections. \nUse q,w,e and r to switch categories. \nUse m to measure.\nWhen the image is complete, press OK");
	Dialog.createNonBlocking("Place dots of one category");
	Dialog.addMessage("Mark grid-bone intersections. \nUse q,w,e and r to switch categories. \nq=Developing\nw=Resting\ne=Degrading\nr=NA\nUse m to measure.\nWhen the image is complete, press OK\nIf this is the last image to process, use the checkbox.");
	Dialog.addCheckbox("Close after this Image?", 0);
	Dialog.setLocation(ScreenW/2, 0);
	Dialog.show();

	ContinueOrStopMacro = Dialog.getCheckbox();


	
	//--------- Result modification ---------------//

	// make sure to not loop over previous measurements.
	// or use data grabber immediately to remove them. 
	
	for (i = 0; i < nResults; i++) {

		// retrieve the measurement colour
		Colour = getResultString("Colour", i);
		
		// match measured colour to bonetype
		for (r = 0; r < BoneChoices.length; r++) {
			BoneCol = BoneColours[r];
			if (BoneCol.matches(Colour)) {
				setResult("BoneType", i, BoneChoices[r]);
			}
		}
		

		// Set the position based on point coordinates
		if (getResult("Y", i) > yCoordinate) {
			setResult("Position", i, "Posterior");
		} else {
			setResult("Position", i, "Anterior");
		}

		// Set the Circle positions
		PointCordX = getResult("X", i);
		PointCordY = getResult("Y", i);
		nROI = roiManager("count");

		toUnscaled(PointCordX, PointCordY);

		// make an array of positions
		CircSum = 0;

		// loop through roimanager and select circles one by one
		for (m = 0; m < nROI; m++) {
			roiManager("select", m);
			InCirc = Roi.contains(PointCordX, PointCordY);
			
			// increase sum by the number of circles the point appears in
			CircSum = CircSum + InCirc;
		}
		// deselect the circles from the ROI manager and as selection
		roiManager("deselect");
		run("Select None");

		// convert and set circle number
		Circ = 4 - CircSum;
		setResult("Circle", i, Circ);

		// update the result so changes appear in the result window
		updateResults();
	}
	// reset the roimanager, so it doesnt fill with circle ROIs
	roiManager("reset");

	// keep results, use datagrabber to transport into a new table, save.
    // Make a results replica table, if it is not already open
	if (isOpen("ResultsCollection") == false){
							
		// Set new table height and width based on screen dimension
		TableW = ScreenW/2;
		TableH = ScreenH/2;
		TableLocX = ScreenW/2;
	
		//Create Collection table
	 	CreateResultsReplica("ResultsCollection", TableW, TableH, TableLocX, 0);
	
		// Set position
	}
    // Retrieve data from the Results table and save to Collection table
    DataGrabberFunction("[ResultsCollection]");

   	//Close results
    selectWindow("Results");
	run("Close"); 

    // Save and close image
    selectWindow(OriginalImg);
    dotIndex = indexOf(OriginalImg, ".");
	Title = substring(OriginalImg, 0, dotIndex);
    saveAs("tiff", outDir + Title + "_traced.tif");
    close("*");

	// if the user has chosen to stop for today..
	// log the files and results and close macro
	if (ContinueOrStopMacro == 1) {
		// Save the collected results as a new unexcisting file
		selectWindow("ResultsCollection");
		saveAs("txt", outDir + "ResultsCollection" + ".txt");
		run("Close");
		
		// Save fileLog
		// create a string of files
		str = "";
		for (i = 0; i < Log.length; i++) {
			str = str + Log[i] + "\n";
		}
		File.saveString(str, LogPath);

		// close ROI manager
		selectWindow("ROI Manager");
		run("Close");

		// exit macro
		exit;
	}


}
// Save the collected results as a new unexcisting file
selectWindow("ResultsCollection");
saveAs("txt", outDir + "ResultsCollection" + ".txt");
run("Close");

// Save fileLog
// create a string of files
str = "";
for (i = 0; i < Log.length; i++) {
	str = str + Log[i] + "\n";
}
File.saveString(str, LogPath);

// close ROI manager
selectWindow("ROI Manager");
run("Close");

// exit macro
exit;
