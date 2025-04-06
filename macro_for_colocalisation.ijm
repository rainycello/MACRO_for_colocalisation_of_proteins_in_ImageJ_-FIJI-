/*
To jest macro, ktore wykonuje pierwsze polecenie z pierwszych cwiczen.
1) Rozdziela kanaly
2) Konwertuje obraz do 8-bit
3) Tworzy Histogram, zeby sprawdzic przesycenie
4) Oddziela tlo
5) Filtruje za pomoca "Despeckle"
7) Sprawdza przesycenie jeszcze raz
6) Mierzy ROI

=============================================================================================================================================
Mierzy tylko jedno ROI na jeden preparat! Wzskakujace okienko "Results" pokazuje zmiezrone ROI dla kompozycji kanalow, czyli chociaz i bedzie 
pokazywalo ze pomiary odnosza sie roznych channels, w koncu beda pokazywaly pomiary tylko dla kompozytu channels
=============================================================================================================================================
*/

// SPLIT CHANNELS
Dialog.create("Split Channels");
Dialog.addCheckbox("splitChannels", true);
Dialog.show();
splitChannels = Dialog.getCheckbox();

if (splitChannels) {
    run("Split Channels");
    print("Channels have been split.");

    // ZMIANA NAZW KANAŁÓW
    var numChannels = nImages();
    for (var i = 1; i <= numChannels; i++) {
        selectImage(i);
        newTitle = "Channel_" + i;
        rename(newTitle);
        print("Renamed channel " + i + " to: " + newTitle);
    }
} else {
    print("Channels were not split.");
}

run("8-bit");

var totalOversaturatedPixelsBefore = 0;
var totalOversaturatedPixelsAfterBackgroundSubtraction = 0;
var totalOversaturatedPixelsAfterDespeckle = 0;

var numChannelsAfterSplit = nImages(); 

// UZYSKANIE PRZESYCONYCH PIKSELI PRZED ODEJMOWANIEM TLA
for (i = 1; i <= numChannelsAfterSplit; i++) {
    selectImage(i);
    var channelName = getTitle();
    print("Processing image (before subtraction): " + channelName + ", Image ID: " + getImageID());

    var values = newArray(256);
    var counts = newArray(256);
    getHistogram(values, counts, 256);

    oversaturated_pixels_before = counts[255];
    totalOversaturatedPixelsBefore += oversaturated_pixels_before;

    print(channelName + ": Number of oversaturated pixels (before background subtraction): " + oversaturated_pixels_before);
}

print("Total number of oversaturated pixels across all images (before background subtraction): " + totalOversaturatedPixelsBefore);

// SUBSTRAKCJA TLA WE WSZYSTKICH KANALACH
for (var i = 1; i <= numChannelsAfterSplit; i++) {
    selectImage(i);
    var channelName = getTitle();
    print("Processing image (for background subtraction): " + channelName + ", Image ID: " + getImageID());

    Dialog.create("Background Subtraction for " + channelName);
    Dialog.addCheckbox("subtractBackground", true);
    Dialog.addNumber("rollingRadius", 20, 0, 100, 0); 
    Dialog.show();

    var subtractBackground = Dialog.getCheckbox();
    var rollingRadius = Dialog.getNumber();

    if (subtractBackground) {
        run("Subtract Background...", "rolling=" + rollingRadius);
        print("Background subtraction applied to " + channelName);

        var valuesAfterBackgroundSubtraction = newArray(256);
        var countsAfterBackgroundSubtraction = newArray(256);
        getHistogram(valuesAfterBackgroundSubtraction, countsAfterBackgroundSubtraction, 256);
        var oversaturated_pixels_after_background_subtraction = countsAfterBackgroundSubtraction[255];
        totalOversaturatedPixelsAfterBackgroundSubtraction += oversaturated_pixels_after_background_subtraction;

        print(channelName + ": Number of oversaturated pixels (after background subtraction, before despeckle): " + oversaturated_pixels_after_background_subtraction);

        // DESPECKLE
        Dialog.create("Despeckle Parameters");
        Dialog.addNumber("despeckleRadius", 20, 0, 100, 0); 
        Dialog.show();
        var despeckleRadius = Dialog.getNumber();
        run("Despeckle", "radius=" + despeckleRadius);
        print("Despeckle filter applied to " + channelName);

        var valuesDespeckle = newArray(256);
        var countsDespeckle = newArray(256);
        getHistogram(valuesDespeckle, countsDespeckle, 256);
        var oversaturated_pixels_despeckle = countsDespeckle[255];
        totalOversaturatedPixelsAfterDespeckle += oversaturated_pixels_despeckle;

        print(channelName + ": Number of oversaturated pixels (after background subtraction and after despeckle): " + oversaturated_pixels_despeckle);
    } else {
        print("No background subtraction applied to " + channelName);
    }
}

// TOTAL OVERSATURATED PIXELS
print("Total number of oversaturated pixels across all images (after background subtraction and after despeckle): " + totalOversaturatedPixelsAfterDespeckle);

// ROI
Dialog.create("ROI Selection");
Dialog.addCheckbox("useROI", true);
Dialog.addMessage("If checked, please use the ROI Manager to select ROIs.");
Dialog.show();
useROI = Dialog.getCheckbox();

if (useROI) {
    run("ROI Manager...");
    roiCount = 0;
    while (roiCount == 0) {
        waitForUser("Please add at least ONE ROI using the ROI Manager, then click OK.");
        roiCount = roiManager("count");
        
        if (roiCount == 0) {
            showMessage("No ROIs Found", "You must select at least one ROI to continue.");
        }
    }
    
    run("Clear Results");

    var measurementIndex = 0;
    for (var i = 1; i <= numChannelsAfterSplit; i++) {
        selectImage(i);
        var channelName = getTitle();
        print("Measuring ROIs for " + channelName);

        for (var roiIndex = 0; roiIndex < roiCount; roiIndex++) {
            roiManager("select", roiIndex);
            roiManager("measure");

            var measurementValue = getResult("Area", nResults() - 1);
            setResult("Channel", measurementIndex, channelName);
            setResult("ROI", measurementIndex, roiIndex + 1);
            setResult("Area", measurementIndex, measurementValue);
            measurementIndex++;

            print(channelName + " - ROI " + (roiIndex + 1) + ": " + measurementValue);
        }
    }
}

Dialog.create("Colocalization Analysis");
Dialog.addCheckbox("runColoc", true);
Dialog.addChoice("Colocalize channels:", newArray("Channel_1 & Channel_2", "Channel_1 & Channel_3", "Channel_2 & Channel_3"), "Channel_1 & Channel_2");
Dialog.show();
runColoc = Dialog.getCheckbox();
selectedPair = Dialog.getChoice();

if (runColoc) {
    splitPair = split(selectedPair, " & ");
    channelA = splitPair[0];
    channelB = splitPair[1];
    
    selectWindow(channelA);
    run("Duplicate...", "title=colocA");
    selectWindow(channelB);
    run("Duplicate...", "title=colocB");

    if (nImages() > 2) {
        print("Attempting colocalization on channels: " + channelA + " and " + channelB);
        
        selectWindow("colocA");
        run("Merge Channels...", "c1=colocA c2=colocB create keep");
        run("Coloc 2", "channel_1=colocA channel_2=colocB");

        print("Colocalization analysis run on " + channelA + " and " + channelB);
    } else {
        print("Not enough images to perform colocalization.");
    }
}
