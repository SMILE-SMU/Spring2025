//-----------------------------------------------------------------------------
// name: monophonicKeyboard.ck
// date: January 2025
// desc: A monophobic keyboard! Uses the laptop keyboard template
//
// author: Courtney Brown 
//-----------------------------------------------------------------------------

@import "openMidiDevice.ck";

//open all the devices 
MidiDevice midi; 
midi.open(); 

//get the correct MidiIn device
1 => int device; 
midi.getDevice(device) @=> MidiIn midiIn; 

//This sets up our signal. This will be playing anytime we 'chuck' time to now
//The Dyno limiter is a generator that limits the volume of our outcome to that 
//it doesn't go louder than what is possible, preventing clipping -- undesirable noise
SinOsc sin => ADSR env(10::ms, 10::ms, 0.25, 100::ms) => Dyno limiter => dac; 
limiter.limit(); //limit the volume so it doesn't cause noise!


MidiMsg msg; //MIDI messages


while(true) //OMG! This never stops!! Until you remove the shred. We want it always running, though.
{
    if( midiIn.recv( msg ) ) //did we receive a message from the mouse?
    {
        <<<msg.data1, msg.data2, msg.data3>>>;
        if( msg.data1 == 144 )
        {
            <<<"noteOn">>>;
            Std.mtof(msg.data2) => float freq;
            freq =>  sin.freq;
            <<<freq>>>;
            10 * msg.data3/127 => limiter.gain; //change the velocity
            env.keyOn(); //start the sound!!
        }
        else if( msg.data1 == 128 )
        {
            <<<"noteOff">>>;
            env.keyOff(); //stop the sound!!

        }
    }
    1::ms => now; //make time pass!!
}


