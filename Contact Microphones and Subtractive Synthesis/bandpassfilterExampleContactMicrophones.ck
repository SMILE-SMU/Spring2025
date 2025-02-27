/** 
    Coder: Courtney Brown
    Date: Feb. 27, 2025
    Desc: Shows how to do subtractive synthesis on incoming audio
    Also shows how to do some interactive structuring of pitches and rhythms in chuck
    Current version chooses random motives to filter out

    One task would be refactor to use loops and arrays to get rid of some of this code repetition

    CLICK HERE to open in WebChuck: https://tinyurl.com/yxpmn2m4

**/

//Signal path for subtractive synthesis, we added an Echo to add an effect as requested
adc => ResonZ reson1 => Echo echo1 => Dyno limiter => dac; 
adc => ResonZ reson2 => Echo echo2 => limiter; 
adc => ResonZ reson3 => Echo echo3 => limiter; 
adc => ResonZ reson4 => Echo echo4 => limiter; 
adc => ResonZ reson5 => Echo echo5 => limiter; 

//set the delay times
125::ms => echo1.delay; 
250::ms => echo2.delay; 
500::ms => echo3.delay;
50::ms => echo4.delay;
100::ms => echo5.delay;

//set the width all the bandpass filters
15 => reson1.Q; 
15 => reson2.Q; 
15 => reson3.Q; 
15 => reson4.Q; 
15 => reson5.Q; 

//motives in C major 
[60, 62, 64] @=> int motive1[];
[72, 71] @=> int motive2[];
[60, 64] @=> int motive3[];
[60, 62, 64, 65, 67, 69, 71, 72] @=> int motive4[]; //C scale
[65, 67, 69,] @=> int motive5[];
[65, 67,] @=> int motive6[];
[57, 59, 60] @=> int motive7[];
[59, 62] @=> int motive8[];

//all the motives in one 2D array
[ motive1, motive2, motive3, motive4, motive5, motive6, motive7, motive8 ] @=> int melodies[][];
motive1 @=> int midiNotes[]; //first thing to play
0 => int melodyIndex; //the index into the 2D array of melodies

//an array of possible rhythms -- there is more 250::ms so when we choose randomly we'll get more
[250::ms, 500::ms, 750::ms, 250::ms, 250::ms, 250::ms, 1000::ms] @=> dur rhythms[]; 

250::ms => dur noteLength; //how long a note will play (ie, a pitch will filter -- as the incoming audio will really affect rhythm)
now => time lastChecked; 
0 => int index; 


while( true ) //go FOREVER
{
    1::ms => now; //check a millisecond to now -- make time pass

    //checks to see if a noteLength of time has passed since we last checked the time
    //if so, then we will change the center frequencies of the bandpass filter
    if( now - lastChecked >= noteLength )
    {
        now => lastChecked; //we just checked! so set lastChecked to now

        //set the filter frequency to the current note in the melodic motive
        //also, set the other bandpass center frequencies to harmonic series of 1st freq.
        Std.mtof( midiNotes[index] ) => float freq; 
        freq => reson1.freq; 
        freq * 2 => reson2.freq; 
        freq * 3  => reson3.freq; 
        freq * 4  => reson4.freq; 
        freq * 5  => reson5.freq; 

        //change rhythms randomly
        Math.random2(0, rhythms.size()-1) => int rhyIndex; 
        rhythms[rhyIndex] => noteLength;

        //output what's happening to the console -- so we KNOW things are working
        <<<"note: " + midiNotes[index] + " , " + rhyIndex>>>; 
 
        index + 1 => index ;  //incrementing the note index in the melody

        //if we're at the end of the current melody, chose the next one -- randomly!
        if( index >= midiNotes.size() )
        {
            0 => index; 

            //change melodies
            Math.random2(0, melodies.size()-1) => melodyIndex;
            melodies[melodyIndex] @=> midiNotes;
        }
    } 
}