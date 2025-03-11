//-----------------------------------------------------------------------------
// name: sketch.js
// date: March 2025
// desc: This the processing.js code that runs in the browser and sends messages to the server.js code running locally
// usage: npm run start to serve the browser code
// This can be run from server (eg. aws, etc.) deployed online or locally -- but the server.js code must be run locally
//-----------------------------------------------------------------------------
let capture; //capture object representing webcam
let target_hue; //target color
let target_color = 255; //rgb of target
let targetIndex = 7; //default index for white -- not using in a substantial way
//hsv_colors -- ranges of the values for each color classification 
let redHSV = [
    0,
    60
];
let yellowHSV = [
    61,
    120
];
let greenHSV = [
    121,
    180
];
let cyanHSV = [
    181,
    240
];
let blueHSV = [
    241,
    300
];
let magentaHSV = [
    301,
    360
];
let blackThresh = 20;
let whiteThresh = 85;
//color definitions and thresholds for black, white, and grey which use saturation and brightness
let colorDefs = [
    redHSV,
    yellowHSV,
    greenHSV,
    cyanHSV,
    blueHSV,
    magentaHSV
];
var colorNames = [
    "red",
    "yellow",
    "green",
    "cyan",
    "blue",
    "magenta",
    "black",
    "white",
    "grey"
];
let colorThresh = 15;
let brightThresh = 30;
let satThresh = 30;
//an array that holds the color counts for each color classification
let colorCounts;
let usingNamedColor = false; //if true, use the named color for the target color but not really needed anymore
let targetCount = 0; //the target color count -- the target is special as it is much narrower range of the color space that the user chooses
//setup the canvas and the video capture
function setup() {
    createCanvas(500, 500);
    // Create the video capture and hide the element.
    capture = createCapture(VIDEO);
    capture.hide();
    describe('Color detection.');
    pixelDensity(1);
}
//draw the video capture and apply a blur filter to the image and call detect to find the colors in the image and send the OSC
function draw() {
    // Draw the video capture within the canvas.
    image(capture, 0, 0, width, width * capture.height / capture.width);
    filter(BLUR, 3, true);
    detect();
    fill(target_color);
    rect(25, 25, 25, 25);
}
//calls the server to send the color information to the OSC server using fetch()
function sendColorOSCInfo() {
    let percentTarget = targetCount / (width * height); //finds the percentage of the target color in the image
    let url = `http://localhost:3001/colorDetect?targetPercent=${percentTarget}`; //adds the target percent to the url
    for(let i = 0; i < colorCounts.length; i++)url += `&${colorNames[i]}=${colorCounts[i] / (width * height)}`; //adds the percent of each color to the url
    fetch(url); //calls the server using fetch
// console.log(url); //uncomment to see the url in the console
}
//detects the colors in the image and changes the color of the pixels that match the target color, also sends the color information to the server via sendColorOSCInfo()
function detect() {
    loadPixels(); //load current screen into pixel array
    colorCounts = [
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    ]; //init counts to have 0 for each color
    targetCount = 0; //init target count to 0
    //for each pixel, add to the colorCounts array the correct classification of the color & to the target count.
    for(let i = 0; i < width; i++)for(let j = 0; j < height; j++){
        //gets the color information of each pixel
        let loc = (i + width * j) * 4;
        let curColor = color(pixels[loc], pixels[loc + 1], pixels[loc + 2], pixels[loc + 3]);
        let cur = hue(curColor); //hue of the color
        let bright = brightness(curColor); //brightness of the color
        let satur = saturation(curColor); //saturation of the color
        let which = classifyColor(cur, bright, satur); //classifies the color based on hue, brightness, and saturation
        colorCounts[which]++; //adds to the color count for the classification
        //adds to the target count if the color is the target color (within a threshold)
        if (which == targetIndex && usingNamedColor || cur < hue(target_color) + colorThresh && cur > hue(target_color) - colorThresh && bright < brightness(target_color) + brightThresh && bright > brightness(target_color) - brightThresh && satur < saturation(target_color) + satThresh && satur > saturation(target_color) - satThresh) {
            //255, 105, 180 - hot pink
            pixels[loc] = 255;
            pixels[loc + 1] = 105;
            pixels[loc + 2] = 180;
            targetCount++;
        }
    }
    updatePixels(); //changes the pixels on screen
    sendColorOSCInfo(); //sends the color information to the server to send to the OSC elsewhere so we can receive in Chuck or Max or what have you
}
//classifies the color based on hue, brightness, and saturation
function classifyColor(cur, bright, sat) {
    let which = -1; //which color classification index (into the colorNames array)
    let index = 0; //for use when checking for the colors based on hues in the while loop below
    if (bright < blackThresh && sat < 30) which = 6;
    else if (bright > whiteThresh) which = 7;
    else if (sat < 20) which = 8;
    else while(which == -1){
        if (cur <= colorDefs[index][1]) which = index;
        index++;
    }
    return which; //return which index of the colorNames array the color is classified as
}
//prints the color information to the console -- all the % that each color is in the image including target percent
function printColorInfo(colorCounts) {
    //this sorts the colors by the number of pixels in the image that are that color -- not used now but could be useful
    let colorIndices = [
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8
    ];
    colorIndices.sort(function(a, b) {
        return colorCounts[b] - colorCounts[a];
    });
    //prints all the current color % to the console incl. target color
    print("========= Color Info =============");
    for(let i = 0; i < colorCounts.length; i++){
        let index = colorIndices[i];
        print(colorNames[index] + ": " + colorCounts[index] + " percent of image:" + colorCounts[index] / (width * height));
    }
    print("TARGET COLOR (more specific): Number of pixels with target color: " + targetCount + " percent of image:" + targetCount / (width * height));
    print("=================");
}
//when the mouse is clicked, get/change the target color and print those color details to the console
function mouseClicked() {
    loadPixels();
    let index = (mouseX + width * mouseY) * 4;
    target_color = color(pixels[index], pixels[index + 1], pixels[index + 2], pixels[index + 3]);
    target_hue = hue(target_color);
    let satur = saturation(target_color);
    print("Target color is: " + red(target_color) + "," + green(target_color) + "," + blue(target_color));
    print("Target hue is: " + target_hue);
    print("Target brightness is: " + brightness(target_color));
    print("Target saturation is: " + satur);
    targetIndex = classifyColor(target_hue, brightness(target_color), satur);
    print("Named color:" + colorNames[targetIndex] + ", " + targetIndex);
}
//when a key is pressed, print the color information to the console or you can change the color thresholds to make wider to narrow the color classification
function keyPressed() {
    if (key == ' ') printColorInfo(colorCounts); //print the color information to the console
    else if (key == 'q') {
        colorThresh++; //increase the target color threshold (allow a wider range of colors to be considered the target color)
        print("Color thresh is:" + colorThresh);
    } else if (key == 'a') {
        colorThresh--; //decrease the target color threshold (allow a smaller range of colors to be considered the target color)
        print("Color thresh is:" + colorThresh);
    }
}

//# sourceMappingURL=index.ba7f5425.js.map
