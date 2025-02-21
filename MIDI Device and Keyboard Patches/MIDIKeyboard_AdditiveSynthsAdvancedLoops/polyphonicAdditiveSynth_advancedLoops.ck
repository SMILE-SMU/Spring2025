//-----------------------------------------------------------------------------
// name: polyphonicSynthPluckedString.ck
// classes: 1 - PluckedString -- a plucked string class 
//          2 - PluckedaddSynths -- uses a PluckedString per voice to create polyphonic (many notes playing at once) sound
// date: January 2025
// desc: polyphonic keyboard plucked string string
//
// author: Courtney Brown 
//-----------------------------------------------------------------------------

public class AdditiveSynth
{
    /*
    // Signal flow with added features
    Noise noise => ADSR env(10::ms, 20::ms, 0.0, 50::ms) => DelayA string => OneZero lp => Dyno limiter => dac;
    Noise noise2 => ADSR env2(10::ms, 20::ms, 0.0, 50::ms) => DelayA string2 => OneZero lp2 => limiter;
    
    //limiter => DelayA string2 => Gain pan => dac;  // string2 line is added for a stereo effect
    lp => Gain flip => string;
    lp2 => Gain flip2 => string2;
    
    limiter.limit();
    -1 => flip.gain;
    */
    
/***** PREVIOUS WAY

    //define all our signal chains
    SinOsc sin => ADSR env(200::ms, 100::ms, 0.25, 500::ms) => Dyno limiter => dac;
    SinOsc sin2 => ADSR env2(200::ms, 100::ms, 0.25, 500::ms) => limiter;
    SinOsc sin3 => ADSR env3(200::ms, 100::ms, 0.25, 500::ms) => limiter;
    SinOsc sin4 => ADSR env4(200::ms, 100::ms, 0.25, 500::ms) => limiter; 
    
    //put our objects into arrays (ie, lists)

    [ sin, sin2, sin3, sin4 ] @=> SinOsc sinList[]; //an array of our SinOsc objects
    [ env, env2, env3, env4 ] @=> ADSR envList[]; //an array of our Envelope objects
    
 END PREVIOUS WAY *****/
    
/***** NEW WAY!!! MORE FLEXIBLE ****/  
    Dyno limiter => dac; //we will only have one of these

    //now I will define how many of each SinOsc and ADSR envelopes I want
    //change below number to change the number of sine waves added together
    20 => int numberOfSinOsc; //NOTE: there will be a limitation with your CPU with this 
                              //you can increase THIS number if you DECREASE the number voices in your
                              //polyphonic synth (this is shown in the example in the other file)
                              //So, I was able to get to 80 sin waves with 8 voices -- see example
                              //I was able to get 40 sin waves with 20 voices, but not 50
                              //I have a brand-new Macbook M3, though
                              //so, your mileage MAY vary :) 
                              
    //but you will need to turn the gain down on each once you get to truly high numbers because it
    //will clip --exceed the computer's capacity to store the large number and cause horrendous noise
    
    //I now use this number to define a list of a particular size
    SinOsc sinList[numberOfSinOsc];  
    ADSR envList[numberOfSinOsc];

    //now I will use a for-loop to create everything
    //the .size() call at the end of the list tells me the size of my array (ie, list) 
    for( 0 => int i; i<sinList.size(); i++ )  
    {
        new SinOsc() => sinList[i]; //create a SinOsc
        
        new ADSR(200::ms, 50::ms, 0.25, 500::ms) => sinList[i]; //create a ADSR envelope
        
        //connect the signals together into one limiter
        sinList[i] => envList[i] => limiter; 
    }

/***** NEW WAY DEFINITION END!!! SEE the rest of class ****/  
    
    0 => float curFreq;
    0 => int playing;
    
    //SinOsc vibrato => blackhole;  // vibrato to add subtle pitch 
    //5.0 => vibrato.freq;  // speed
    
    function void playNote(float freq, float velocity, float sus)
    {
        (velocity / 127.0) => float vol;
        vol => limiter.gain;
        
        /*
        // Set pitch
        second/samp => float SR;
        SR/freq - 1 => float period;
        period::samp => string.delay;
        (period * 1.02)::samp => string2.delay; // Slightly detune second delay
        
        */
        
        //create the harmonic series with for-loop and lists --> NEW WAY, add the size()
        for( 0=>int i; i<sinList.size(); i++)
        {
            (i+1)*freq => sinList[i].freq; //same code as before, harmonic series
                        
            //uncomment to try these things instead (one at a time):
            //(i*2+1)*freq => sinList[i].freq; //odd harmonic series
            //(i*2)*freq => sinList[i].freq; //even harmonic series (the 1st freq/fundamental will be silent)
            //(i*3)+freq => sinList[i].freq; //a cluster with beating tones starting @ freq
            //(i*25)+freq => sinList[i].freq; //a cluster with dissonant tones starting @ freq

            //we can also have different gains for each SinOsc!!
            //one at a time!!
            //1/(1+i) => sinList[i].gain; //exponentially decaying volume for every freq after the 1st (you mostly hear the 1st one)
            //(1-i/sinList.size()) => sinList[i].gain; //linear decreasing gain
            //0.05 => sinList[i].gain; //all the same gain -- if a lot, need this & can make smaller if needed
            //Math.sin(i*Math.pi/sinList.size()) => sinList[i].gain; //gains like a sin wave!!
            
        }
        
        
        freq => curFreq;
        1 => playing;
        
        //sustain(sus, freq);
        
        //turn ON all the envelopes  -- NEW WAY -- adds the size
        for( 0 => int i; i<envList.size(); i++ )
        {
            envList[i].keyOn();
        }
        
        //spork ~applyVibrato(freq);
    }
    
    /*
    function void sustain(float sec, float freq)
    {
        Math.exp(-6.91 / sec / freq) => lp.gain;
        Math.exp(-5.5 / sec / freq) => lp2.gain;  // Slightly different damping for richer texture
    }
    
    function void applyVibrato(float freq)
    {
        while (playing)
        {
            (freq + (vibrato.last() * 0.1)) => curFreq;  // Small vibrato effect
            10::ms => now;
        }
    }
    */
    
    function void off()
    {
        0 => playing;
        //sustain(0.5, curFreq);
        
        //turn OFF all the envelopes -- NEW WAY -- adds the size
        for( 0 => int i; i<envList.size(); i++ )
        {
            envList[i].keyOff();
        }
        
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

// Creates a polyphonic synth with enhancements
public class AdditiveSynths extends Chugraph
{
    20 => int voiceNum;
    AdditiveSynth addSynths[];
    0 => int whichSynthToPlay;
    
    function AdditiveSynths()
    {
        init();
    }
    
    function AdditiveSynths(int voices)
    {
        voices => voiceNum;
        init();
    }
    
    function init()
    {
        new AdditiveSynth[voiceNum] @=> addSynths;
        for (0 => int i; i < voiceNum; i++)
        {
            new AdditiveSynth() @=> addSynths[i];
        }
    }
    
    function play(float freq, float velocity, float seconds)
    {
        if (freq < 20 || freq > 20000)
        {
            <<< freq + " cannot be heard by humans!" >>>;
            return;
        }
        
        spork ~addSynths[whichSynthToPlay].playNote(freq, velocity, seconds);
        whichSynthToPlay++;
        if (whichSynthToPlay >= addSynths.size())
        {
            0 => whichSynthToPlay;
        }
    }
    
    function off(float freq)
    {
        for (0 => int i; i < addSynths.size(); i++)
        {
            if (addSynths[i].isPlaying() == 1 && addSynths[i].getFreq() == freq)
            {
                addSynths[i].off();
            }
        }
    }
}