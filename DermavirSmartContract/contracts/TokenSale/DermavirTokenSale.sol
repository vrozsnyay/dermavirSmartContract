pragma solidity 0.4.18;

import '../Token/Owned.sol';
import '../Math/SafeMath.sol'; 

/**
 This is interface to transfer Dermavir tokens , created by DERMAVIR token contract+
 */
interface DermavirToken {
    function transfer(address _to, uint256 _value) external returns (bool);
}

/**
 * This is the main DERMAVIR Token Sale contract
 */
contract DermavirTokenSale is Owned {

	using SafeMath for uint256;

	mapping (address=> uint256) private contributors ;
	mapping (address=> bool) private isTokenTransferred;
		
	// start and end timestamps when contributions are allowed  (both inclusive)
	uint256 constant public STARTTIME = 1522400400;  // 30th march 09:00am GMT (9:00 am UTC)
	uint256 public endTime;

	// address where all funds collected from token sale are stored
	address private wallet;

	// amount of raised money in wei
	uint256 public weiRaised;

	// maximum gas price for contribution transactions - 50 GWEI
	uint256 public maxGasPrice = 50000000000 wei;  

	// The token being sold
	DermavirToken public token;

	// To check whether all token are sold 
	bool private hasFirstPreICOCapReached = false;
	bool private hasSecondPreICOCapReached = false;
	bool private hasThirdPreICOCapReached = false;
	bool private hasCrowdSaleICOCapReached = false;

	/**
  	 * event for funds received logging
  	 * @param contributor address who contributed for the tokens     
  	 */
	event ContributionReceived(address indexed contributor, uint256 value) ;

	/**
	 * event for tokens transferred logging
	 * @param contributor who contributed for the tokens     
	 */
	event TokensTransferred(address indexed contributor, uint256 value) ;

	/**
	 * Fix for the ERC20 short address attack.
	 */
	modifier onlyPayloadSize(uint256 size) {
		assert(msg.data.length == size + 4);
		_;
	}

	/**
	 * Constructor to set the parameter like Token address, wallet address
	 */
	function DermavirTokenSale(DermavirToken _addressOfRewardToken, address _wallet) public {
		require(STARTTIME >= now); 			// Check if start time is greater then current time
		require(_wallet != address(0));		// Check whether is not equal to null
  		endTime = (STARTTIME + 60 days); 	// Endtime is 60 days from starttime  , 30 days of Pre token sale and 30 days of token sale //UTC end time is 1527670800
		token = DermavirToken (_addressOfRewardToken);
  		wallet = _wallet;
		owner = msg.sender; // Deployer of the contract will be owner to the contract
	}

	/** 
	 * Verifies that the gas price is lower than max gas price
	 */
	modifier validGasPrice() {
		require(tx.gasprice <= maxGasPrice);
		_;
	}

	/**
	 * Fallback function used to buy tokens , this function is called when anyone sends ether to this contract
	 */
	function () payable public validGasPrice {  
		require(msg.sender != address(0));                     	//contributor address should not be zero
		require(msg.value >= 0.1 ether);              			//contribution amount should be greater then 0.1 ETH            
		require(msg.value <= 600 ether);						//contribution amount should not be greater then 600 ETH
		require(isContributionAllowed());                      	//Valid time of contribution and cap has not been reached 

		//forward fund received to Dermavir multisig Account
		forwardFunds();

		// Add to contributions with the contributor
		contributors[msg.sender] = contributors[msg.sender].add(msg.value);
		weiRaised = weiRaised.add(msg.value);
		
		isTokenTransferred[msg.sender] = false;					// Tokens are not yet transferred

		//Notify server that an contribution has been received
		ContributionReceived(msg.sender, msg.value);
	}

	/**
	 * This function is used to check if an contribution is allowed or not
	 */
	function isContributionAllowed() public view returns (bool) {
		if (isTokenSaleActive())
			return true;
		else
			return false;
	}

	/**
	 * Send ether to the fund collection wallet
	 */
	function forwardFunds() internal {
		wallet.transfer(msg.value);
	}


	/**
	 * Token Sale time
	 */
	function isTokenSaleActive() internal view returns (bool) {
		if (now >= STARTTIME && now < STARTTIME + 15 days)						// If condition met please check boolean value of hasTokenSaleCapReachedPre1 and send
 			return (!hasFirstPreICOCapReached);
		else if ((now >= STARTTIME + 15 days) && (now < STARTTIME + 30 days)) 	// If condition met please check boolean value of hasTokenSaleCapReachedPre2 and send	
			return (!hasSecondPreICOCapReached);
		else if ((now >= STARTTIME + 30 days) && (now < STARTTIME + 45 days)) 	// If condition met please check boolean value of hasTokenSaleCapReachedPre3 and send	
			return (!hasThirdPreICOCapReached);
		else if ((now >= STARTTIME + 45 days) && (now < STARTTIME + 60 days)) 	// If condition met please check boolean value of hasTokenSaleCapReachedCrowdSale and send	
			return (!hasCrowdSaleICOCapReached);
		else
			return false;														// Else token sale has not started or ended
	}
    
	/**
	 * Called by owner when first pre ico token cap has been reached
	 */ 
	function firstPreICOCapReached() public onlyOwner {
 		hasFirstPreICOCapReached = true;
	}

	/**
	 * Called by owner when second pre ico token cap has been reached
	 */ 
	function secondPreICOCapReached() public onlyOwner {
 		hasSecondPreICOCapReached = true;
	}

	/**
	 * Called by owner when third pre ico token cap has been reached
	 */ 
	function thirdPreICOCapReached() public onlyOwner {
 		hasThirdPreICOCapReached = true;
	}

	/**
	 * Called by owner when crowd sale ico token cap has been reached
	 */
	function crowdSaleICOCapReached() public onlyOwner {
 		hasCrowdSaleICOCapReached = true;
	}

	/**
	 * This function is used to transfer token to contributor after successful audit
	 */
	function transferToken(address _contributor, uint _numberOfTokens) public onlyPayloadSize(2 * 32) onlyOwner {
    	require(!isTokenTransferred[_contributor]);   //check if tokens are not already transferred to avoid multiple token transfers
      	require(_numberOfTokens > 0);
      	require(_contributor != address(0));

      	isTokenTransferred[_contributor] = true;       //to avoid duplicate token transfer
      	token.transfer(_contributor, _numberOfTokens);
     	//fire event 
      	TokensTransferred(_contributor,_numberOfTokens);      
	} 

	/**
	 * This function allows the owner to update the gas price limit public onlyOwner
	 */
	function setMaxGasPrice(uint256 _gasPrice) public onlyOwner {
		maxGasPrice = _gasPrice;
	}
}