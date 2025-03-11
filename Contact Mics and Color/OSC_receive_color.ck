//-----------------------------------------------------------------------------
// name: OSC_receive_color.ck
// date: March 2025
// desc: Receives OSC from the p5ColorDetectionAndOSC project -- basically you can change the sound you create based on the color that you detect!!

/*

TO run the servers: 
Open 2 terminal or git-bash windows. You need to run servers. Yes you do!! Welcome to javascript & OSC !!
In one terminal: 
 Use cd ('change directory') to navigate to the correct folder directory
 eg. (the % is just noting the command-line, not something you would type in, and # is for comments so don't need to type that in)
 % cd ~/Downloads/Spring2025-main
 % cd "Contact Mics and Color"
 % cd p5ColorDetectionAndOSC
 % ls #note: this lists the directory & the # is a comment so won't run
 % pwd #gets the current file path where you are -- use this to copy & paste and then cd into the same place
 % node server.js #starts the server
 
 ===== 2nd terminal window!!  ===== 
 % cd "Users/yourname/Downloads/Spring2025-main/Contact Mics and Color/p5ColorDetectionAndOSC" #change the directory in one go, needs "" as 
       there are spaces -- in git-bash/Windows you may need to go through the whole cd process again as there were some problems with this
 % ls #lists the current directory, should be same as current directory of the 1st window
 % rm -r -rf node_modules # just in case, erase the old node_modules, particularly recommended for Windows or Linux systems -- only do this once on INSTALL
 % npm install # this gets all the other code you need from the internet & puts it in the right places, only do this ONCE for the install
 % npm run start # this starts the server!! so you'll want to do this to start always. Copy the url it gives you into your own browser. Color detection has started!!
 
 Once running from the browser, you can click to choose a target color & you can also press space bar to see all the color values at that current frame/moment
 It sends OSC values to the 9000 port referenced in this example patch
 
*/

//-----------------------------------------------------------------------------

// (launch with OSC_send.ck)

@import "SmoothedFloat.ck"

// the signal to create sound, very simple as this is an example
SinOsc sin => Dyno limiter => dac;
limiter.limit(); //I always limit just in case!!

// create our OSC receiver
OscIn oin;
// create our OSC message
OscMsg msg;
// use port 9000 as I am sending via javascript on port 9000, so we must receive there
9000 => oin.port;

//these are all the different submessages that we will be receiving, actual message will be /colorDetect/targetPercent, /colorDetect/red, etc.
["targetPercent", "red", "yellow", "green", "cyan", "blue", "magenta", "black", "white", "grey" ] @=> string colorNames[];
int messages[colorNames.size()];

//for loop to concatenate & create the OSC messages we're looking for and add all the messages to the OscIn
for( 0=>int i; i<colorNames.size(); i++ )
{
    "/colorDetect/"+ colorNames[i] => string msg1;
     i => messages[msg1];
     oin.addAddress(msg1 +", f");
     <<<msg1  +", f">>>; //print out the OSC message signature we're looking for
}

SmoothedFloat gain(0.0, 350); //this will be the gain to our sin wave, we want to change smoothly even though our color values will not... 


// infinite event loop
while ( true )
{
    // wait for event to arrive
    1::ms => now; //to change smoothly, we only move time forward a teensy bit at a time
    gain.update(); //update the gain so that it approaches the goal value, if its already there, it won't do anything
    gain.get() * 100 => sin.gain; 

    // grab the next OSC - Open Sound Control message from the queue. 
    while ( oin.recv(msg) != 0 )
    { 
       <<<msg.address + ": " + msg.getFloat(0) >>>; //print out the all messages on the console, so we can see them

        if( messages[msg.address] == 0 ) //if its the target percent -- i.e., the color we asked it to track
        {
            gain.set(msg.getFloat(0)); //we will set the gain 
        }
        else if( messages[msg.address] == 2 ) //if its yellow -- how much % of the screen is yellow now?
        {
            if ( msg.getFloat(0) > 0.024 ) 
            {
                Std.mtof( 60 ) => sin.freq; //if there's enough yellow, sine wave is middle C -- using MIDI numbers
            }
            else
            {
                Std.mtof( 59 ) => sin.freq; //otherwise, its the B below              
            }
        }
    }
}

