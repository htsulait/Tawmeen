// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ChangeNotice.sol";

// Reuse the interfaces defined in ChangeNotice.sol (IBatchRegistry, IMerkleAnchor)

// Simple mock that satisfies IBatchRegistry for ChangeNotice
contract MockBatchRegistry is IBatchRegistry {
    function getBatchState(string memory) external pure override returns (uint8) {
        // Just return some dummy state; ChangeNotice only cares that the call works.
        return 0;
    }
}

// Simple mock that satisfies IMerkleAnchor for ChangeNotice
contract MockMerkleAnchor is IMerkleAnchor {
    event RootSubmitted(string batchId, bytes32 root);

    function submitRoot(string memory batchId, bytes32 root) external override {
        emit RootSubmitted(batchId, root);
    }

    function getRoot(string memory) external pure override returns (bytes32) {
        return bytes32(0);
    }

    function verifyRoot(string memory, bytes32) external pure override returns (bool) {
        return true;
    }
}

contract ChangeNoticeGasTest is Test {
    ChangeNotice public notice;
    MockBatchRegistry public batchRegistry;
    MockMerkleAnchor public merkle;

    address owner     = address(0x1);
    address regulator = address(0x2);
    address supplier  = address(0x3);
    address retailer  = address(0x4);

    function setUp() public {
        // Deploy mocks
        batchRegistry = new MockBatchRegistry();
        merkle = new MockMerkleAnchor();

        // Deploy ChangeNotice as owner
        vm.prank(owner);
        notice = new ChangeNotice(
            address(batchRegistry),
            regulator,
            address(merkle)
        );

        // Set roles so we can call the functions
        vm.prank(owner);
        notice.setSupplier(supplier, true);

        vm.prank(owner);
        notice.setRetailer(retailer, true);
    }

    /// Gas for creating a notice
    function testGas_createNotice() public {
        vm.prank(supplier);
        notice.createNotice(
            "batch-123",
            ChangeNotice.NoticeType.CompositionChange,
            ChangeNotice.Severity.Major,
            uint48(block.timestamp),
            "summary",
            "ipfs://details",
            bytes32(uint256(1))
        );
    }

    /// Gas for create + submit + approve
    function testGas_submitApprove() public {
        vm.startPrank(supplier);
        uint256 id = notice.createNotice(
            "batch-123",
            ChangeNotice.NoticeType.CompositionChange,
            ChangeNotice.Severity.Major,
            uint48(block.timestamp),
            "summary",
            "ipfs://details",
            bytes32(uint256(1))
        );
        notice.submit(id);
        vm.stopPrank();

        vm.prank(regulator);
        notice.approve(id, "looks good");
    }

    /// Gas for create + approve + acknowledge
    function testGas_acknowledge() public {
        vm.startPrank(supplier);
        uint256 id = notice.createNotice(
            "batch-123",
            ChangeNotice.NoticeType.CompositionChange,
            ChangeNotice.Severity.Major,
            uint48(block.timestamp),
            "summary",
            "ipfs://details",
            bytes32(uint256(1))
        );
        notice.submit(id);
        vm.stopPrank();

        vm.prank(regulator);
        notice.approve(id, "ok");

        vm.prank(retailer);
        notice.acknowledge(id);
    }
}
