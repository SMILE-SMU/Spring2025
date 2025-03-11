let capture; //capture object representing webcam
let target_hue; //target color
let target_color = 255; //rgb of target
let targetIndex = 7;
//hsv_colors
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
//let colorDefs = [redHSV, yellowHSV, greenHSV, cyanHSV, blueHSV, magentaHSV ];
//let colorNames = ["White", "Silver", "Gray", "Black", "Red", "Maroon", "Yellow", "Olive", "Lime", "Green", "Aqua", "t ];
let colorCounts;
let usingNamedColor = false;
let targetCount = 0;
// let osc = new OSC(); // Create a new OSC object
// osc.open();
function setup() {
    createCanvas(500, 500);
    // Create the video capture and hide the element.
    capture = createCapture(VIDEO);
    capture.hide();
    describe('Color detection.');
    pixelDensity(1);
}
function draw() {
    // Draw the video capture within the canvas.
    image(capture, 0, 0, width, width * capture.height / capture.width);
    filter(BLUR, 3, true);
    detect();
    fill(target_color);
    rect(25, 25, 25, 25);
}
function sendColorOSCInfo() {
    let percentTarget = targetCount / (width * height);
    let url = `http://localhost:3001/colorDetect?targetPercent=${percentTarget}`;
    for(let i = 0; i < colorCounts.length; i++)url += `&${colorNames[i]}=${colorCounts[i] / (width * height)}`;
    fetch(url);
    console.log(url);
}
function detect() {
    loadPixels();
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
    ];
    targetCount = 0;
    for(let i = 0; i < width; i++)for(let j = 0; j < height; j++){
        let loc = (i + width * j) * 4;
        let curColor = color(pixels[loc], pixels[loc + 1], pixels[loc + 2], pixels[loc + 3]);
        let cur = hue(curColor);
        let bright = brightness(curColor);
        let satur = saturation(curColor);
        let which = classifyColor(cur, bright, satur);
        colorCounts[which]++;
        if (which == targetIndex && usingNamedColor || cur < hue(target_color) + colorThresh && cur > hue(target_color) - colorThresh && bright < brightness(target_color) + brightThresh && bright > brightness(target_color) - brightThresh && satur < saturation(target_color) + satThresh && satur > saturation(target_color) - satThresh) {
            //255, 105, 180 - hot pink
            pixels[loc] = 255;
            pixels[loc + 1] = 105;
            pixels[loc + 2] = 180;
            targetCount++;
        }
    }
    updatePixels();
    sendColorOSCInfo();
}
function classifyColor(cur, bright, sat) {
    let which = -1;
    let index = 0;
    if (bright < blackThresh && sat < 30) which = 6;
    else if (bright > whiteThresh) which = 7;
    else if (sat < 20) which = 8;
    else while(which == -1){
        if (cur <= colorDefs[index][1]) which = index;
        index++;
    }
    return which;
}
function printColorInfo(colorCounts) {
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
    print("========= Color Info =============");
    for(let i = 0; i < colorCounts.length; i++){
        let index = colorIndices[i];
        print(colorNames[index] + ": " + colorCounts[index] + " percent of image:" + colorCounts[index] / (width * height));
    }
    print("TARGET COLOR (more specific): Number of pixels with target color: " + targetCount + " percent of image:" + targetCount / (width * height));
    print("=================");
}
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
function keyPressed() {
    if (key == ' ') printColorInfo(colorCounts);
    else if (key == 'q') {
        colorThresh++;
        print("Color thresh is:" + colorThresh);
    } else if (key == 'a') {
        colorThresh--;
        print("Color thresh is:" + colorThresh);
    }
}

//# sourceMappingURL=index.ba7f5425.js.map
