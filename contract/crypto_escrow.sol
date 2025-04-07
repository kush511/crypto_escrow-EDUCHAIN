// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CryptoEscrow {
    enum EscrowState { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, REFUNDED }

    struct Escrow {
        address payable buyer;
        address payable seller;
        uint256 amount;
        EscrowState state;
    }

    uint256 public escrowCounter = 0;
    mapping(uint256 => Escrow) public escrows;

    event EscrowCreated(uint256 indexed escrowId, address indexed buyer, address indexed seller, uint256 amount);
    event PaymentConfirmed(uint256 indexed escrowId);
    event OrderDelivered(uint256 indexed escrowId);
    event RefundIssued(uint256 indexed escrowId);

    modifier onlyBuyer(uint256 _escrowId) {
        require(msg.sender == escrows[_escrowId].buyer, "Only buyer can perform this action");
        _;
    }

    modifier onlySeller(uint256 _escrowId) {
        require(msg.sender == escrows[_escrowId].seller, "Only seller can perform this action");
        _;
    }

    modifier inState(uint256 _escrowId, EscrowState _state) {
        require(escrows[_escrowId].state == _state, "Invalid escrow state for this action");
        _;
    }

    function createEscrow(address payable _seller) external payable {
        require(msg.value > 0, "Escrow amount must be greater than 0");
        escrows[escrowCounter] = Escrow(payable(msg.sender), _seller, msg.value, EscrowState.AWAITING_DELIVERY);
        emit EscrowCreated(escrowCounter, msg.sender, _seller, msg.value);
        escrowCounter++;
    }

    function confirmDelivery(uint256 _escrowId) external onlyBuyer(_escrowId) inState(_escrowId, EscrowState.AWAITING_DELIVERY) {
        escrows[_escrowId].state = EscrowState.COMPLETE;
        escrows[_escrowId].seller.transfer(escrows[_escrowId].amount);
        emit OrderDelivered(_escrowId);
    }

    function refundBuyer(uint256 _escrowId) external onlySeller(_escrowId) inState(_escrowId, EscrowState.AWAITING_DELIVERY) {
        escrows[_escrowId].state = EscrowState.REFUNDED;
        escrows[_escrowId].buyer.transfer(escrows[_escrowId].amount);
        emit RefundIssued(_escrowId);
    }

    function getEscrowDetails(uint256 _escrowId) public view returns (
        address buyer,
        address seller,
        uint256 amount,
        EscrowState state
    ) {
        Escrow memory e = escrows[_escrowId];
        return (e.buyer, e.seller, e.amount, e.state);
    }
}
