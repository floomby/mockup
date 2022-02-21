### Notes

Something to think about is if you have the players account call the methods in the airport contract or do you have them get called from another account such as the account which did the contract deployment initially. (I am guessing the former is preferable due to gas usage).

Also you might want to deploy the contracts behind a proxy contract so you can update them. I know how to do this in a way that works, but is not elegant. There is probably a better way.

It might be preferable to not have all these tokens in different contracts. You don't need to stick to standards but erc1155 is a standard that supports multitoken contracts. Might be worth looking into. If you want to have many more types of tokens.