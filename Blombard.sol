// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Blombard is ERC20, Ownable {
    bool public airdropStart;
    using SafeERC20 for IERC20;
    mapping(address => uint256) private _airdroppedTokens;

    constructor(
        address initialOwner
    ) ERC20("Blombard", "BLM") Ownable(initialOwner) {
        _mint(msg.sender, 9000000000 * 10 ** decimals());
    }

    function airdrop(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(recipients.length == amounts.length, "Mismatched arrays");
        for (uint256 i = 0; i < recipients.length; i++) {
            _airdroppedTokens[recipients[i]] += amounts[i];
            _transfer(msg.sender, recipients[i], amounts[i]);
        }
    }

    function setSellable() external onlyOwner {
        airdropStart = !airdropStart;
    }

    function withdrawStuckTokens(address token) public onlyOwner {
        uint256 amount;
        if (token == address(0)) {
            bool success;
            amount = address(this).balance;
            (success, ) = address(_msgSender()).call{value: amount}("");
        } else {
            amount = IERC20(token).balanceOf(address(this));
            require(amount > 0, "HideCoin: No tokens");
            IERC20(token).safeTransfer(_msgSender(), amount);
        }
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20) {
        if (from != address(0) && to != address(0) && !airdropStart) {
            uint256 transferable = balanceOf(from) - _airdroppedTokens[from];
            require(
                value <= transferable,
                "Airdropped tokens are not sellable yet"
            );
        }
        super._update(from, to, value);
    }
}
