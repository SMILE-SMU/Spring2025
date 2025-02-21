//-----------------------------------------------------------------------------
// name: MIDI_keyboard_example_polyphonic.ck
// date: January 2025
// desc: all things for a polyphonic MIDI keyboard or device!!
//
// author: Courtney Brown 
//-----------------------------------------------------------------------------


@import "openMidiDevice.ck"
@import "polyphonicSynthPluckedString.ck"

//polyphonic MIDI keyboard!!
MidiDevice midi;

midi.open(); 

//this creates the polyphonic synths that will be our synth voices
PluckedStrings strings; 

//A message from your MIDI keyboard
MidiMsg msg;

// Ok now modify to select the correct midi device
1 => int device;
midi.getDevice(device) @=> MidiIn midDevice;

while(true) //OMG! This never stops!! Until you remove the shred. We want it always running, though.
{
    if( midDevice.recv( msg ) ) //did we receive a message from the mouse?
    {
        <<< "device", device, ":", msg.data1, msg.data2, msg.data3 >>>;

        //works for on and off messages
        Std.mtof(msg.data2 + 36) => float freq; //frequency

        if( msg.data1 == 144 ) //note on!
        {
            <<< "device", device, ":", msg.data1, msg.data2, msg.data3 >>>;
            (10 * msg.data3 / 127.0) => float vel; //velocity - gain/volume
            strings.play(freq, vel, 20);
        }
        else if( msg.data1 == 128 )
        {
            strings.off(freq);
        }
    }
    1::ms => now; //make time pass!!
}

