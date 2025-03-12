public class Follower extends Chugraph
{

//---create an envelope follower, code from follower.ck by Perry Cook
// this basically allows the breath to control the sound.
adc => Gain g => OnePole audioInEnvelope => blackhole;
// square the input
adc => g;
// multiply
3 => g.op;
//-- end Perry's code

audioInEnvelope => outlet;

}