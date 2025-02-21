//Get the directory and file list of lifs to make composites out of as well as the number of markers
var lif_ListDir = "";
Dialog.createNonBlocking("Select folder of .lifs/.nd2s");
Dialog.addMessage("Make sure the target folder contains ONLY the .nd2s! No subfolders/other files");
Dialog.addDirectory("Choose folder that contains the .lifs/.nd2s you want to work with: ", "");
Dialog.addNumber("Enter number of channels:", 0);
Dialog.show();


var lif_ListDir = Dialog.getString();
var lif_List = getFileList(lif_ListDir);
var numMarkers = Dialog.getNumber();
var channels_array = newArray(numMarkers);
var markerNames_channels_array = newArray(numMarkers);

var i = 0;

Dialog.createNonBlocking("Enter marker information");
Dialog.addMessage("-Make sure you enter the markers in the order of their channels! For example, if DAPI was your first channel, put DAPI as marker #1 etc\n -Note that if you're using this macro on .nd2 files from the Nikon scope, the default bit depth is >8 and so the LUTS max contrast value should probably be much greater than 255");
for (i = 0; i < numMarkers; i++) {
	Dialog.addMessage("Enter marker #"+(i+1)+" information");
	Dialog.addString("Name", "");
	Dialog.addNumber("Threshhold Min:", 0);
	Dialog.addNumber("Threshhold Max:", 255);
	}

Dialog.show();
//Get the marker labels
var markerLabels = newArray(numMarkers);

for (i = 0; i < numMarkers; i++) {
	 markerLabels[i] = Dialog.getString();
}


var thresholdMax_array = newArray(numMarkers);
var thresholdMin_array = newArray(numMarkers);
for (i = 0; i < numMarkers; i++) {
	thresholdMin_array[i] = Dialog.getNumber();
	thresholdMax_array[i] = Dialog.getNumber();
	}

//Start the loop thru the folder
for (file = 0; file < lif_List.length; file++) {
	//open the file
	if (endsWith(lif_List[file], ".lif") > 0 || endsWith(lif_List[file], ".nd2") > 0){
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
		run("Analyze Particles...", "display summarize");
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