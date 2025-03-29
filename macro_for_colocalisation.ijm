/*
To jest macro, ktore wykonuje pierwsze polecenie z pierwszych cwiczen.
1) Rozdziela kanaly
2) Konwertuje obraz do 8-bit
3) Tworzy Histogram, zeby sprawdzic przesycenie
4) Oddziela tlo
5) Sprawdza przesycenie jeszcze raz
6) Wybiera Region Of Interest
7) Wykonuje pomiar w zakresie ROI za pomoca plugin'u coloc2
*/

// SPLIT CHANNELS
Dialog.create("Split Channels");
Dialog.addCheckbox("splitChannels", true);  
Dialog.show();
splitChannels = Dialog.getCheckbox(); 

if (splitChannels) {
    run("Split Channels");
}

run("8-bit"); 

var totalOversaturatedPixelsBefore = 0; 
var totalOversaturatedPixelsAfter = 0;

// PROCESS IMAGES AND GET OVERSATURATED PIXELS BEFORE BACKGROUND SUBTRACTION
for (i = 1; i <= nImages(); i++) {
    selectImage(i);
    
    var values = newArray(256); 
    var counts = newArray(256);   
    getHistogram(values, counts, 256); 
    
    oversaturated_pixels_before = counts[255]; 
    totalOversaturatedPixelsBefore += oversaturated_pixels_before;

    print("Image " + i + ": Number of oversaturated pixels (before background subtraction): " + oversaturated_pixels_before);
}

print("Total number of oversaturated pixels across all images (before background subtraction): " + totalOversaturatedPixelsBefore);

// APPLY BACKGROUND SUBTRACTION TO EACH CHANNEL
var channels = newArray(nImages());
for (i = 1; i <= nImages(); i++) {
    selectImage(i);
    channels[i - 1] = getTitle(); // Retrieve and store the title of each image
}

for (var channelIndex = 0; channelIndex < channels.length; channelIndex++) {
    var channel = channels[channelIndex];
    
    Dialog.create("Background Subtraction for " + channel);
    Dialog.addCheckbox("subtractBackground", true);
    Dialog.addNumber("rollingRadius", 20, 0, 100); // Add a dialog for radius selection
    Dialog.show();
    var subtractBackground = Dialog.getCheckbox();
    var rollingRadius = Dialog.getNumber();

    if (subtractBackground) {
        selectImage(channelIndex + 1); // Select the image by index
        run("Subtract Background...", "rolling=" + rollingRadius); 
        print("Background subtraction applied to " + channel);
        
        // CHECK OVERSATURATION AFTER BACKGROUND SUBTRACTION
        var values = newArray(256); 
        var counts = newArray(256);   
        getHistogram(values, counts, 256); 
        
        oversaturated_pixels_after = counts[255]; 
        totalOversaturatedPixelsAfter += oversaturated_pixels_after;

        print(channel + ": Number of oversaturated pixels (after background subtraction): " + oversaturated_pixels_after);
    } else {
        print("No background subtraction applied to " + channel);
    }
}

print("Total number of oversaturated pixels across all images (after background subtraction): " + totalOversaturatedPixelsAfter);

// ROI SELECTION AND MEASUREMENT
Dialog.create("ROI Selection");
Dialog.addCheckbox("useROI", true);
Dialog.show();
useROI = Dialog.getCheckbox();

if (useROI) {
    makeRectangle(50, 50, 100, 100);  
    run("Measure"); 
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

// BIT DEPTH
var imageID = getImageID();
var bitDepth = getInfo(imageID, "bit-depth");
print("Bit Depth: " + bitDepth);
