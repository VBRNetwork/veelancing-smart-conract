// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./VEEToken.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/access/AccessControl.sol";
import "hardhat/console.sol";

contract VEECrowdsale is AccessControl {
    using SafeMath for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant RATER_ROLE = keccak256("RATER_ROLE");
    bytes32 public constant DEPOSIT_ROLE = keccak256("DEPOSIT_ROLE");

    uint256 public tokenBalance;
    uint256 public TotalClaimed;

    uint256 public amountICO;
    uint256 public amountPreICO;

    uint256 public preICOStart;
    uint256 public preICOEnd;
    uint256 public period_1;
    uint256 public period_2;
    uint256 public period_3;
    uint256 public period_4;

    uint256 public purchase_1 = 20000;
    uint256 public purchase_2 = 100000;
    uint256 public purchase_3 = 200000;

    enum CrowdsaleState {Unknown, PreICO, ICO, Finished}

    struct PreICOData {
        uint256 amount;
        uint256 amountClaimed;
    }
    mapping(address => PreICOData) public preICO;

    address payable storage_eth;
    uint256 public RateICO;
    uint256 public RatePreICO;
    uint256 public Precision = 1000000;

    VEEToken public VEE;

    constructor(
        uint256 _rateICO,
        uint256 _ratePreICO,
        address payable _storageETH,
        uint256 preICOStart_,
        uint256 _amountICO,
        uint256 _amountPreICO
    ) public {
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(RATER_ROLE, msg.sender);
        _setupRole(DEPOSIT_ROLE, msg.sender);
        // Sets `DEFAULT_ADMIN_ROLE` as ``ADMIN_ROLE``'s admin role.
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        // Sets `ADMIN_ROLE` as ``RATER_ROLE``'s admin role.
        _setRoleAdmin(RATER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(DEPOSIT_ROLE, ADMIN_ROLE);

        amountICO = _amountICO;
        amountPreICO = _amountPreICO;

        preICOStart = preICOStart_;
        preICOEnd = preICOStart_.add(14 days);
        period_1 = 60 days;
        period_2 = 90 days;
        period_3 = 120 days;
        period_4 = 180 days;

        storage_eth = _storageETH;
        RateICO = _rateICO;
        RatePreICO = _ratePreICO;
    }

    /**
     * @dev Initialize the token contract
     *
     */
    function initialize(address _token) external {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "VEECrowdsale: caller is not an admin"
        );
        require(
            address(VEE) == address(0),
            "VEECrowdsale: contract already initialized"
        );
        VEE = VEEToken(_token);
    }

    /**
     * @dev Synchronizes the token balance on the contract
     *
     */
    function sync() external {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "VEECrowdsale: caller is not an admin"
        );
        tokenBalance = VEE.balanceOf(address(this));
    }

    /**
     * @dev Shows the status of ICO
     *
     */
    function getCurrentStatus() external view returns (CrowdsaleState state) {
        state = getState();
        return state;
    }

    function getState() private view returns (CrowdsaleState state) {
        if (block.timestamp < preICOStart) {
            state = CrowdsaleState.Unknown;
        } else if (
            (block.timestamp >= preICOStart) && (block.timestamp <= preICOEnd)
        ) {
            state = CrowdsaleState.PreICO;
        } else if ((block.timestamp > preICOEnd) && (tokenBalance == 0)) {
            state = CrowdsaleState.ICO;
        } else {
            state = CrowdsaleState.Finished;
        }

        return state;
    }

    /**
     * @dev Executes the swap
     *
     */
    receive() external payable {
        storage_eth.transfer(msg.value);
        swap(msg.value, msg.sender);
    }

    /**
     * @dev swap ETH to VEE token in ICO period
     *
     * Requirements:
     *
     * - `_receiver` cannot be the zero address.
     * - `_amount` in ETH.
     */
    function deposit(address _receiver, uint256 _amount) external {
        require(
            hasRole(DEPOSIT_ROLE, msg.sender),
            "VEECrowdsale: caller is not a depositor"
        );
        swap(_amount, _receiver);
    }

    /**
     * @dev Calculate equivalent amount of VEE token
     *
     * Requirements:
     *
     * - `_sender` cannot be the zero address.
     * - `_amount` in ETH.
     */
    function swap(uint256 _amount, address _sender)
        private
        returns (uint256 amount_vee)
    {
        CrowdsaleState state = getState();

        require(
            (state == CrowdsaleState.PreICO) || (state == CrowdsaleState.ICO),
            "VEECrowdsale: ICO is not available yet"
        );

        if (state == CrowdsaleState.PreICO) {
            require(
                amountPreICO >= _amount,
                "VEECrowdsale: Pre-ICO limit has been exeeded"
            );
            amount_vee = _amount.mul(RatePreICO).div(Precision);
            PreICOData storage data = preICO[_sender];
            data.amount = data.amount.add(amount_vee);
            amountPreICO = amountPreICO.sub(amount_vee);
        } else {
            require(
                amountICO >= _amount,
                "VEECrowdsale: ICO limit has been exeeded"
            );
            amount_vee = _amount.mul(RateICO).div(Precision);
            VEE.transfer(_sender, amount_vee);
            amountICO = amountICO.sub(amount_vee);
        }
        return amount_vee;
    }

    /**
     * @dev Claim of available tokens bought in pre-ICO period
     *
     * Requirements:
     *
     * - `amount` in VEE.
     */
    function claim(uint256 _amount) external {
        uint256 claimAmount = getClaimAllowed();
        require(
            _amount <= claimAmount,
            "VEECrowdsale: Not enough tokens are available to claim"
        );
        preICO[msg.sender].amountClaimed = preICO[msg.sender].amountClaimed.add(
            _amount
        );
        TotalClaimed = TotalClaimed.add(_amount);
        VEE.transfer(msg.sender, _amount);
    }

    /**
     * @dev Calculates available tokens bought in pre-ICO period to claim
     *
     */
    function getClaimAllowed() public view returns (uint256 claimAmount) {
        uint256 firstClaim;
        PreICOData storage claimer = preICO[msg.sender];

        if (
            claimer.amount == 0 ||
            claimer.amount.sub(claimer.amountClaimed) == 0
        ) {
            return 0;
        }

        if (claimer.amount < purchase_1.mul(1e18)) {
            firstClaim = period_1;
        } else if (
            claimer.amount >= purchase_1.mul(1e18) &&
            claimer.amount < purchase_2.mul(1e18)
        ) {
            firstClaim = period_2;
        } else if (
            claimer.amount >= purchase_2.mul(1e18) &&
            claimer.amount < purchase_3.mul(1e18)
        ) {
            firstClaim = period_3;
        } else if (claimer.amount >= purchase_3.mul(1e18)) {
            firstClaim = period_4;
        }

        if (now.sub(preICOEnd) > firstClaim) {
            claimAmount = claimer.amount.mul(4).div(10);
            if (now.sub(preICOEnd) > firstClaim.add(period_1)) {
                claimAmount = claimer.amount.mul(7).div(10);
                if (now.sub(preICOEnd) > firstClaim.add(period_3)) {
                    claimAmount = claimer.amount;
                }
            }
            claimAmount = claimAmount.sub(claimer.amountClaimed);
            return claimAmount;
        }
    }

    /**
     * @dev Update exchange rate for ICO stage
     *
     */
    function updateRateICO(uint256 _rate) external {
        require(
            hasRole(RATER_ROLE, msg.sender),
            "VEECrowdsale: Caller is not a rater"
        );
        RateICO = _rate;
    }

    /**
     * @dev Update exchange rate for pre ICO stage
     *
     */
    function updateRatePreICO(uint256 _rate) external {
        require(
            hasRole(RATER_ROLE, msg.sender),
            "VEECrowdsale: Caller is not a rater"
        );
        RatePreICO = _rate;
    }

    /**
     * @dev Update rate precision
     *
     */
    function updatePrecision(uint256 _precision) external {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "VEECrowdsale: Caller is not an admin"
        );
        Precision = _precision;
    }
}
