//-----------------------------------------------------------------------------
// name: server.js
// date: March 2025
// desc: Javascript server that 1) receives messages from the browser so that it can 2) send OSC messages to a _local_ port
// usage: node server.js
// This must be run LOCALLY to work! As we're sending OSC messages to a local port so the we can use different software
//-----------------------------------------------------------------------------


//Import express, OSC, and CORS libraries
let express = require('express');
let OSC = require('osc-js');
var cors = require('cors');

//List of color messages to send via osc -- matches colorNames in Chuck and the browser javascript file
var colorNames = ["red", "yellow", "green", "cyan", "blue", "magenta", "black", "white", "grey" ];


// Create the Express app
let app = express();
app.use( cors() ); // Enable CORS for all routes -- that means that I can send messages from the browser to this server LOCALLY

let fs = require('fs'); //don't really need this, it was in the template code, tag for deletion... 

// Set the port used for _server_ traffic -- this is the port that the browser code will send messages to    
let port = 3001;
// Middleware to serve static files from 'public' directory
app.use(express.static('public')); //this is the directory that the browser code will be served from -- um not so much using, tag for deletion.


//Run server at port
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});

//config for sennding OSC
// const config = { 
//     // Adjust these to match your receiving application's settings
//     send: { 
//         host: '127.0.0.1', //server IP address -- in this case the local machine, localhost -- that IP address is always the localhost
//         port: 9000 //set the port to send OSC messages to -- this is the port that the receiving application is listening on
//     }
// }

//setup our OSC object
let osc;
function setupOSC()
{
  const options = {
    open: {
      port: 9000
    }
  };
  osc = new OSC({ plugin: new OSC.DatagramPlugin(options) });
  osc.open();
}
setupOSC(); //call the function to setup the OSC object
//osc?.send( new OSC.Message( "/testMessage"), { port: 9000 } ); //send a test message

//receives the messages from the broswer and sends them to the OSC object
app.get('/colorDetect/targetPercent', (req, res) => {
    let target = req.query.targetPercent; //get the target percent from the query string
    osc?.send( new OSC.Message( "/colorDetect/targetPercent", parseFloat(req.query.targetPercent)), { port: 9000 } ); //send the target percent via the OSC object

    //basically, this is a loop that goes through all the color names and sends the color values to the OSC object
    //its a fast way to send all 9 colors
    let colors = []; 
    for(let i=0; i<colorNames.length; i++)
    {
        let query = "req.query." + colorNames[i];
        colors.push(eval(query));
        let msg = "/colorDetect/" + colorNames[i];
        osc?.send( new OSC.Message( msg,  parseFloat(colors[i])), { port: 9000 } ); 
    }

    console.log("sent: "+target ); //just log we sent something to the console
    res.send('Color sent to OSC'); //send a response back to the browser -- its ok! 200 OK!
});


app.get('/colorDetect', (req, res) => {
    let target = req.query.targetPercent;
    //let message = new OSC.Message('/colorDetect/targetPercent', target);
    osc?.send( new OSC.Message( "/colorDetect/targetPercent", parseFloat(req.query.targetPercent)), { port: 9000 } ); 

    let colors = []; 
    for(let i=0; i<colorNames.length; i++)
    {
        let query = "req.query." + colorNames[i];
        colors.push(eval(query));
        let msg = "/colorDetect/" + colorNames[i];
        //console.log(query + " " + colors[i]); 
        //console.log(msg);
        osc?.send( new OSC.Message( msg,  parseFloat(colors[i])), { port: 9000 } ); 
    }

    //console.log("sent: "+target );
    res.send('Color sent to OSC');
});