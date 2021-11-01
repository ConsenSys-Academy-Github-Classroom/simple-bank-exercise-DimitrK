/*
 * This exercise has been updated to use Solidity version 0.8.5
 * See the latest Solidity updates at
 * https://solidity.readthedocs.io/en/latest/080-breaking-changes.html
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleBank {
    /* State variables
     */
    bool internal locked;

    // Fill in the visibility keyword.
    // Hint: We want to protect our users balance from other contracts
    mapping(address => uint256) private balances;

    // Fill in the visibility keyword
    // Hint: We want to create a getter function and allow contracts to be able
    //       to see if a user is enrolled.
    mapping(address => bool) public enrolled;

    // Let's make sure everyone knows who owns the bank, yes, fill in the
    // appropriate visilibility keyword
    address public owner = msg.sender;

    /* Events - publicize actions to external listeners
     */

    // Add an argument for this event, an accountAddress
    event LogEnrolled(address indexed accountAddress);

    // Add 2 arguments for this event, an accountAddress and an amount
    event LogDepositMade(address indexed accountAddress, uint256 amount);

    // Create an event called LogWithdrawal
    // Hint: it should take 3 arguments: an accountAddress, withdrawAmount and a newBalance
    event LogWithdrawal(
        address indexed accountAddress,
        uint256 withdrawAmount,
        uint256 newBalance
    );

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    modifier enrolledOnly(address requester) {
        require(
            enrolled[requester],
            "address must first enroll to use this method"
        );
        _;
    }
    /* Functions
     */

    // Fallback function - Called if other functions don't match call or
    // sent ether without data
    // Typically, called when invalid data is sent
    // Added so ether sent to this contract is reverted if the contract fails
    // otherwise, the sender's money is transferred to contract
    fallback() external payable {
        revert();
    }

    /// @notice Get balance
    /// @return The balance of the user
    function getBalance() public view returns (uint256) {
        // 1. A SPECIAL KEYWORD prevents function from editing state variables;
        //    allows function to run locally/off blockchain
        // 2. Get the balance of the sender of this transaction
        return balances[msg.sender];
    }

    /// @notice Enroll a customer with the bank
    /// @return The users enrolled status
    // Emit the appropriate event
    function enroll() public returns (bool) {
        require(enrolled[msg.sender] != true, "address already enrolled");

        enrolled[msg.sender] = true;
        emit LogEnrolled(msg.sender);
        return true;
    }

    /// @notice Deposit ether into bank
    /// @return The balance of the user after the deposit is made
    function deposit()
        public
        payable
        enrolledOnly(msg.sender)
        returns (uint256)
    {
        require(msg.value > 0, "invalid deposit amount");
        balances[msg.sender] += msg.value;
        emit LogDepositMade(msg.sender, msg.value);

        return balances[msg.sender];
        // 1. Add the appropriate keyword so that this function can receive ether
        // 2. Users should be enrolled before they can make deposits
        // 3. Add the amount to the user's balance. Hint: the amount can be
        //    accessed from of the global variable `msg`
        // 4. Emit the appropriate event associated with this function
        // 5. return the balance of sndr of this transaction
    }

    /// @notice Withdraw ether from bank
    /// @dev This does not return any excess ether sent to it
    /// @param withdrawAmount amount you want to withdraw
    /// @return The balance remaining for the user
    function withdraw(uint256 withdrawAmount)
        public
        payable
        enrolledOnly(msg.sender)
        noReentrant
        returns (uint256)
    {
        // If the sender's balance is at least the amount they want to withdraw,
        // Subtract the amount from the sender's balance, and try to send that amount of ether
        // to the user attempting to withdraw.
        // return the user's balance.
        // 1. Use a require expression to guard/ensure sender has enough funds
        // 2. Transfer Eth to the sender and decrement the withdrawal amount from
        //    sender's balance
        // 3. Emit the appropriate event for this message
        require(withdrawAmount > 0, "incorrect withdrawal amount");
        require(balances[msg.sender] >= withdrawAmount, "insufficient funds");

        uint256 newBalance =  balances[msg.sender] - withdrawAmount ;
        balances[msg.sender] = newBalance;
        (bool success, ) = msg.sender.call{value: withdrawAmount}("");

        if (!success) {
            revert("failed to send Eth");
        }

        emit LogWithdrawal(msg.sender, withdrawAmount, newBalance);
        return newBalance;
    }
}
