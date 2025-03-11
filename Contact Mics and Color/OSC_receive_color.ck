// (launch with OSC_send.ck)

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



["targetPercent", "red", "yellow", "green", "cyan", "blue", "magenta", "black", "white", "grey" ] @=> string colorNames[];
int messages[colorNames.size()];

for( 0=>int i; i<colorNames.size(); i++ )
{
    "/colorDetect/"+ colorNames[i] => string msg1;
     i => messages[msg1];
     oin.addAddress(msg1 +", f");
     <<<msg1>>>;
}


// infinite event loop
while ( true )
{
    // wait for event to arrive
    oin => now;

    // grab the next message from the queue. 
    while ( oin.recv(msg) != 0 )
    { 
        if( messages[msg.address] == 0 ) //if its the target percent
        {
            <<<msg.address + ": " + msg.getFloat(0) >>>;
            msg.getFloat(0) * 100 => sin.gain;
            
        }
    }
}
