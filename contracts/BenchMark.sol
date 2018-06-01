pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "./TokenSale_GasTokenFactory.sol";

// mock class using StandardToken
contract BenchMark {

  // Gas token factory
  TokenSale_GasTokenFactory public gasTokenFactory;

  // Mapping variable for benchmark
  mapping(bytes32 => uint256) public randStorage; 
  uint256 benchmarkSeed = 1;

  //Set gasTokenFactory address
  constructor(TokenSale_GasTokenFactory _gasTokenFactory) public {
    gasTokenFactory = _gasTokenFactory;
  }

  //Function that costs 2085112 gas
  function benchMark(uint256 nLoops, uint256 _gasTokenToConsume) public payable {
    bytes32 hash = keccak256(abi.encodePacked(benchmarkSeed));

    for (uint256 i = 0; i < nLoops; i++){
      randStorage[hash] = 1;
      hash = keccak256(abi.encodePacked(hash));
    }

    // freeStorage
    if (_gasTokenToConsume > 0) {
      gasTokenFactory.freeStorage.value(msg.value)(_gasTokenToConsume);
    }

    // Increment benchmask init value
    benchmarkSeed ++;
  
  }
}
