// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Wallet {
    struct Transfer {
        uint amount;
        address payable to;
        address from;
        uint approvalCount;
        bool hasBeenSent;
        uint id;
    }

    Transfer[] transferLog;

    //Set in constructor
    address[] public owners;
    uint approvalsRequired;

    //Keeps track of whether owner has approved a transaction
    mapping(address => mapping(uint => bool)) approvals;

    event Deposit(uint amount, address from);
    event TransferRequestReceived(address from, address to, uint amount, uint id);
    event ApprovalReceived(address approver, uint id, uint approvalCount);
    event TransferCompleted(address from, address to, uint amount, uint id);

    //Only callable by owners (set in constructor)
    modifier onlyOwners {
        bool owner = false;

        //Check if msg.sender is in the owners array
        for(uint i = 0; i <= owners.length; i++) {
            if(owners[i] == msg.sender){
                owner = true;
            }
        }
        require(owner = true, "You are not authorized for this transaction");
        _;
    }

    constructor(address[] memory _owners, uint _approvalsRequired){
        owners = _owners;
        approvalsRequired = _approvalsRequired;
    }

    function deposit() public payable {
        emit Deposit(msg.value, msg.sender);
    }

    function requestTransfer(address payable _to, uint _amount) public onlyOwners {
        //Make new transfer instance
        Transfer memory newTransferRequest = Transfer(_amount, _to, msg.sender, 0, false, transferLog.length);
        //Push to log
        transferLog.push(newTransferRequest);
        //Emit event
        emit TransferRequestReceived(msg.sender, _to, _amount, transferLog.length);
    }

    function getTransfer(uint _index) public view returns(Transfer memory){
        return transferLog[_index];
    }

    function approve(uint _index) public onlyOwners {
        require(msg.sender != transferLog[_index].from, "You cannot approve your own transaction request");
        require(approvals[msg.sender][_index] == false, "You have already approved this transaction");
        require(transferLog[_index].hasBeenSent == false, "This transaction was already approved and sent");

        //Increase approval count
        transferLog[_index].approvalCount++;
        //Log msg.sender as having approved (so cannot do it again-- see require above)
        approvals[msg.sender][_index] = true;

        emit ApprovalReceived(msg.sender, _index, transferLog[_index].approvalCount++);

        if (transferLog[_index].approvalCount >= approvalsRequired) {
            //Send transfer
            transferLog[_index].to.transfer(transferLog[_index].amount);
            //Set instance to has been sent
            transferLog[_index].hasBeenSent = true;
            //emit event
            emit TransferCompleted(transferLog[_index].from, transferLog[_index].to, transferLog[_index].amount, transferLog[_index].id);
         }
    }
}