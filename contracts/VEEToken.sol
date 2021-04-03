// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Capped.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/access/AccessControl.sol";
import "hardhat/console.sol";

contract VEEToken is ERC20, ERC20Capped, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor(
        string memory name,
        string memory symbol,
        uint256 cap,
        address Crowdsale,
        address Investors,
        address Rewards,
        address Team,
        address Liquidity,
        uint256 volume_preICO,
        uint256 volume_crowdsale,
        uint256 volume_investors,
        uint256 volume_rewards,
        uint256 volume_team,
        uint256 volume_liquidity
    ) public ERC20(name, symbol) ERC20Capped(cap) {
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        // _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // _setupRole(ADMIN_ROLE, msg.sender);
        // Sets `DEFAULT_ADMIN_ROLE` as ``ADMIN_ROLE``'s admin role.
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);

        _mint(Crowdsale, volume_crowdsale.add(volume_preICO));
        _mint(Investors, volume_investors);
        _mint(Rewards, volume_rewards);
        _mint(Team, volume_team);
        _mint(Liquidity, volume_liquidity);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Capped) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
