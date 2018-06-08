# GasToken Factories
When storage variables are deleted from the blockchain, the sender of the transaction receives a gas refund (or negative gas) which can substantially reduce the cost of a transaction. A GasToken Factory is a smart contract that allows third parties to delete some of its storage variables in exchange of receiving the gas refund. One example could be token sale contracts, which become useless after the sale is over, yet contain a lot of data. Using an example below, a token sale contract with 10k buyers which implements GasToken Factory methods could have an additional revenue of 5–10 ETH or have 290,000,000 gas units available for future transactions. This is not only good for the contracts owners, but also for those able to obtain cheaper (or free) gas and for the rest of the network since data is deleted from the chain.

This repository contains an implementation example using an [OpenZeppelin token sale contract](https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/crowdsale/validation/IndividuallyCappedCrowdsale.sol) as a skeleton. 

You can read more on GasToken Factories in this [medium post](https://blog.polymath.network/turning-smart-contracts-into-gastoken-factories-3e947f664e8b).

## Test Instructions

Run `npm install` to install node packages.

Run `npm test` to run basic tests. 

## Disclaimer
The contracts provided here were not audited nor optimized, hence please do not reuse in production without doing your due diligence. The contracts provides no share or promise of anything and contract will probably stop working with future hard forks in the next following years.

