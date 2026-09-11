// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ArcGift is ReentrancyGuard {
    IERC20 public immutable usdc;

    uint256 public nextGiftId;

    struct Gift {
        address sender;
        uint256 amount;
        uint256 expiry;
        bool claimed;
        bool refunded;
    }

    mapping(uint256 => Gift) public gifts;

    event GiftCreated(
        uint256 indexed giftId,
        address indexed sender,
        uint256 amount,
        uint256 expiry
    );

    event GiftClaimed(
        uint256 indexed giftId,
        address indexed receiver,
        uint256 amount
    );

    event GiftRefunded(
        uint256 indexed giftId,
        address indexed sender,
        uint256 amount
    );

    constructor(address _usdc) {
        require(_usdc != address(0), "Invalid USDC address");
        usdc = IERC20(_usdc);
    }

    function createGift(
        uint256 amount,
        uint256 expiry
    ) external nonReentrant returns (uint256 giftId) {
        require(amount > 0, "Amount must be greater than zero");
        require(expiry > block.timestamp, "Expiry must be in the future");

        require(
            usdc.transferFrom(msg.sender, address(this), amount),
            "USDC transfer failed"
        );

        giftId = nextGiftId++;

        gifts[giftId] = Gift({
            sender: msg.sender,
            amount: amount,
            expiry: expiry,
            claimed: false,
            refunded: false
        });

        emit GiftCreated(
            giftId,
            msg.sender,
            amount,
            expiry
        );
    }

    function claimGift(uint256 giftId)
        external
        nonReentrant
    {
        Gift storage gift = gifts[giftId];

        require(gift.amount > 0, "Gift does not exist");
        require(!gift.claimed, "Gift already claimed");
        require(!gift.refunded, "Gift already refunded");
        require(block.timestamp < gift.expiry, "Gift has expired");

        gift.claimed = true;

        require(
            usdc.transfer(msg.sender, gift.amount),
            "USDC transfer failed"
        );

        emit GiftClaimed(
            giftId,
            msg.sender,
            gift.amount
        );
    }

    function refundGift(uint256 giftId)
        external
        nonReentrant
    {
        Gift storage gift = gifts[giftId];

        require(gift.amount > 0, "Gift does not exist");
        require(msg.sender == gift.sender, "Not the sender");
        require(!gift.claimed, "Gift already claimed");
        require(!gift.refunded, "Gift already refunded");
        require(block.timestamp >= gift.expiry, "Gift not expired");

        gift.refunded = true;

        require(
            usdc.transfer(gift.sender, gift.amount),
            "USDC transfer failed"
        );

        emit GiftRefunded(
            giftId,
            gift.sender,
            gift.amount
        );
    }
}
