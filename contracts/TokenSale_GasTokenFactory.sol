pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @title TokenSale_GasTokenFactory
 * @dev TokenSale_GasTokenFactory is a simple crowdsale contract inspired from 
 *      OpenZeppeling library, but with a GasToken Factory component integrated.
 *      Sale participants are capped and whitelisted. 
 *      Once the sale is finalized, third parties can call #freeStorage() and 
 *      purchase available gas refund at a given price. This price per gas 
 *      unit is specified by #costPerGasUnit;
 */
contract TokenSale_GasTokenFactory is Ownable {
  using SafeMath for uint256;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  // Finalized sale
  bool finalized = false; 

        // IndividuallyCappedCrowdsale mappings
        mapping(address => uint256) public contributions; // Keeps track of user's contribution
        mapping(address => uint256) public caps;          // How much wei can each user contribute to

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }




  // ----------------------------------------------------- //
  //               Crowdsale External Interface            //
  // ----------------------------------------------------- //

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external payable {
    buyTokens(msg.sender);
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    // How many weis are sent for purchase
    uint256 weiAmount = msg.value;
    
    // Verify that the purchase is valid
    _preValidatePurchase(_beneficiary, weiAmount);

    // Calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // Update fund raised
    weiRaised = weiRaised.add(weiAmount);

    // Transfer tokens to _beneficiary
    token.transfer(_beneficiary, tokens);

    // Increase contribution by _benificiary
    contributions[_beneficiary] = contributions[_beneficiary].add(weiAmount);

    // Transfer funds to fund wallet
    wallet.transfer(msg.value);
  }

  /**
   * @dev Owner can finalize sell, where tokens can't be sold anymore
   */
  function finalizeSale() onlyOwner public {
    require(!finalized);
    finalized = true;
  }



  // ----------------------------------------------------- //
  //             Internal Interface (Extensible)           //
  // ----------------------------------------------------- //

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  { 
//  require(isWhitelisted(_benificiary)); Is not required since cap acts as whitelist
    require(contributions[_beneficiary].add(_weiAmount) <= caps[_beneficiary]);
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
    require(!finalized);
  }



  // ----------------------------------------------------- //
  //         IndividuallyCappedCrowdsale Functions         //
  // ----------------------------------------------------- //

  /**
   * @dev Sets a specific user's maximum contribution
   * @param _beneficiary Address to be capped
   * @param _cap Wei limit for individual contribution
   */
  function setUserCap(address _beneficiary, uint256 _cap) external onlyOwner {
    caps[_beneficiary] = _cap;

    // Save user info to free later
    _mintGasToken(_beneficiary);
  }




  // ----------------------------------------------------- //
  //                GasTokenFactory Functions              //
  // ----------------------------------------------------- //

  // We start our storage at this location. The EVM word at this location
  // contains the number of stored words. The stored words follow at
  // locations (STORAGE_LOCATION_ARRAY+1), (STORAGE_LOCATION_ARRAY+2), ...
  // Make sure this does not collide with other variables, this will be 
  // different in each GasToken Factory contract.
  uint256 constant STORAGE_LOCATION_ARRAY = 0xDEADBEEF;

    // Refunded gas for every gasToken consumed (optimal)
  uint256 constant GAS_REFUNDED_PER_GASTOKEN = 29520; 

  // If selling the gas tokens, what price will each gasUnit cost
  uint256 public costPerGasUnit = 30 * 10**9; // 30 GWei

  /**
  * @dev Keeps track of all the storage slots that can be freed in this contract
  * @param _user Address that is associated with mappings that can be freed
  */ 
  function _mintGasToken(address _user) internal {
    // Loading storage location array in memory to use with assembly
    uint256 storage_location_array = STORAGE_LOCATION_ARRAY; 

    // Read gasToken supply
    uint256 gasTokenSupply;
    assembly {  gasTokenSupply := sload(storage_location_array)  }

    // Index where to store info
    uint256 index = storage_location_array + gasTokenSupply + 1;

    // Store user info to free storage space
    assembly {  sstore(index, _user)  }

    // Update gasToken gasTokenSupply
    assembly {  sstore(storage_location_array, add(gasTokenSupply, 1))  }
  }

      /**
      * @dev Allow anyone to free some of the storage used by this contract
      * @param _amount Amount of storage slots you want to free
      *
      */
      function freeStorage(uint256 _amount) public payable {
        
        // Check if tokensale is finalized
        require(finalized, 'Sale not finalized');

        // Loading storage location array in memory to use with assembly
        uint256 storage_location_array = STORAGE_LOCATION_ARRAY; 

        // Read gasToken gasTokenSupply
        uint256 gasTokenSupply;
        assembly {  gasTokenSupply := sload(storage_location_array)  }

        // Check if gas token gasTokenSupply is sufficient
        require(_amount <= gasTokenSupply, 'Not enough gasTokens available');

        // Cost to consume _amount of gas tokens
        uint256 cost = getFreeStorageCost(_amount);

        // Check if sender has enough funds to pay for the gas tokens consummed
        require(msg.value >= cost, 'Insufficient funds to pay for the gasTokens');

        // Address to empty storage of
        address user;

        // Clear memory locations in interval [l, r] for gasTokens array
        uint256 l = storage_location_array + gasTokenSupply - _amount + 1;
        uint256 r = storage_location_array + gasTokenSupply;

        
        // Empty storage
        for (uint256 i = l; i <= r; i++) {

            // Loading current user address
            assembly {  user := sload(i)  }

            // Empty user caps and contributions
            caps[user] = 0;
            contributions[user] = 0;

            // Burn gasToken associated with user
            assembly {  sstore(i, 0)  }
        }

        // Transfer funds to wallet
        wallet.transfer(cost);

        // Refund msg.sender if msg.value was too high
        if (cost < msg.value){
          msg.sender.transfer( (msg.value).sub(cost) );
        }
        
        // Update tokenGas gasTokenSupply
        assembly {  sstore(storage_location_array, sub(gasTokenSupply, _amount))  }
      }

  /**
  * @dev Return the total supply of gas tokens
  */
  function totalGasTokenSupply() public constant returns (uint256 gasTokenSupply) {
      uint256 storage_location_array = STORAGE_LOCATION_ARRAY;
      assembly {
          gasTokenSupply := sload(storage_location_array)
      }
  }

  /**
  * @dev Return the optimal amount of gas token to consume for given tx gas cost
  *         This is required since gas refund can only account for 50% of a tx gas.
  * @param _txGasCost Amount of gas a transaction would cost WITHOUT calling the 
  *                   freeStorage() function on this contract.
  * 
  * /------------------------------------NOTES------------------------------------/
  *
  * > Gas cost for freeing N storage slots for this contract & pay:   
  *                         
  *              => W ~= 15480 * N + 22790
  * 
  * > Total gas cost, where G is the cost of the original transaction
  *
  *              => Z = 15480 * N + 22790 + G
  *
  * > Number of tokens to consume to obtain 50% gas in refund :  
  *
  *              => N ~= G / 74520 + 0.305;
  *
  * /-----------------------------------------------------------------------------/
  *
  */ 
  function getOptimalGasTokenAmount(uint256 _txGasCost) 
      pure public returns (uint256) 
  { 
            //   N ~= G / 74500 + 0.2;
    uint256 dec = 10**3;
    return ( _txGasCost * dec / 74520 + 305) / dec; //Returns floor value
  }

  /**
  * @dev Return the cost users need to pay to free storage
  * @param _amount Amount of gasTokens to consume
  *
  */ 
  function getFreeStorageCost(uint256 _amount) view public returns (uint256 cost) {
    return costPerGasUnit.mul(GAS_REFUNDED_PER_GASTOKEN).mul(_amount);
  }
  
}