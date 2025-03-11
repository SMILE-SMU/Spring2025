//Import express
let express = require('express');
let OSC = require('osc-js');
var cors = require('cors');
var colorNames = ["red", "yellow", "green", "cyan", "blue", "magenta", "black", "white", "grey" ];


// Create the Express app
let app = express();
app.use( cors() );

let fs = require('fs');

// Set the port used for server traffic.    
let port = 3001;
// Middleware to serve static files from 'public' directory
app.use(express.static('public'));


//Run server at port
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});

const config = { 
    // Adjust these to match your receiving application's settings
    send: { 
        host: '127.0.0.1', 
        port: 9001 
    }
}

//const config = { udpServer: { port: 3334 } };
let osc;
function oscForMax()
{
  const options = {
    open: {
      port: 9988
    }
  };
  osc = new OSC({ plugin: new OSC.DatagramPlugin(options) });
  osc.open();
}
oscForMax(); 
//osc?.send( new OSC.Message( "/testMessage"), { port: 9000 } ); 

app.get('/colorDetect/targetPercent', (req, res) => {
    let target = req.query.targetPercent;
    //let message = new OSC.Message('/colorDetect/targetPercent', target);
    osc?.send( new OSC.Message( "/colorDetect/targetPercent", parseFloat(req.query.targetPercent)), { port: 9000 } ); 

    let colors = []; 
    for(let i=0; i<colorNames.length; i++)
    {
        let query = "req.query." + colorNames[i];
        colors.push(eval(query));
        let msg = "/colorDetect/" + colorNames[i];
        console.log(query + " " + colors[i]); 
        console.log(msg);
        //osc?.send( new OSC.Message( msg,  parseFloat(colors[i])), { port: 9000 } ); 
    }


    console.log("sent: "+target );

    res.send('Color sent to OSC');
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