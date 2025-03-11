//-----------------------------------------------------------------------------
// name: OSC_receive_color.ck
// date: March 2025
// desc: Receives OSC from the p5ColorDetectionAndOSC project
//-----------------------------------------------------------------------------

// (launch with OSC_send.ck)

@import "SmoothedFloat.ck"

// the patch
SinOsc sin => Dyno limiter => dac;
limiter.limit();

// create our OSC receiver
OscIn oin;
// create our OSC message
OscMsg msg;
// use port 6449
9000 => oin.port;
// create an address in the receiver


//these are all the different submessages that we will be receiving, actual message will be /colorDetect/targetPercent, /colorDetect/red, etc.
["targetPercent", "red", "yellow", "green", "cyan", "blue", "magenta", "black", "white", "grey" ] @=> string colorNames[];
int messages[colorNames.size()];

//for loop to concatenate & create the OSC messages we're looking for and add all the messages to the OscIn
for( 0=>int i; i<colorNames.size(); i++ )
{
    "/colorDetect/"+ colorNames[i] => string msg1;
     i => messages[msg1];
     oin.addAddress(msg1 +", f");
     <<<msg1  +", f">>>;
}

SmoothedFloat gain(0.0, 350);


// infinite event loop
while ( true )
{
    // wait for event to arrive
    1::ms => now;
    gain.update();
    gain.get() * 100 => sin.gain; 

    // grab the next message from the queue. 
    while ( oin.recv(msg) != 0 )
    { 
        if( messages[msg.address] == 0 ) //if its the target percent
        {
            <<<msg.address + ": " + msg.getFloat(0) >>>;
            gain.set(msg.getFloat(0));
        }
    }
}

