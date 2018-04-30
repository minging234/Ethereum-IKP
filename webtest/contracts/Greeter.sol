pragma solidity ^0.4.19;

contract Greeter         
{
    address creator;     
    string greeting;     

    constructor() public   
    {
        creator = msg.sender;
        greeting = "hello";
    }

    function greet() constant returns (string)          
    {
        return greeting;
    }
    
    function setGreeting(string _newgreeting) 
    {
        greeting = _newgreeting;
    }
    
     /**********
     Standard kill() function to recover funds 
     **********/
    
    function kill()
    { 
        if (msg.sender == creator)
            selfdestruct(creator);  // kills this contract and sends remaining funds back to creator
    }

}