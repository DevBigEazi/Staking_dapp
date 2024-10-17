// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./IERC20.sol";

contract StakeXFI {
    IERC20 public  XFIContract;
    IERC20 public  MPXContract;

    address internal owner;
    address internal newOnwer;

    bool locked;

    uint256 immutable MIN_STAKE_AMOUNT = 1_000 * (10**18);
    uint256 immutable MAX_STAKE_AMOUNT = 100_000 * (10**18);

    uint32 constant REWARD_PER_SECOND = 1_000_000; // 0.00001% 10e11.. 60_000_000 in 60 secs

    struct Staking{
        uint256 amount;
        uint256 startTime;
        uint256 duration;
        bool hasWithdraw;
    }

    mapping (address => Staking[]) stakers;

    constructor(address _xfiAddress, address _mpxAddress) {
        XFIContract = IERC20(_xfiAddress);
        MPXContract = IERC20(_mpxAddress);

        owner = msg.sender;
    }

    event DepositSuccessful(address indexed _staker, uint256 _amount, uint256 indexed  _startTime);
    event WithdrawalSuccessful(address indexed _staker, uint256 _amount, uint256 indexed _reward);
    event OwnershipTransfer(address indexed _prevOwner, address indexed _newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "No access");
        _;
    }

    modifier reentrancyGuard() {
        require(!locked, "Not allowed to re-enter");
        locked = true;
        _;
        locked = false;
    }

    function stake(uint256 _amount, uint256 _duration) external reentrancyGuard {
        require(msg.sender != address(0), "Zero address not allowed!");
        require(_amount >= MIN_STAKE_AMOUNT && _amount <= MAX_STAKE_AMOUNT, "Amount is out of range!");
        require(XFIContract.balanceOf(msg.sender) >= _amount, "You don't have enough token");
        require(_duration > 0, "Duration is too short");
        require(XFIContract.allowance(msg.sender, address(this)) >= _amount, "Amount is not allowed");

        XFIContract.transferFrom(msg.sender, address(this), _amount);

        Staking memory staking;
        staking.amount = _amount;
        staking.duration = block.timestamp + _duration;
        staking.startTime = block.timestamp;

        stakers[msg.sender].push(staking);

        emit DepositSuccessful(msg.sender, staking.amount, staking.startTime);
    }

    function withdrawStake(uint32 _index) external reentrancyGuard returns(bool){
        require(msg.sender != address(0), "Zero address not allowed!");

        require(_index < stakers[msg.sender].length, "Out of bound!");

        Staking storage staking = stakers[msg.sender][_index];

        require(block.timestamp > staking.duration, "Not yet time!");

        uint256 amountStaked_ = staking.amount;
        uint256 rewardAmount_ = calcReward(staking.startTime, staking.duration);


        staking.hasWithdraw = true;
        staking.amount = 0;
        staking.startTime = 0;
        staking.duration = 0;

        XFIContract.transfer(msg.sender, amountStaked_);
        MPXContract.transfer(msg.sender, rewardAmount_);

        emit WithdrawalSuccessful(msg.sender, amountStaked_, rewardAmount_);

        return true;

    }

    function getStakerInfo(uint32 _index) external view returns (Staking memory){
        require(msg.sender != address(0), "Zero address not allowed!");

        require(_index < stakers[msg.sender].length, "Out of bound!");

        Staking memory staking = stakers[msg.sender][_index];

        return staking;
    }

    function getContractXFIBalance() external onlyOwner view returns (uint256) {
        return XFIContract.balanceOf(address(this));
    }

    function getContractMPXBalance() external onlyOwner view returns (uint256) {
        return MPXContract.balanceOf(address(this));
    }

    function TransferOwnership(address _newOwner) external onlyOwner {
       require(msg.sender !=address(0), "Zero address not allowed");
       
       newOnwer = _newOwner;
    }

    function claimOwnership() external  {
        require(msg.sender !=address(0), "Zero address not allowed");
        require(msg.sender == newOnwer, "Not yet your turn!");

        emit OwnershipTransfer(owner, newOnwer);

        owner = newOnwer;
        newOnwer = address(0);
        
    }

    //HELPER
    function calcReward(uint256 _startTime, uint256 _endTime) private pure returns(uint256) {
        uint256 stakeDuration = _endTime - _startTime;
    return stakeDuration * REWARD_PER_SECOND;
    }
}