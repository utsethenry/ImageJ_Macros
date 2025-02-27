//Get the directory and file list of lifs to make composites out of as well as the number of markers
var lif_ListDir = "";
Dialog.createNonBlocking("Select folder of .lifs/.nd2s");
Dialog.addMessage("Make sure the target folder contains ONLY the .nd2s! No subfolders/other files");
Dialog.addDirectory("Choose folder that contains the .lifs/.nd2s you want to work with: ", "");
Dialog.addNumber("Enter number of channels:", 0);
Dialog.addCheckbox("Are these z-stacks that you want to analyze as max projections?", 0);
Dialog.addCheckbox("Do you want to specify min/max particle sizes? Default is 0-Infinity", 0);
Dialog.show();

var max_projections = Dialog.getCheckbox();
var particleSize_yesno = Dialog.getCheckbox();


var lif_ListDir = Dialog.getString();
var lif_List = getFileList(lif_ListDir);
var numMarkers = Dialog.getNumber();
var channels_array = newArray(numMarkers);
var MaxProjection_array = newArray(numMarkers);
var markerNames_channels_array = newArray(numMarkers);

var i = 0;

Dialog.createNonBlocking("Enter marker information");
Dialog.addMessage("-Make sure you enter the markers in the order of their channels! For example, if DAPI was your first channel, put DAPI as marker #1 etc\n -Note that if you're using this macro on .nd2 files from the Nikon scope, the default bit depth is >8 and so the LUTS max contrast value should probably be much greater than 255");
for (i = 0; i < numMarkers; i++) {
	Dialog.addMessage("Enter marker #"+(i+1)+" information");
	Dialog.addString("Name", "");
	Dialog.addNumber("Threshhold Min:", 0);
	Dialog.addNumber("Threshhold Max:", 255);
	if (particleSize_yesno > 0) {
		Dialog.addNumber("Particle size minimum:", 0);
		Dialog.addNumber("Particle size maximum:", "Infinity");
	}
}

Dialog.show();
//Get the marker labels
var markerLabels = newArray(numMarkers);

for (i = 0; i < numMarkers; i++) {
	 markerLabels[i] = Dialog.getString();
}


var thresholdMax_array = newArray(numMarkers);
var thresholdMin_array = newArray(numMarkers);
var particleSizeMin_array = newArray(numMarkers);
var particleSizeMax_array = newArray(numMarkers);
for (i = 0; i < numMarkers; i++) {
	thresholdMin_array[i] = Dialog.getNumber();
	thresholdMax_array[i] = Dialog.getNumber();
	if (particleSize_yesno > 0) {
	particleSizeMin_array[i] = Dialog.getNumber();
	particleSizeMax_array[i] = Dialog.getNumber();
	}
}

if (particleSize_yesno < 1) {
	for (i = 0; i < numMarkers; i++) {
		particleSizeMin_array[i] = 0;
		particleSizeMax_array[i] = "Infinity";
	}

}

var num_Series = 0;
//Start the loop thru the folder
for (file = 0; file < lif_List.length; file++) {
	if (max_projections > 0 ) {
	//open the file
	if (endsWith(lif_List[file], ".lif") > 0 || endsWith(lif_List[file], ".nd2") > 0){
		run("Bio-Formats Importer", "open=["+lif_ListDir+lif_List[file]+"] open_all_series split_channels");
		while (nImages < 1) {
			wait(1000);
		}
		//run("8-bit"); running 8-bit on .nd2 files can mess up the nice scale sometimes, especially with small intensity values.
		//Thus, it is better to just keep the .nd2s in 16-bit format and use appropriate (i.e. much larger than 8-bit) thresholds
		num_Series = nImages/numMarkers-1;
		for (series = 0; series < num_Series; series++) {
		//Get the current image title to find the channels you need to interact with
		var lastChannel = getTitle();
		for (j = 0; j < numMarkers; j++) {
			channels_array[j] = replace(lastChannel, "C="+(numMarkers-1), "C="+j);
		}
		//Replace the channel numbers with human-readable marker names based on use input in markerLabels
		for (j = 0; j < numMarkers; j++) {
			markerNames_channels_array[j] = replace(channels_array[j], "C="+j, markerLabels[j]);
		}
		//Run max projection on each of the stacks of this image series and close the original stack
		for (j = 0; j < numMarkers; j++) {
			selectWindow(channels_array[j]);
			run("Z Project...", "projection=[Max Intensity]");
			MaxProjection_array[j] = getTitle();
			selectWindow(channels_array[j]);
			close();
		}
		//Now the stacks have been closed and only the max projections are open
		//Rename the max projections based on the marker names and run threshold analysis on them
		for (j = 0; j < numMarkers; j++) {
		selectWindow(MaxProjection_array[j]);
		rename(markerNames_channels_array[j]);
		setThreshold(thresholdMin_array[j],thresholdMax_array[j], "raw");
		run("Analyze Particles...", "size="+particleSizeMin_array[j]+"-"+particleSizeMax_array[j]+" display summarize");
		close();
		}
		//while (nImages > 0){
			//close();
		//}
		}
	}
	//This ends the version of the script for z-stack max projections
	//
	//Now begin the version of the script for 2D images
	} else if (endsWith(lif_List[file], ".lif") > 0 || endsWith(lif_List[file], ".nd2") > 0){
		run("Bio-Formats Importer", "open=["+lif_ListDir+lif_List[file]+"] open_all_series split_channels");
		while (nImages < 1) {
			wait(1000);
		}
		//run("8-bit"); running 8-bit on .nd2 files can mess up the nice scale sometimes, especially with small intensity values.
		//Thus, it is better to just keep the .nd2s in 16-bit format and use appropriate (i.e. much larger than 8-bit) thresholds
		var lastChannel = getTitle();
		for (j = 0; j < numMarkers; j++) {
			channels_array[j] = replace(lastChannel, "C="+(numMarkers-1), "C="+j);
		}
		for (j = 0; j < numMarkers; j++) {
			markerNames_channels_array[j] = replace(channels_array[j], "C="+j, markerLabels[j]);
		}
		for (j = 0; j < numMarkers; j++) {
		selectWindow(channels_array[j]);
		rename(markerNames_channels_array[j]);
		setThreshold(thresholdMin_array[j],thresholdMax_array[j], "raw");
		run("Analyze Particles...", "size="+particleSizeMin_array[j]+"-"+particleSizeMax_array[j]+" display summarize");
		close();
		}
		while (nImages > 0){
			close();
		}
	} else {
		print("Not a .nd2/.lif ("+lif_List[file]+")");
		continue;
	}
}