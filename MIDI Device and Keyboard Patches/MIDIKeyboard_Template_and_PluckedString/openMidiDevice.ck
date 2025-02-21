//-----------------------------------------------------------------------------
// name: openMidiDevice.ck
// class: MidiDevice -- just does a few things for MIDI in.
// date: February 2025
//
// author: Courtney Brown 
//-----------------------------------------------------------------------------


// device, and contents of the MIDI message

// devices to open (try: chuck --probe)
public class MidiDevice{

    MidiIn min[16];

    // number of devices
    int devices;

    function void open()
    {
        // loop
        for( int i; i < min.size(); i++ )
        {
            // no print err
            min[i].printerr( 0 );
        
            // open the device
            if( min[i].open( i ) )
            {
                <<< "device", i, "->", min[i].name(), "->", "open: SUCCESS" >>>;
                devices++;
            }
            else break;
        }
    
        // check
        if( devices == 0 )
        {
            <<< "um, couldn't open a single MIDI device, bailing out..." >>>;
            me.exit();
        }
    }
    
    function testDevice( MidiIn min, int id )
    {        
        // the message
        MidiMsg msg;
        
        // infinite event loop
        while( true )
        {
            // wait on event
            min => now;
            
            // print message
            while( min.recv( msg ) )
            {
                // print out midi message with id
                <<< "device", id, ":", msg.data1, msg.data2, msg.data3 >>>;
            }
         }
        
    }

    function MidiIn getDevice(int device)
    {
    
        return min[device];
    }
    
}
