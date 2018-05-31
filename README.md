### gastoken-factory--token-sale
Token Sale example implementing GasToken Factory methods.

# GasToken Factories
When storage variables are deleted from the blockchain, the sender of the transaction receives a gas refund (or negative gas) which can substantially reduce the cost of a transaction. A GasToken Factory is a smart contract that allows third parties to delete some of its storage variables in exchange of receiving the gas refund. One example could be token sale contracts, which become useless after the sale is over, yet contain a lot of data. Using an example below, a token sale contract with 10k buyers which implements GasToken Factory methods could have an additional revenue of 5–10 ETH or have 290,000,000 gas units available for future transactions. This is not only good for the contracts owners, but also for those able to obtain cheaper (or free) gas and for the rest of the network since data is deleted from the chain.

You can read more on GasToken Factories in this medium post ; 
