/*
To jest macro, ktore wykonuje pierwsze polecenie z pierwszych cwiczen.
1) Rozdziela kanaly
2) Konwertuje obraz do 8-bit
3) Tworzy Histogram, zeby sprawdzic przesycenie
4) Oddziela tlo
5) Filtruje za pomoca "Despeckle"
7) Sprawdza przesycenie jeszcze raz
6) Mierzy ROI
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
var totalOversaturatedPixelsAfter = 0;

var numChannelsAfterSplit = nImages(); 

// PROCESS IMAGES AND GET OVERSATURATED PIXELS BEFORE BACKGROUND SUBTRACTION
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

// APPLY BACKGROUND SUBTRACTION TO EACH CHANNEL
for (var i = 1; i <= numChannelsAfterSplit; i++) {
    selectImage(i);
    var channelName = getTitle();
    print("Processing image (for subtraction): " + channelName + ", Image ID: " + getImageID());

    Dialog.create("Background Subtraction for " + channelName);
    Dialog.addCheckbox("subtractBackground", true);
    Dialog.addNumber("rollingRadius", 20, 0, 100, 0); 
    Dialog.show();

    var subtractBackground = Dialog.getCheckbox();
    var rollingRadius = Dialog.getNumber();

    if (subtractBackground) {
        run("Subtract Background...", "rolling=" + rollingRadius);
        print("Background subtraction applied to " + channelName);

        // DODANIE FILTRA MEDIANOWEGO
        run("Despeckle");
        print("Despeckle filter applied to " + channelName);

        // CHECK OVERSATURATION AFTER BACKGROUND SUBTRACTION
        var valuesAfter = newArray(256);
        var countsAfter = newArray(256);
        getHistogram(valuesAfter, countsAfter, 256);

        oversaturated_pixels_after = countsAfter[255];
        totalOversaturatedPixelsAfter += oversaturated_pixels_after;

        print(channelName + ": Number of oversaturated pixels (after background subtraction): " + oversaturated_pixels_after);
    } else {
        print("No background subtraction applied to " + channelName);
    }
}

// ROI SELECTION AND MEASUREMENT
Dialog.create("ROI Selection");
Dialog.addCheckbox("useROI", true);
Dialog.addMessage("If checked, please use the ROI Manager to select ROIs.");
Dialog.show();
useROI = Dialog.getCheckbox();

if (useROI) {
    run("ROI Manager...");
    waitForUser("Use the ROI Manager to add and select ROIs, then press OK.");
    run("Measure");  // Measure the ROIs after they have been selected

    // Now collect the measurements from the results
    var measurements = newArray();  // Initialize an empty array
    var numResults = nResults();  // Get the number of results in the results table

    // Ensure that there are results to collect
    if (numResults > 0) {
        // Loop over the results to collect the measurements
        for (var i = 0; i < numResults; i++) {
            // Get measurement value, here I use "Area", but you can change it to other measurements like "Mean", "Max", etc.
            var measurementValue = getResult("Area", i);  
            
            // Manually extend the array to add the measurement
            measurements[measurements.length] = measurementValue;
            
            print("Measurement for ROI " + (i + 1) + ": " + measurementValue);
        }

        // Print all collected measurements (correcting the syntax error)
        print("All Measurements: ");
        for (var j = 0; j < measurements.length; j++) {
            print("Measurement " + (j + 1) + ": " + measurements[j]);
        }
    } else {
        print("No results to collect.");
    }
}

// SUMMARY DIALOG
Dialog.create("Summary");
Dialog.addMessage("Split Channels: " + splitChannels);
Dialog.addMessage("Background Subtraction Applied: " + subtractBackground);
Dialog.addMessage("ROI Used: " + useROI);
Dialog.show();

print("Split Channels: " + splitChannels);
print("Background Subtraction Applied: " + subtractBackground);
print("ROI Used: " + useROI);
