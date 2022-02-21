### Notes

2 things I can think which need to be decided
 * Do you have the players account call the methods in the airport contract or do you have them get called from another account such as the 
 account which did the contract deployment initially. (I am guessing the former is preferable due to gas usage).
 * Do you manage completion of flights and subsequent rewarding of aero on chain or not

Also you might want to deploy the contracts behind a proxy contract so you can update them. I will figure out how to do this.

Against the advice in the openzeppelin docs I just used wget to grab all the openzeppelin contracts I needed in this repo. (I only had to modify one of them.)
I also flattened the structure.