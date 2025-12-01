// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBatchRegistry {
    function getBatchState(string memory batchId) external view returns (uint8);
}

interface IChangeNotice {
    function isNoticeApproved(uint256 noticeId) external view returns (bool);
}

contract MerkleAnchor {
    //matching batchId's to merkle roots 
    mapping(string => bytes32) public batchRoots;
    address public owner;
    
    IBatchRegistry public batchRegistry;
    IChangeNotice public changeNotice;

    //registers batch that gets logged to the blockchain
    event RootSubmitted(string indexed batchId, bytes32 root);

    //check if function is called by owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _; 
        }

    //runs when the contract is deployed (deployer = owner)
    constructor(address _batchRegistry, address _changeNotice) {
        owner = msg.sender;
        batchRegistry = IBatchRegistry(_batchRegistry);
        changeNotice = IChangeNotice(_changeNotice);
    }

    //owner submitting merkle root for batch
    function submitRoot(string memory batchId, bytes32 root) public onlyOwner {
        require(root != bytes32(0), "Root cannot be zero");
        batchRoots[batchId] = root;
        //logs the event to the blockchain 
        emit RootSubmitted(batchId, root);
    }

    //read only function for the root for a batch 
    function getRoot(string memory batchId) public view returns (bytes32) {
        return batchRoots[batchId];
    }

    //check if proposed root matches stored root 
    function verifyRoot(string memory batchId, bytes32 proposedRoot) public view returns (bool) {
        return batchRoots[batchId] == proposedRoot;
    }
}