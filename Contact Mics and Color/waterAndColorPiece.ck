/** 
    Coder: Courtney Brown
    Date: Mar. 12, 2025
    Desc: A piece for contact microphones and color detection. See OSC_receive_color.ck for usage and how to install/start js servers for color detection

    One task would be refactor to use loops and arrays to get rid of some of this code repetition

    **This cannot be run in webChuck because it uses OSC.
        
    The piece plays random notes and sequences in C harmonic minor in response to contact mic input (or any mic input)
    Interactivity:
        Keypress:
            '1' - turns on the echo on the bandpass filters of the microphone input
            '2' - turns off the echo on the bandpass filters of the microphone input
        Color detection via Camera on Web:
            % Target color (chosen interactively) -- controls gain of ongoing sin waves additive synthesis
            % of magenta -- controls the octave of the sine wave sounds (threshholded)
            % of black -- controls the octave of reson filters on the mic input (threshholded)
            
**/

@import "Follower.ck"
@import "SmoothedFloat.ck"

//Initial signal path for subtractive synthesis, we added an Echo to add an effect as requested
adc => ResonZ reson1 => Echo echo1 => Dyno limiter => dac; 
adc => ResonZ reson2 => Echo echo2 => limiter; 
adc => ResonZ reson3 => Echo echo3 => limiter; 
adc => ResonZ reson4 => Echo echo4 => limiter; 
adc => ResonZ reson5 => Echo echo5 => limiter; 
[reson1, reson2, reson3, reson4, reson5] @=> ResonZ resons[];
[echo1, echo2, echo3, echo4, echo5] @=> Echo echos[];
limiter.limit();
//turnOffReson();

//adc follower -- can use audio in to change other parameters
Follower follower => blackhole; 
SinOsc sin1 => ADSR sinEnv(450::ms, 50::ms, 0, 500::ms) => Echo echoSin => JCRev reverb => limiter; 
SinOsc sin2 => echoSin => sinEnv => reverb; 
SinOsc sin3 => sinEnv => reverb; 
SinOsc tri4 => sinEnv => reverb; 
SinOsc tri5 => sinEnv => reverb;
[sin1, sin2, sin3, tri4, tri5] @=> Osc oscillators[];
SmoothedFloat sinGain(0.0, 250);
0.5 => reverb.mix;

//set the delay times
125::ms => echo1.delay; 
250::ms => echo2.delay; 
500::ms => echo3.delay;
50::ms => echo4.delay;
100::ms => echo5.delay;

//set the width all the bandpass filters
20 => reson1.Q; 
20 => reson2.Q; 
20 => reson3.Q; 
20 => reson4.Q; 
20 => reson5.Q; 

//random notes in C minor 
[60, 62, 63, 65, 67, 68, 71, 72, 74,
72, 74, 75, 77, 79, 80, 83, 84, 86, 87,
48, 50, 51, 53, 55, 56, 59, 60] @=> int section1[];

//specific shiz in C minor
[
[60, 68, 67], 
[68, 71, 72], 
[60, 62, 63], 
[60, 58, 56, 55, 53], 
[67-12, 71-12, 74-12, 76-12, 7-74], 
[67, 63, 62, 59, 60, 62], 
[55, 56, 57, 59, 71] 
] @=> int section2[][];


//all the motives in one 2D array
//[ section1, section2, section1 ] @=> int melodies[][];
section1 @=> int midiNotes[]; //first thing to play

0 => int sectionIndex; //which section?
0 => int melodyIndex; //the index into the 2D array of melodies of section 2

//an array of possible rhythms -- there is more 250::ms so when we choose randomly we'll get more
[250::ms, 500::ms, 750::ms, 250::ms, 250::ms, 250::ms, 1000::ms] @=> dur rhythms[]; 

250::ms => dur noteLength; //how long a note will play (ie, a pitch will filter -- as the incoming audio will really affect rhythm)
now => time lastChecked; 
0 => int index;
1000::ms => dur sinNoteLength; 
now => time lastCheckedSin;

// HID input and HID message
Hid hi;
HidMsg msg;

// which keyboard
0 => int device;

// open keyboard (get device number from command line)
if( !hi.openKeyboard( device ) ) me.exit();
<<< "keyboard '" + hi.name() + "' ready", "" >>>;

// create our OSC receiver
OscIn oin;
// create our OSC message
OscMsg osc_msg;
// use port 9000 as I am sending via javascript on port 9000, so we must receive there
9000 => oin.port;
["targetPercent", "red", "yellow", "green", "cyan", "blue", "magenta", "black", "white", "grey" ] @=> string colorNames[];
//these are all the different submessages that we will be receiving, actual message will be /colorDetect/targetPercent, /colorDetect/red, etc.
int messages[colorNames.size()]; //this is our index into the above array so that we can test for string equality of the OSC messages, 
//it is weird but this is how you check for string equality in max
setupOSCMessages(); //setup all the OSC messages for receiving

1 => int pitchOctaveDropSin; //how much to drop (negative numbers go up), 0 doesn't do anything
0 => int pitchOctaveDropResons; //how much to drop (negative numbers go up), 0 doesn't do anything


SmoothedFloat freq(Std.mtof(60), 10000);
Std.mtof(60) => float sinFreq;
//================================================================================
// END INIT CODE AND START EVENT LOOP
//================================================================================
while( true ) //go FOREVER
{
    1::ms => now; //check a millisecond to now -- make time pass
    freq.update(); 
    updateFilters(freq);
    updateOscillators(sinFreq, sinGain);
    respondToOsc();
    respondToKeypress();
    updateSins();
    
    //checks to see if a noteLength of time has passed since we last checked the time
    //if so, then we will change the center frequencies of the bandpass filter
    if( now - lastChecked >= noteLength )
    {
        now => lastChecked; //we just checked! so set lastChecked to now
        
        //turn on env

        //set the filter frequency to the current note in the melodic motive
        //also, set the other bandpass center frequencies to harmonic series of 1st freq.
        freq.set(Std.mtof( midiNotes[index]-12*pitchOctaveDropResons ));         

        Math.random2(0, rhythms.size()-1) => int rhyIndex; 
        rhythms[rhyIndex] => noteLength;
 
        if( sectionIndex == 1 )
        { 
            index + 1 => index ;  //incrementing the note index in the melody
        }
        else
        {
            Math.random2(0, section1.size()-1) => index; 
            section1 @=> midiNotes;
        }
        
        //if we're at the end of the current melody, chose the next one -- randomly!
        if( index >= midiNotes.size() && sectionIndex == 1 )
        {
            0 => index; 

            //change melodies
            Math.random2(0, section2.size()-1) => melodyIndex;
            section2[melodyIndex] @=> midiNotes;
        }
    } 
}
//================================================================================
// End EVENT LOOP, user-defined functions below
//================================================================================
function updateSins()
{
    //checks to see if a noteLength of time has passed since we last checked the time for the sinOsc
    //if so, then we will change the center frequencies of the bandpass filter
    if( now - lastCheckedSin >= sinNoteLength )
    {
        sinEnv.keyOff();
        sinEnv.keyOn();
        
        Math.random2(0, section1.size()-1) => int sinIndex; 
        Std.mtof( section1[sinIndex]-12*pitchOctaveDropSin ) => sinFreq;
        
        now => lastCheckedSin;
    }    
   
}
//================================================================================
function respondToKeypress()
{
    // get message for keyboard
    while( hi.recv( msg ) )
    {
        // check
        if( msg.isButtonDown() )
        {
            <<<"Pressed key: " + msg.which>>>;
            if( msg.which == 44 ) //space bar to change 
            {
                changeSection();
            }
            else if( msg.which == 30 ) //'1' key adds echo
            {
                signalWithEcho();
            }
            else if( msg.which == 31 ) //'2' key removes echo
            {
                signalWithOutEcho();
            }
        }        
    }  
}
//================================================================================
function respondToOsc()
{
    // grab the next OSC - Open Sound Control message from the queue when there is a message
    while ( oin.recv(osc_msg) != 0 )
    { 
        //<<<msg.address + ": " + msg.getFloat(0) >>>; //uncomment to print out the all messages on the console, so we can see them
        //referencing this array:
        // ["targetPercent", "red", "yellow", "green", "cyan", "blue", "magenta", "black", "white", "grey" ] @=> string colorNames[];
        <<<osc_msg.address>>>;

        
        if( messages[osc_msg.address] == 0 ) //if its the target percent -- i.e., the color we asked it to track
        {
            //sinGain.set(osc_msg.getFloat(0)*10*follower.last()); //we will set the gain to be determined by the amt. of target color shown on the video camera screen.
            sinGain.set(osc_msg.getFloat(0)); //we will set the gain to be determined by the amt. of target color shown on the video camera screen.
            <<<osc_msg.getFloat(0)>>>;
        }
        else if( messages[osc_msg.address] == 2 ) //if its yellow -- how much % of the screen is yellow now?
        {
            //TODO -- create different things for different colors!!
            
            if ( osc_msg.getFloat(0) > 0.024 ) 
            {
                1 => sectionIndex;
            }
            else
            {
                0 => sectionIndex;
            }
            
        }
        else if( messages[osc_msg.address] == 6 ) //if its magenta -- how much % of the screen is yellow now?
        {
            //TODO -- create different things for different colors!!
            
            if ( osc_msg.getFloat(0) > 0.08 ) 
            {
                0 => pitchOctaveDropSin;
            }
            else if ( osc_msg.getFloat(0) > 0.035 ) 
            {
                1 => pitchOctaveDropSin;
            } 
            else
            {
                2 => pitchOctaveDropSin;
            }
            
            
        }
        else if( messages[osc_msg.address] == 7 ) //if its black -- how much % of the screen is black now?
        {
            //TODO -- create different things for different colors!!
            if ( osc_msg.getFloat(0) > 0.075 ) 
            {
                2 => pitchOctaveDropResons;
                <<<"here">>>;
            }
            else if ( osc_msg.getFloat(0) > 0.05 ) 
            {
                1 => pitchOctaveDropResons;
            }
            else
            {
                0 => pitchOctaveDropResons;
            }
        }
    } 
}
//================================================================================
//changes the section
function changeSection()
{
    if(sectionIndex == 0)
    {
        1 => sectionIndex;
    }
    else 
    {
        0 => sectionIndex;
    }
}
//================================================================================
//add back the echo
function signalWithEcho()
{
    for( 0 => int i; i<resons.size(); i++ )
    {
        resons[i] =< limiter; //disconnect resons from limiter
        echos[i] => limiter; //connect echos to limiter
    }
}
//================================================================================
//remove the echo
function signalWithOutEcho()
{
    for( 0 => int i; i<echos.size(); i++ )
    {
        echos[i] =< limiter; //disconnect echos from limiter
        resons[i] => limiter; //connect resons to limiter
    }
}
//================================================================================
//update the oscillator gain
function updateOscillatorGain(SmoothedFloat g)
{
    g.update();
    for( 0 => int i; i< oscillators.size(); i++ )
    {
        g.get() / (i+1) => oscillators[i].gain; 
    }
}
//================================================================================
//update freq and gain of all the oscillators
function updateOscillators(float freq, SmoothedFloat g)
{
    //sin waves
    updateOscillatorGain(g);
    for( 0 => int i; i< oscillators.size(); i++ )
    {
        freq * (i+1) => oscillators[i].freq; 
    }        
}
//================================================================================
//update all the filters
function updateFilters(SmoothedFloat freq)
{
    //set subtractive synth filters
    freq.get() => reson1.freq; 
    freq.get() * 2 => reson2.freq; 
    freq.get() * 3  => reson3.freq; 
    freq.get() * 4  => reson4.freq; 
    freq.get() * 5  => reson5.freq;     
}
//================================================================================
//setup all the OSC messages that we will receive
function setupOSCMessages()
{    
    //for loop to concatenate & create the OSC messages we're looking for and add all the messages to the OscIn
    for( 0=>int i; i<colorNames.size(); i++ )
    {
        "/colorDetect/"+ colorNames[i] => string msg1; //create the OSC message from the array
        i => messages[msg1]; //create the index in our messages array
        oin.addAddress(msg1 +", f"); //add the OSC address signature to our OSC listener object (OscIn oin)
        <<<msg1  +", f">>>; //print out the OSC message signature we're looking for -- just to check
    }   
}
//================================================================================
//for debugging, turn down all the resons
function turnOffReson()
{
    for( 0 => int i; i<resons.size(); i++ )
    {
        0 => resons[i].gain;
        0 => echos[i].gain;
    }    
}
//================================================================================

