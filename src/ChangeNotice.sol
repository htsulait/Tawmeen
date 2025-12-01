// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBatchRegistry {
    function getBatchState(string memory batchId) external view returns (uint8);
}

interface IMerkleAnchor {
    function submitRoot(string memory batchId, bytes32 root) external;
    function getRoot(string memory batchId) external view returns (bytes32);
    function verifyRoot(string memory batchId, bytes32 proposedRoot) external view returns (bool);
}

contract ChangeNotice {
    address public owner;
    address public regulator;

    mapping(address => bool) public isSupplier;
    mapping(address => bool) public isRetailer;

    modifier onlyOwner() {
    _onlyOwner();
    _;
}

function _onlyOwner() internal view {
    require(msg.sender == owner, "Not owner");
}

modifier onlyRegulator() {
    _onlyRegulator();
    _;
}

function _onlyRegulator() internal view {
    require(msg.sender == regulator, "Not regulator");
}

modifier onlySupplier() {
    _onlySupplier();
    _;
}

function _onlySupplier() internal view {
    require(isSupplier[msg.sender], "Not supplier");
}

modifier onlyRetailer() {
    _onlyRetailer();
    _;
}

function _onlyRetailer() internal view {
    require(isRetailer[msg.sender], "Not retailer");
}


    IBatchRegistry public batchRegistry;
    IMerkleAnchor public merkleAnchor;

    enum NoticeType { CompositionChange, LabelingChange, ProcessChange, SupplierChange, SafetyAdvisory, Other }
    enum Severity { Minor, Major, Critical }
    enum Status { Draft, Submitted, Approved, Rejected, Superseded, Closed }

    struct Notice {
        uint256 id;
        string batchId;
        address createdBy;
        uint48 createdAt;
        NoticeType noticeType;
        Severity severity;
        Status status;
        uint48 effectiveFrom;
        string summary;
        string detailsURI;
        bytes32 anchor;
        string regulatorNote;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Notice) public notices;
    mapping(string => uint256[]) private noticesByBatch;
    mapping(uint256 => mapping(address => bool)) public acknowledged;
    mapping(uint256 => uint256) public ackCount;

    event RoleUpdated(string role, address indexed account, bool enabled);
    event RegulatorChanged(address indexed newRegulator);
    event NoticeCreated(uint256 indexed id, string indexed batchId, address indexed by);
    event NoticeSubmitted(uint256 indexed id, string indexed batchId);
    event NoticeApproved(uint256 indexed id, string indexed batchId, string regulatorNote);
    event NoticeRejected(uint256 indexed id, string indexed batchId, string regulatorNote);
    event NoticeSuperseded(uint256 indexed id, string indexed batchId, uint256 byNoticeId);
    event NoticeClosed(uint256 indexed id, string indexed batchId, string regulatorNote);
    event NoticeAcknowledged(uint256 indexed id, address indexed by);
    event AnchorPushed(uint256 indexed id, string indexed batchId, bytes32 anchor);

    constructor(address _batchRegistry, address _regulator, address _merkleAnchor) {
        require(_batchRegistry != address(0), "batchRegistry=0");
        require(_regulator != address(0), "regulator=0");
        owner = msg.sender;
        regulator = _regulator;
        batchRegistry = IBatchRegistry(_batchRegistry);
        merkleAnchor = _merkleAnchor == address(0) ? IMerkleAnchor(address(0)) : IMerkleAnchor(_merkleAnchor);
    }

    function setRegulator(address _regulator) external onlyOwner {
        require(_regulator != address(0), "regulator=0");
        regulator = _regulator;
        emit RegulatorChanged(_regulator);
    }

    function setSupplier(address account, bool enabled) external onlyOwner {
        isSupplier[account] = enabled;
        emit RoleUpdated("SUPPLIER", account, enabled);
    }

    function setRetailer(address account, bool enabled) external onlyOwner {
        isRetailer[account] = enabled;
        emit RoleUpdated("RETAILER", account, enabled);
    }

    function setMerkleAnchor(address _merkleAnchor) external onlyOwner {
        merkleAnchor = _merkleAnchor == address(0) ? IMerkleAnchor(address(0)) : IMerkleAnchor(_merkleAnchor);
    }

    function noticesForBatch(string calldata batchId) external view returns (uint256[] memory) {
        return noticesByBatch[batchId];
    }

    function _now() internal view returns (uint48) { return uint48(block.timestamp); }

    function createNotice(
        string calldata batchId,
        NoticeType noticeType,
        Severity severity,
        uint48 effectiveFrom,
        string calldata summary,
        string calldata detailsURI,
        bytes32 anchor
    ) external onlySupplier returns (uint256 id) {
        batchRegistry.getBatchState(batchId);
        require(bytes(summary).length > 0, "Empty summary");
        id = nextId++;
        Notice storage n = notices[id];
        n.id = id;
        n.batchId = batchId;
        n.createdBy = msg.sender;
        n.createdAt = _now();
        n.noticeType = noticeType;
        n.severity = severity;
        n.status = Status.Draft;
        n.effectiveFrom = effectiveFrom;
        n.summary = summary;
        n.detailsURI = detailsURI;
        n.anchor = anchor;
        noticesByBatch[batchId].push(id);
        emit NoticeCreated(id, batchId, msg.sender);
    }

    function submit(uint256 id) external onlySupplier {
        Notice storage n = notices[id];
        require(n.id == id && n.createdBy == msg.sender && n.status == Status.Draft, "Invalid");
        n.status = Status.Submitted;
        emit NoticeSubmitted(id, n.batchId);
    }

    function approve(uint256 id, string calldata regulatorNote) external onlyRegulator {
        Notice storage n = notices[id];
        require(n.id == id && n.status == Status.Submitted, "Invalid");
        n.status = Status.Approved;
        n.regulatorNote = regulatorNote;
        if (address(merkleAnchor) != address(0) && n.anchor != bytes32(0)) {
            merkleAnchor.submitRoot(n.batchId, n.anchor);
            emit AnchorPushed(id, n.batchId, n.anchor);
        }
        emit NoticeApproved(id, n.batchId, regulatorNote);
    }

    function reject(uint256 id, string calldata regulatorNote) external onlyRegulator {
        Notice storage n = notices[id];
        require(n.id == id && n.status == Status.Submitted, "Invalid");
        n.status = Status.Rejected;
        n.regulatorNote = regulatorNote;
        emit NoticeRejected(id, n.batchId, regulatorNote);
    }

    function supersede(uint256 id, uint256 byNoticeId) external onlyRegulator {
        Notice storage n = notices[id];
        require(n.id == id && n.status == Status.Approved && notices[byNoticeId].id == byNoticeId, "Invalid");
        n.status = Status.Superseded;
        emit NoticeSuperseded(id, n.batchId, byNoticeId);
    }

    function close(uint256 id, string calldata regulatorNote) external onlyRegulator {
        Notice storage n = notices[id];
        require(n.id == id && n.status != Status.Closed, "Invalid");
        n.status = Status.Closed;
        n.regulatorNote = regulatorNote;
        emit NoticeClosed(id, n.batchId, regulatorNote);
    }

    function acknowledge(uint256 id) external onlyRetailer {
        Notice storage n = notices[id];
        require(n.id == id && n.status == Status.Approved && !acknowledged[id][msg.sender], "Invalid");
        acknowledged[id][msg.sender] = true;
        unchecked { ackCount[id] += 1; }
        emit NoticeAcknowledged(id, msg.sender);
    }

    function isNoticeApproved(uint256 id) external view returns (bool) {
        Notice storage n = notices[id];
        return (n.id == id && n.status == Status.Approved);
    }

    function isEffective(uint256 id) external view returns (bool) {
        Notice storage n = notices[id];
        require(n.id == id, "Missing");
        return (n.status == Status.Approved && block.timestamp >= n.effectiveFrom);
    }

    function getNotice(uint256 id) external view returns (Notice memory n, uint256 acknowledgements) {
        require(notices[id].id == id, "Missing");
        return (notices[id], ackCount[id]);
    }

    function anchorVerifiedOnMerkle(uint256 id) external view returns (bool) {
        Notice storage n = notices[id];
        require(n.id == id, "Missing");
        if (address(merkleAnchor) == address(0) || n.anchor == bytes32(0)) return false;
        return merkleAnchor.verifyRoot(n.batchId, n.anchor);
    }
}
