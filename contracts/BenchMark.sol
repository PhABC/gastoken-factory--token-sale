pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "./TokenSale_GasTokenFactory.sol";

/**
* @dev Allows to test the gas refund procress and verify that the optimal 
*      GasToken to consume is correct for various transaction costs. 
*/
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

  /**
  * @dev Executes an expensive loop and call the gasTokenFactory.freeStorage() function
  * @param nLoops Number of loops benchmark function executes, where each loop is about ~20k gas. 
  * @param _gasTokenToConsume Number of GasTokens to consume when calling freeStorage() function
  */
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
