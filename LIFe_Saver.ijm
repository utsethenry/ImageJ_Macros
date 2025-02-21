//Get basic task info: do they wants JPEGs or TIFFs, do they want to apply LUTS, do they want an overlay, are these z stacks that
//need to be made into max projections
Dialog.create("Enter task information");
Dialog.addChoice("Do you want to save TIFFs or JPEGs?", newArray("Tiff", "Jpeg"));
Dialog.addCheckbox("Do you want to set LUTS contrast values?", false);
Dialog.addCheckbox("Do you want to save an overlay image?", false);
Dialog.addCheckbox("Do you want to save individual channels?", true);
Dialog.addCheckbox("Are these z-stacks you want to make max projections of? (e.g. 2-photon FDMs)", false);
//Dialog.addCheckbox("Is there a f-SHG channel (usually blue) that you want to ignore?", true);
Dialog.show();
var Tiff_or_Jpeg = Dialog.getChoice();
var LUTsTrueFalse = Dialog.getCheckbox();
var overlayTrueFalse = Dialog.getCheckbox();
var singleChannelsTrueFalse = Dialog.getCheckbox();
var stacksMax_TrueFalse = Dialog.getCheckbox();
//var ignorefSHG = Dialog.getCheckbox();

if (overlayTrueFalse && !LUTsTrueFalse) {
	Dialog.createNonBlocking("Warning");
	Dialog.addChoice("You specified you want an overlay but that you don't want to apply any LUTS––\n do you want to change to apply LUTS?", newArray("Yes", "No"));
	Dialog.show();
	var editLUTsChoice = Dialog.getChoice();
	if (editLUTsChoice == "Yes") {
		 LUTsTrueFalse = true
	}
}



//Get the directory and file list of lifs to make composites out of as well as the number of markers
var lif_ListDir = "";
Dialog.createNonBlocking("Select folder of .lifs/.nd2s");
Dialog.addMessage("Make sure the target folder contains ONLY the .lifs/.nd2s! No subfolders/other files");
Dialog.addDirectory("Choose folder that contains the .lifs you want to work with: ", "");
Dialog.addDirectory("Choose the folder to save the output images to:", "");
Dialog.addNumber("Enter number of channels:", 0);
Dialog.show();
var lif_ListDir = Dialog.getString();
var lif_List = getFileList(lif_ListDir);
var outputDir = Dialog.getString();
var numMarkers = Dialog.getNumber();

//Enter the marker names and make an array of them
var i = 0;
var LUTsColorChoicesArray = newArray("Blue","Cyan","Grays","Green", "Red","Magenta","Yellow");
var factorLUTsColorChoicesArray = newArray("Blue","Green","Yellow", "Magenta", "Red","Cyan","Grays");
Dialog.createNonBlocking("Enter marker information");
Dialog.addMessage("-Make sure you enter the markers in the order of their channels! For example, if DAPI was your first channel, put DAPI as marker #1 etc\n -Note that if you're using this macro on .nd2 files from the Nikon scope, the default bit depth is >8 and so the LUTS max contrast value should probably be much greater than 255");
for (i = 0; i < numMarkers; i++) {
	Dialog.addMessage("Enter marker #"+(i+1)+" information");
	Dialog.addString("Name", "");
	Dialog.addChoice("Desired LUT color:", LUTsColorChoicesArray, factorLUTsColorChoicesArray[i]);
	if (LUTsTrueFalse) {
		Dialog.addNumber("LUTS Min:", 0);
		Dialog.addNumber("LUTS Max:", 255);
	}
}
Dialog.show();
//Get the marker labels
var markerLabels = newArray(numMarkers);

for (i = 0; i < numMarkers; i++) {
	 markerLabels[i] = Dialog.getString();
}
//Get the marker LUTS color
var markerLUT_color = newArray(numMarkers);
for (i = 0; i < numMarkers; i++) {
	 markerLUT_color[i] = Dialog.getChoice();
}

//Get the LUTS max values
var LUTSmax_array = newArray(numMarkers);
var LUTSmin_array = newArray(numMarkers);
if (LUTsTrueFalse) {
	for (i = 0; i < numMarkers; i++) {
		LUTSmin_array[i] = Dialog.getNumber();
	 	LUTSmax_array[i] = Dialog.getNumber();
	}
}

//Start the loop thru the folder
for (i = 0; i < lif_List.length; i++) {
	//open the file
	run("Bio-Formats Importer", "open=["+lif_ListDir+lif_List[i]+"] open_all_series split_channels");
	while (nImages < 1) {
		wait(1000);
	}
	//Determine the number of series in the .lif
	var totalImages = nImages;
	var numSeries = (nImages-1)/numMarkers;
	//Loop thru each series to generate a composite
	var j = 0;
	for (j = 0; j < numSeries; j++) {
		var currentSeries = numSeries-j;
		wait(20);
		//Find the title of the last channel
		var FinalChannel = getTitle();
		//Make an array for all of the channel titles to be able to select them later
		var channelTitles = newArray(numMarkers);
		channelTitles[numMarkers-1] = FinalChannel;
		var z = 0;
		for (z = 0; z < numMarkers-1; z++) {
			channelTitles[z] = replace(FinalChannel, "C="+(numMarkers-1), "C="+z);
		}

		//Create all the outputImage names
		var outputImageNames = newArray(numMarkers);
		for (z = 0; z < numMarkers; z++) {
			outputImageNames[z] = replace(FinalChannel, " - C="+(numMarkers-1), "_"+markerLabels[z]);
			//outputImageNames[z] = replace(outputImageNames[z], lif_ListDir, "");
			outputImageNames[z] = replace(outputImageNames[z], ":", "");
			outputImageNames[z] = replace(outputImageNames[z], "/", "-");
		}
		//Create all the outputImage name alternatives for if there are multiple series
		var outputImageNames2 = newArray(numMarkers);
		for (z = 0; z < numMarkers; z++) {
			outputImageNames2[z] = replace(FinalChannel, " - Region"+currentSeries+" - C="+(numMarkers-1), "_Region"+currentSeries+"_"+markerLabels[z]);
			//outputImageNames2[z] = replace(outputImageNames2[z], lif_ListDir, "");
			outputImageNames2[z] = replace(outputImageNames2[z], ":", "");
			outputImageNames2[z] = replace(outputImageNames2[z], "/", "-");
		}
		
		//Create all outputMerge names
		var outputMergeName = "";
			outputMergeName = replace(FinalChannel, " - C="+(numMarkers-1), "_MERGE");
			//outputMergeName = replace(outputMergeName, lif_ListDir, "");
			outputMergeName = replace(outputMergeName, ":", "");
			outputMergeName = replace(outputMergeName, "/", "-");

		//Create all alternative outputMerge names for if there are multiple series
		var outputMergeName2 = "";
			outputMergeName2 = replace(FinalChannel, ".lif - Region"+currentSeries+" - C="+(numMarkers-1), "_Region"+currentSeries+"_Merge");
			//outputMergeName2 = replace(outputMergeName2, lif_ListDir, "");
			outputMergeName2 = replace(outputMergeName2, ":", "");
			outputMergeName2 = replace(outputMergeName2, "/", "-");
		
		//Convert the stacks into max projections if applicable
		var maxNames_array = newArray(numMarkers);
		if (stacksMax_TrueFalse) {
			for (z = 0; z < numMarkers; z++) {
				selectWindow(channelTitles[z]);
				run("Z Project...", "projection=[Max Intensity]");
				maxNames_array[z] = getTitle();
				//selectWindow(channelTitles[z]);
				//close();
			}
		}
		
		//Prep the channel names to correspond appropriately
		var k = 0;
		var mergeTitle = "";
		var colorIndexes = newArray(numMarkers);
		var colorSelections = newArray(numMarkers);
		var pastedImageChannels = "";
		var mergeColorChOptions = newArray("Red", "Green", "Blue", "Grays", "Cyan", "Magenta", "Yellow");
		var chOptions = newArray("c1=[", "c2=[", "c3=[", "c4=[", "c5=[", "c6=[", "c7=[");
		//Fill colorIndexes with the appropriate values
		if (overlayTrueFalse == true) {
			for (p = 0; p < numMarkers; p++) {
				for (k = 0; k < mergeColorChOptions.length; k++) {
					if (markerLUT_color[p] == mergeColorChOptions[k]){
						colorIndexes[p] = k;
						break;
					} //if markerLUT_color = color option loop close
				} //k loop close
			} //p loop close
			colorIndexes = Array.sort(colorIndexes);
			//Paste together all the channel/color:image matches for the merge string
			if (stacksMax_TrueFalse){
			for (k = 0; k < numMarkers; k++) {
					pastedImageChannels = pastedImageChannels + chOptions[colorIndexes[k]] + maxNames_array[k] + "] ";
				} //k loop close
			} else {
				for (k = 0; k < numMarkers; k++) {
					pastedImageChannels = pastedImageChannels + chOptions[colorIndexes[k]] + channelTitles[k] + "] ";
				} //k loop close
			}
		}
		
			
		//Save the overlay with/without LUTS as appropriate
		if (stacksMax_TrueFalse) {
			if (overlayTrueFalse) {
				for (z = 0; z < numMarkers; z++) {
					selectWindow(maxNames_array[z]);
					run(markerLUT_color[z]);
					if (LUTsTrueFalse) {
						setMinAndMax(LUTSmin_array[z], LUTSmax_array[z]);
					}
				}
				run("Merge Channels...", pastedImageChannels + " create keep");
				run("RGB Color");
				if (outputMergeName != FinalChannel) {
					saveAs(Tiff_or_Jpeg, outputDir+outputMergeName);
				} else {
					saveAs(Tiff_or_Jpeg, outputDir+outputMergeName2);
				}
				close();
				close();
			} //if overLayTrueFalse close
		
			//Save the single channels with/wihtout LUTS as appropriate
			if (singleChannelsTrueFalse) {
				for (z = 0; z < numMarkers; z++) {
					selectWindow(maxNames_array[z]);
					run(markerLUT_color[z]);
					if (LUTsTrueFalse) {
						setMinAndMax(LUTSmin_array[z], LUTSmax_array[z]);
						run("RGB Color");
						if (outputImageNames[z] != FinalChannel) {
							saveAs(Tiff_or_Jpeg, outputDir+outputImageNames[z]+"_LUTS");
						} else {
							saveAs(Tiff_or_Jpeg, outputDir+outputImageNames2[z]+"_LUTS");
					}
					} else if (!LUTsTrueFalse) {
						if (outputImageNames[z] != FinalChannel) {
						saveAs(Tiff_or_Jpeg, outputDir+outputImageNames[z]);
					}	else {
						saveAs(Tiff_or_Jpeg, outputDir+outputImageNames2[z]);
					}
					close();
					}
				}
				for (z = 0; z < numMarkers; z++) {
					if (isOpen(channelTitles[z])){
						selectWindow(channelTitles[z]);
						close();
					}
				}
				for (z = 0; z < numMarkers; z++) {
					if (isOpen(maxNames_array[z])){
						selectWindow(maxNames_array[z]);
						close();
					}
				}
			
			} else {
				for (z = 0; z < numMarkers; z++) {
					if (isOpen(channelTitles[z])){
						selectWindow(channelTitles[z]);
						close();
					}
				}
				for (z = 0; z < numMarkers; z++) {
					if (isOpen(maxNames_array[z])){
						selectWindow(maxNames_array[z]);
						close();
					}
				}
			}
		} else { //this is for non-stack-->max projection .lifs (e.g. IF)
			if (overlayTrueFalse) {
				for (z = 0; z < numMarkers; z++) {
					selectWindow(channelTitles[z]);
					run(markerLUT_color[z]);
					if (LUTsTrueFalse) {
						setMinAndMax(LUTSmin_array[z], LUTSmax_array[z]);
					}
				}
				run("Merge Channels...", pastedImageChannels + " create keep");
				run("RGB Color");
				if (outputMergeName != FinalChannel) {
					saveAs(Tiff_or_Jpeg, outputDir+outputMergeName);
				} else {
					saveAs(Tiff_or_Jpeg, outputDir+outputMergeName2);
				}
				close();
				close();
			} //if overLayTrueFalse close
		
			//Save the single channels with/without LUTS as appropriate
			if (singleChannelsTrueFalse) {
				for (z = 0; z < numMarkers; z++) {
					selectWindow(channelTitles[z]);
					run(markerLUT_color[z]);
					if (LUTsTrueFalse) {
						setMinAndMax(LUTSmin_array[z], LUTSmax_array[z]);
						run("RGB Color");
						if (outputImageNames[z] != FinalChannel) {
							saveAs(Tiff_or_Jpeg, outputDir+outputImageNames[z]+"_LUTS");
						} else {
							saveAs(Tiff_or_Jpeg, outputDir+outputImageNames2[z]+"_LUTS");
					}
					} else if (!LUTsTrueFalse) {
						if (outputImageNames[z] != FinalChannel) {
						saveAs(Tiff_or_Jpeg, outputDir+outputImageNames[z]);
					}	else {
						saveAs(Tiff_or_Jpeg, outputDir+outputImageNames2[z]);
					}
					close();
					}
				}
			for (z = 0; z < numMarkers; z++) {
				if (isOpen(channelTitles[z])){
					selectWindow(channelTitles[z]);
					close();
					}
				}

			}
			} 
			
		}//this is for multiple series
		while (nImages > 0 ) {
			close();
		}
	} //this is for the file list
