//-----------------------------------------------------------------------------
// name: polyphonicSynthPluckedString.ck
// classes: 1 - PluckedString -- a plucked string class 
//          2 - PluckedStrings -- uses a PluckedString per voice to create polyphonic (many notes playing at once) sound
// date: January 2025
// desc: polyphonic keyboard plucked string string
//
// author: Courtney Brown 
//-----------------------------------------------------------------------------


public class PluckedString
{
    //PUT IN YOUR SIGNAL FLOW HERE
    Noise noise => ADSR env(20::ms, 10::ms, 0.0, 10::ms) => DelayA string => OneZero lp => Dyno limiter => dac; 
    lp => Gain flip => string; 
    limiter.limit(); //limit the volume so it doesn't cause noise!
    -1 => flip.gain; //make string sound
    
    0 => float curFreq; //current playing frequency
    0 => int playing;
    
    //to make it polyphonic
    function void playNote(float freq, float velocity, float sus)
    {
        (velocity / 127.0) => float vol; 
        vol => limiter.gain;
        
        //set the pitch
        second/samp => float SR; 
        SR/freq - 1 => float period;
        period::samp => string.delay;
        freq => curFreq; 
        1 => playing;
        
        //inputs/parameters are 1) sustain in seconds
        //                      2) freq -- it is the frequency we've chosen
        sustain(sus, freq); //call the sustain function
        
        env.keyOn(); //start the sound!!    
    }
        
    //function -- named place in code
    //control sustain
    function void sustain(float sec, float freq)
    {
        Math.exp( -6.91/sec/freq ) => lp.gain;
    }
    
    function void off()
    {
        0 => playing;
        sustain(0.5, curFreq);
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
public class PluckedStrings extends Chugraph
{
    
    20 => int voiceNum;
    PluckedString strings[];
    0 => int whichStringToPlay; 
    
    //constructor - default
    function PluckedStrings()
    {
        init();
    }
    
    //constructor - how many voices at once?
    function PluckedStrings(int voices)
    {
        voices => voiceNum; 
        init();
    }
    
    //init -- create all the voices
    function init()
    {
        new PluckedString[voiceNum] @=> strings;
        for( 0 => int i; i < voiceNum; i++)
        {
            new PluckedString() @=> strings[i];
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
        
        spork ~strings[whichStringToPlay].playNote(freq, velocity, seconds);
        whichStringToPlay++;
        if(whichStringToPlay >= strings.size())
        {
            0 => whichStringToPlay;
        }
    }
    
    //this will only work if sustain in envelope is set to non-zero
    function off(float freq)
    {
        for( 0 => int i; i < strings.size(); i++)
        {
            if( strings[i].isPlaying() == 1 && strings[i].getFreq() == freq )
            {
                strings[i].off();
            }
         }

    }
}