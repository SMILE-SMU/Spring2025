//-----------------------------------------------------------------------------
// name: polyphonicSynthTEMPLATEwithNoteOffs.ck
// date: February 2025
// desc: all things for a polyphonic MIDI keyboard or device!!
//
// author: Courtney Brown 
//-----------------------------------------------------------------------------


public class Synth extends Chugraph //<-- CHANGE NAME (Synth) TO DESIRED SYNTH NAME
{
    //PUT IN YOUR SIGNAL FLOW HERE INSTEAD OF PLUCKED STRING -- you can also add init code here for the UGENs
    //TO MAKE IT FULLY REACTIVE TO NOTE-OFFs
    //IF SIGNAL IS NOT A STRING/TUBE MODEL, THEN MUST ALSO CHANGE SUSTAIN VALUE IN THE ENVELOPE FROM 0 to some value > 0 && > 1, eg. 0.25
    TriOsc noise => ADSR env(10::ms, 10::ms, 0.0, 100::ms) => DelayA string => OneZero lp => Dyno limiter => dac; 
    lp => Gain flip => string; 
    limiter.limit(); //limit the volume so it doesn't cause noise!
    -1 => flip.gain; //make string sound

        
    //we need these variables to implement note-offs, don't need to change anything.
    0 => float curFreq; //current playing frequency
    0 => int playing; //is the synth playing?
    
    //to make it polyphonic
    function void playNote(float freq, float vel, float sus)
    {
        
        //freq => sin.freq; //if using a sin or something that takes a frequency, you can set it here.
        
        //set the pitch
        second/samp => float SR; 
        SR/freq - 1 => float period;
        period::samp => string.delay;
        
        //inputs/parameters are 1) sustain in seconds
        //                      2) freq -- it is the frequency we've chosen
        sustain(sus, freq); //call the sustain function, delete if not a string/tube model
        
        freq => curFreq; //addition so that we can turn the note off, need to keep track of current frequency
        1 => playing; //note that we are now playing, important to be able to turn the note off
        
        vel => limiter.gain;
        
        //freq => sin.freq; //you'd have to change the frequency of any oscillators used here
        
        env.keyOn(); //start the sound!!    
    }
        
    //function -- named place in code
    //control sustain -- inputs 1) sec - how many seconds to sustain & 2) the frequency of the sound
    //this is for the physically-modeled string
    function void sustain(float sec, float freq)
    {
        Math.exp( -6.91/sec/freq ) => lp.gain;
    }
    
    function void off()
    {
        0 => playing;
        sustain(0.5, curFreq); //delete if not a string/tube model
        env.keyOff(); 
    }
    
    function float getFreq()
    {
        return curFreq;
    }
    
    function int isPlaying()
    {
        return playing;
    }
}

//creates a polyphonic synth!!
public class Synths extends Chugraph //<-- CHANGE NAME (Synths) TO DESIRED SYNTH NAME
{
    
    20 => int voiceNum;
    Synth synths[]; //<-- CHANGE NAME (Synths) TO REFLECT CURRENT CLASS NAME
    0 => int whichStringToPlay; 
    
    //constructor - default
    function Synths() //<-- CHANGE NAME (Synths) TO REFLECT CURRENT CLASS NAME
    {
        init();
    }
    
    //constructor - how many voices at once?
    function Synths(int voices) //<-- CHANGE NAME (Synths) TO REFLECT CURRENT CLASS NAME
    {
        voices => voiceNum; 
        init();
    }
    
    //init -- create all the voices
    function init()
    {
        new Synth[voiceNum] @=> synths; //<-- CHANGE NAME (Synth) TO REFLECT CURRENT CLASS NAME OF Synth class above
        for( 0 => int i; i < voiceNum; i++)
        {
            new Synth() @=> synths[i]; //<-- CHANGE NAME (Synth) TO REFLECT CURRENT CLASS NAME OF Synth class above
        }  
    }
    
    //spork a thread to play a note then iterate through our list
    function play(float freq, float velocity, float seconds)
    {
        if( freq < 20 || freq > 20000 )
        {
            <<<freq + " cannot be heard by humans!">>>;
            return; 
        }
        
        spork ~synths[whichStringToPlay].playNote(freq, velocity, seconds);
        whichStringToPlay++;
        if(whichStringToPlay >= synths.size())
        {
            0 => whichStringToPlay;
        }
    }
    
    //this will only work if sustain in envelope is set to non-zero OR you're doing a string/tube physically-based model
    function off(float freq)
    {
        for( 0 => int i; i < synths.size(); i++)
        {
            if( synths[i].isPlaying() == 1 && synths[i].getFreq() == freq )
            {
                synths[i].off();
            }
        }
        
    }
}