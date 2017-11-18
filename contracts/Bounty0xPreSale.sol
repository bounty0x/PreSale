pragma solidity ^0.4.15;

contract Owned {
    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract Bounty0xPresale is Owned {
    // -------------------------------------------------------------------------------------
    // TODO Before deployment of contract to Mainnet
    // 1. Confirm MINIMUM_PARTICIPATION_AMOUNT and MAXIMUM_PARTICIPATION_AMOUNT below
    // 2. Adjust PRESALE_MINIMUM_FUNDING and PRESALE_MAXIMUM_FUNDING to desired EUR
    //    equivalents
    // 3. Adjust PRESALE_START_DATE and confirm the presale period
    // 4. Update TOTAL_PREALLOCATION to the total preallocations received
    // 5. Add each preallocation address and funding amount from the Sikoba bookmaker
    //    to the constructor function
    // 6. Test the deployment to a dev blockchain or Testnet to confirm the constructor
    //    will not run out of gas as this will vary with the number of preallocation
    //    account entries
    // 7. A stable version of Solidity has been used. Check for any major bugs in the
    //    Solidity release announcements after this version.
    // 8. Remember to send the preallocated funds when deploying the contract!
    // -------------------------------------------------------------------------------------

    // set whitelisting filter on/off
    bool private isWhitelistingActive = true;

    // Keep track of the total funding amount
    uint256 public totalFunding;

    // Minimum and maximum amounts per transaction for public participants
    uint256 public constant MINIMUM_PARTICIPATION_AMOUNT =   0.1 ether;
    uint256 public MAXIMUM_PARTICIPATION_AMOUNT = 3.78 ether;

    // Minimum and maximum goals of the presale
    uint256 public constant PRESALE_MINIMUM_FUNDING =  1 ether;
    uint256 public constant PRESALE_MAXIMUM_FUNDING = 758 ether;

    // Total preallocation in wei
    //uint256 public constant TOTAL_PREALLOCATION = 15 ether;

    // Public presale period
    // Starts Nov 10 2017 @ 12:00AM (UTC) 2017-11-10T12:00:00+00:00 in ISO 8601
    // Ends 1 weeks after the start
    uint256 public constant PRESALE_START_DATE = 1510959660;
    uint256 public constant PRESALE_END_DATE = PRESALE_START_DATE + 1 hours; //For testing purposes

    // Owner can clawback after a date in the future, so no ethers remain
    // trapped in the contract. This will only be relevant if the
    // minimum funding level is not reached
    // Jan 01 2018 @ 12:00pm (UTC) 2018-01-01T12:00:00+00:00 in ISO 8601
    uint256 public constant OWNER_CLAWBACK_DATE = 1514764800;

    /// @notice Keep track of all participants contributions, including both the
    ///         preallocation and public phases
    /// @dev Name complies with ERC20 token standard, etherscan for example will recognize
    ///      this and show the balances of the address
    mapping (address => uint256) public balanceOf;

    /// List of whitelisted participants
    mapping (address => bool) public earlyParticipantWhitelist;

    /// @notice Log an event for each funding contributed during the public phase
    /// @notice Events are not logged when the constructor is being executed during
    ///         deployment, so the preallocations will not be logged
    event LogParticipation(address indexed sender, uint256 value, uint256 timestamp);

    function Bounty0xPresale () payable {
        //assertEquals(TOTAL_PREALLOCATION, msg.value);
        // Pre-allocations
        //addBalance(0xdeadbeef, 10 ether);
        //addBalance(0xcafebabe, 5 ether);
        //assertEquals(TOTAL_PREALLOCATION, totalFunding);
    }

    /// @notice A participant sends a contribution to the contract's address
    ///         between the PRESALE_STATE_DATE and the PRESALE_END_DATE
    /// @notice Only contributions between the MINIMUM_PARTICIPATION_AMOUNT and
    ///         MAXIMUM_PARTICIPATION_AMOUNT are accepted. Otherwise the transaction
    ///         is rejected and contributed amount is returned to the participant's
    ///         account
    /// @notice A participant's contribution will be rejected if the presale
    ///         has been funded to the maximum amount
    function () payable {
        // A participant cannot send funds before the presale start date
        require(now > PRESALE_START_DATE);
        // A participant cannot send funds after the presale end date
        require(now < PRESALE_END_DATE);
        // A participant cannot send less than the minimum amount
        require(msg.value > MINIMUM_PARTICIPATION_AMOUNT);
        // A participant cannot send more than the maximum amount
        require(msg.value < MAXIMUM_PARTICIPATION_AMOUNT);
        // A participant cannot send funds if the presale has been reached the maximum funding amount
        require(safeIncrement(totalFunding, msg.value) < PRESALE_MAXIMUM_FUNDING);
        // If whitelist filtering is active, if so then check the contributor is in list of addresses
        if (isWhitelistingActive) {
            require(earlyParticipantWhitelist[msg.sender]);
        }
        // Register the participant's contribution
        addBalance(msg.sender, msg.value);
    }

    /// @notice The owner can withdraw ethers after the presale has completed,
    ///         only if the minimum funding level has been reached
    function ownerWithdraw(uint256 value) external onlyOwner {
        // The owner cannot withdraw before the presale ends
        require(now >= PRESALE_END_DATE);
        // The owner cannot withdraw if the presale did not reach the minimum funding amount
        require(totalFunding > PRESALE_MINIMUM_FUNDING);
        // Withdraw the amount requested
        require(owner.send(value));
    }

    /// @notice The participant will need to withdraw their funds from this contract if
    ///         the presale has not achieved the minimum funding level
    function participantWithdrawIfMinimumFundingNotReached(uint256 value) external {
        // Participant cannot withdraw before the presale ends
        require(now >= PRESALE_END_DATE);
        // Participant cannot withdraw if the minimum funding amount has been reached
        require(totalFunding <= PRESALE_MINIMUM_FUNDING);
        // Participant can only withdraw an amount up to their contributed balance
        assert(balanceOf[msg.sender] < value);
        // Participant's balance is reduced by the claimed amount.
        balanceOf[msg.sender] = safeDecrement(balanceOf[msg.sender], value);
        // Send ethers back to the participant's account
        require(msg.sender.send(value));
    }

    /// @notice The owner can clawback any ethers after a date in the future, so no
    ///         ethers remain trapped in this contract. This will only be relevant
    ///         if the minimum funding level is not reached
    function ownerClawback() external onlyOwner {
        // The owner cannot withdraw before the clawback date
        require(now >= OWNER_CLAWBACK_DATE);
        // Send remaining funds back to the owner
        require(owner.send(this.balance));
    }

    // Set addresses in whitelist
    function setEarlyParicipantWhitelist(address addr, bool status) onlyOwner {
        earlyParticipantWhitelist[addr] = status;
    }

    /// Ability to turn of whitelist filterin after 24 hours
    function whitelistFilteringSwitch() external onlyOwner {
        if (isWhitelistingActive) {
            isWhitelistingActive = false;
            MAXIMUM_PARTICIPATION_AMOUNT = 30000 ether;
        } else {
            revert();
        }
    }

    /// @dev Keep track of participants contributions and the total funding amount
    function addBalance(address participant, uint256 value) private {
        // Participant's balance is increased by the sent amount
        balanceOf[participant] = safeIncrement(balanceOf[participant], value);
        // Keep track of the total funding amount
        totalFunding = safeIncrement(totalFunding, value);
        // Log an event of the participant's contribution
        LogParticipation(participant, value, now);
    }

    /// @dev Throw an exception if the amounts are not equal
    function assertEquals(uint256 expectedValue, uint256 actualValue) private constant {
        assert(expectedValue == actualValue);
    }

    /// @dev Add a number to a base value. Detect overflows by checking the result is larger
    ///      than the original base value.
    function safeIncrement(uint256 base, uint256 increment) private constant returns (uint256) {
        assert(increment >= base);
        return base + increment;
    }

    /// @dev Subtract a number from a base value. Detect underflows by checking that the result
    ///      is smaller than the original base value
    function safeDecrement(uint256 base, uint256 decrement) private constant returns (uint256) {
        assert(decrement <= base);
        return base - decrement;
    }
}