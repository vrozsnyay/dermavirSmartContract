pragma solidity 0.4.18;

/** 
 * This contract is used to set admin to the contract which has some additional features such as minting , burning etc
 */
contract Owned {

    address public owner;           // Address of smart contract owner

    /**
     * This function will assign deployer as a owner            
     */
    function owned() public {
        owner = msg.sender;
    }

    /**
     * This modifier will check whether function is been called by owner/admin 
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    /** 
     *This function is used to transfer adminship to new owner
     * @param  _newOwner - address of new admin or owner        
     */
    function transferOwnership(address _newOwner) onlyOwner public {
        require(_newOwner != address(0)); 
        owner = _newOwner;
    }          
}