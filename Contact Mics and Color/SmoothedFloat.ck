//---------------------------
//Author: Courtney
//Date: January 2025
//class SmoothedVariable
//this is for a float that needs to change for sound parameters
//it changes the float over time smoothly so there are no clicks, etc. noise



public class SmoothedFloat
{        
    second / samp => float SRATE; //sample rate
    1 / SRATE => float T; //time step
     
    0 => float curVal; //the variable to change
    0 => float dT; //the 1st derivative change over time (ie, the infinitesimal, but not infinit lol)
    500 => float modT; //a modification to the time-step
    0 => float goalVal; //the goal value
    
    function SmoothedFloat()
    {
        //do nothing keep default values
    }
    
    //set the initial value
    function SmoothedFloat(float v)
    {
        v => curVal;
        v => goalVal;
    }
    
    //set the initial value & mod
    function SmoothedFloat(float v, float mod)
    {
        v => curVal;
        v => goalVal;
        mod => modT;
    }
    
    //this will start changing the val to reach the goal value
    function set(float v)
    {
        v => goalVal; 
    }
    
    //this will update the value as time passes so it heads towards the goal value
    function update()
    {
        goalVal - curVal => float diff;
        (dT + diff)*T*modT => dT ; 
        curVal + dT => curVal; 
    }
    
    //return the current value
    function float get()
    {
        return curVal;
    }
    
    //make the value change faster or slower
    function setModT(float m)
    {
        m => modT;
    }
}
//---------------------------
//---------------------------