//-----------------------------------------------------------------------------
// name: polyphonicAdditiveSynth.ck
// classes: 1 - AdditiveSynth -- an AdditiveSynth string class 
//          2 - AdditiveSynths -- uses a AdditiveSynth per voice to create polyphonic (many notes playing at once) sound
// date: January 2025
// desc: polyphonic keyboard Additive Synth --- also example of using the polysyth template.
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
    
    SinOsc sin => ADSR env(200::ms, 100::ms, 0.25, 500::ms) => Dyno limiter => dac;
    SinOsc sin2 => ADSR env2(200::ms, 100::ms, 0.25, 500::ms) => limiter;
    SinOsc sin3 => ADSR env3(200::ms, 100::ms, 0.25, 500::ms) => limiter;
    SinOsc sin4 => ADSR env4(200::ms, 100::ms, 0.25, 500::ms) => limiter; 
    
    [ sin, sin2, sin3, sin4 ] @=> SinOsc sinList[]; //an array of our SinOsc objects
    [ env, env2, env3, env4 ] @=> ADSR envList[]; //an array of our Envelope objects
    
    
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
        
        for( 0=>int i; i<4; i++)
        {
            (i+1)*freq => sinList[i].freq;
        }
        
        
        freq => curFreq;
        1 => playing;
        
        //sustain(sus, freq);
        
        
        for( 0 => int i; i<4; i++ )
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
        
        for( 0 => int i; i<4; i++ )
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