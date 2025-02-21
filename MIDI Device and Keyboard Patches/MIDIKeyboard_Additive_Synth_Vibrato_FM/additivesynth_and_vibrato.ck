//-----------------------------------------------------------------------------
// name: polyphonicSynthTEMPLATEwithNoteOffs.ck
// date: February 2025
// desc: all things for a polyphonic MIDI keyboard or device!!
//
// author:  Courtney Brown and Nha-Y Doung!
//-----------------------------------------------------------------------------


public class mySynth extends Chugraph //<-- CHANGE NAME (Synth) TO DESIRED SYNTH NAME
{
    //PUT IN YOUR SIGNAL FLOW HERE INSTEAD OF PLUCKED STRING -- you can also add init code here for the UGENs
    //TO MAKE IT FULLY REACTIVE TO NOTE-OFFs
    //IF SIGNAL IS NOT A STRING/TUBE MODEL, THEN MUST ALSO CHANGE SUSTAIN VALUE IN THE ENVELOPE FROM 0 to some value > 0 && > 1, eg. 0.25
    /*
    Noise noise => ADSR env(10::ms, 10::ms, 0.0, 10::ms) => DelayA string => OneZero lp => Dyno limiter => dac; 
    lp => Gain flip => string; 
    limiter.limit(); //limit the volume so it doesn't cause noise!
    -1 => flip.gain; //make string sound
    */
    
    SinOsc sin => ADSR env(50::ms, 160::ms, 0.4, 150::ms) => Dyno limiter => JCRev reverb => dac;
    SinOsc sin2 => ADSR env2(50::ms, 50::ms, 0.0, 20::ms) => limiter;
    SinOsc sin3 => ADSR env3(50::ms, 700::ms, 0.8, 200::ms) => limiter;
    TriOsc tri => ADSR env4(50::ms, 500::ms, 0.0, 500::ms) => limiter; 
    SqrOsc sqr => ADSR env5(50::ms, 400::ms, 0.2, 700::ms) => limiter;
    
    ADSR env_fm(10::ms, 59::ms, 0.4, 150::ms) => blackhole; //we used an envelope to determine how much vibrato or the fm tone we hear
    
    SinOsc vibrato => blackhole;
    5 => vibrato.freq; //the frequency of the vibrato. if we want to do fm synthesis we can just make it higher!! eg. 200 would be fm.

        
    //we need these variables to implement note-offs, don't need to change anything.
    0 => float curFreq; //current playing frequency
    0 => int playing; //is the synth playing?
    
    //to make it polyphonic
    function void playNote(float freq, float vel, float sus)
    {
  
        //Nha-Y's additive synthesis!!
        freq => sin.freq;
        freq+10 => sin2.freq;
        freq-20 => sin3.freq;
        freq*3=> tri.freq;
        freq-30=> sqr.freq;

        
        //sin.gain to show more prominent wave
        
        //freq => sin.freq; //if using a sin or something that takes a frequency, you can set it here.
        
        //set the pitch--for a string/tube model
        //second/samp => float SR; 
        //SR/freq - 1 => float period;
        //period::samp => string.delay;
        //freq => sin.freq; 
        
        //inputs/parameters are 1) sustain in seconds
        //                      2) freq -- it is the frequency we've chosen
        //sustain(sus, freq); //call the sustain function, delete if not a string/tube model
        freq => curFreq; //addition so that we can turn the note off, need to keep track of current frequency
        1 => playing; //note that we are now playing, important to be able to turn the note off
        
        vel => limiter.gain;
        
        //freq => sin.freq; //you'd have to change the frequency of any oscillators used here

        env.keyOn();
        env2.keyOn();
        env3.keyOn();
        env4.keyOn();
        env5.keyOn();
        
        //we added the vibrato here! it will stop when playing is zero (when we call off() --> taken care of by the template!)
        while( playing == 1 )
        {
            5.0 => float vibratoAmplitude; //how big a vibrato we want! -- or how loud we want the fm frequency bands to sound!
            // below we create the vibrato for each sine wave, triangle wave, or square wave we've added together :) 
            freq + vibrato.last()*(env_fm.last()*vibratoAmplitude) => sin.freq; 
            freq + vibrato.last()*(env_fm.last()*vibratoAmplitude) => sin2.freq; 
            freq + vibrato.last()*(env_fm.last()*vibratoAmplitude) => sin3.freq; 
            freq + vibrato.last()*(env_fm.last()*vibratoAmplitude) => tri.freq; 
            freq + vibrato.last()*(env_fm.last()*vibratoAmplitude) => sqr.freq; 
            
            //TODO: AM synthesis :) professor will show sometime next week!!
            
            1::ms => now;
        }
        
    } 
    function void off()
    {
        0 => playing;
        //sustain(0.5, curFreq); //delete if not a string/tube model

        env.keyOff();
        env2.keyOff();
        env3.keyOff();
        env4.keyOff();
        env5.keyOff();
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
public class mySynths extends Chugraph //<-- CHANGE NAME (Synths) TO DESIRED SYNTH NAME
{
    
    20 => int voiceNum;
    mySynth synths[]; //<-- CHANGE NAME (Synths) TO REFLECT CURRENT CLASS NAME
    0 => int whichStringToPlay; 
    
    //constructor - default
    function mySynths() //<-- CHANGE NAME (Synths) TO REFLECT CURRENT CLASS NAME
    {
        init();
    }
    
    //constructor - how many voices at once?
    function mySynths(int voices) //<-- CHANGE NAME (Synths) TO REFLECT CURRENT CLASS NAME
    {
        voices => voiceNum; 
        init();
    }
    
    //init -- create all the voices
    function init()
    {
        new mySynth[voiceNum] @=> synths; //<-- CHANGE NAME (Synth) TO REFLECT CURRENT CLASS NAME OF Synth class above
        for( 0 => int i; i < voiceNum; i++)
        {
            new mySynth() @=> synths[i]; //<-- CHANGE NAME (Synth) TO REFLECT CURRENT CLASS NAME OF Synth class above
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