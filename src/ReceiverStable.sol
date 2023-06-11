// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

error Receiver__TransactionAndSignatureLengthMismatch();

contract Receiver {
    using ECDSA for bytes32;

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct Transaction {
        address user;
        uint256 rfsId;
        address makerAddress;
        string paypalEmail;
        uint256 amountToBuy;
        uint256 nonce;
    }

    //HASHES to comply with EIP712
    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 private constant TRANSACTION_TYPEHASH =
        keccak256(
            "Transaction(address user,uint256 rfsId,address makerAddress,string paypalEmail,uint256 amountToBuy,uint256 nonce)"
        );

    address public relayer;
    address public owner;

    // Nonces to prevent replay attacks
    mapping(address => uint256) private nonces;

    // Domain separator
    bytes32 private immutable domainSeparator;

    event TransactionProcessed(address indexed target, address indexed signer);
    event TransactionInvalidSigner(address indexed target, string reason);
    event TransactionInvalidNonce(uint256 indexed nonce, string reason);
    event TransactionInvalidAmount(uint256 indexed amount, string reason);

    modifier onlyRelayer() {
        require(msg.sender == relayer, "Only relayer can call this function");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
        domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("OTC Swap Protocol")),
                keccak256(bytes("1")),
                getChainId(),
                address(this)
            )
        );
    }

    function nonceOf(address user) external view returns (uint256) {
        return nonces[user];
    }

    function getChainId() private view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function getDomainSeparator() public view returns (bytes32) {
        return domainSeparator;
    }

    function setRelayer(address _relayer) external onlyOwner {
        relayer = _relayer;
    }

    /**
     * @notice Execute a meta transaction
     * @param transactions The transactions to execute
     * @param signatures The signatures of the transactions
     * @dev The transactions and signatures must be in the same order and of the same length
     * @dev The transactions must be encoded as per the Transaction struct
     * @dev onlyRelayer can call this function
     */

    //Could be added a modifier to check if the sender is a relayer
    function executeMetaTransaction(
        bytes[] calldata transactions,
        bytes[] calldata signatures
    ) external onlyRelayer {
        //If they are not of the same length, we revert. Using error to lower gas costs and don't store strings in the contract
        if (transactions.length != signatures.length) {
            revert Receiver__TransactionAndSignatureLengthMismatch();
        }

        for (uint256 i = 0; i < transactions.length; i++) {
            bytes memory transaction = transactions[i];
            //Decode the transaction
            (
                address user,
                uint256 rfsId,
                address makerAddress,
                string memory paypalEmail,
                uint256 amountToBuy,
                uint256 nonce
            ) = abi.decode(transaction, (address, uint256, address, string, uint256, uint256));

            //Compute the hash of the transaction
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            TRANSACTION_TYPEHASH,
                            user,
                            rfsId,
                            makerAddress,
                            keccak256(bytes(paypalEmail)),
                            amountToBuy,
                            nonce
                        )
                    )
                )
            );

            //Recover the signer
            address signer = digest.recover(signatures[i]);
            //Using events to emit errors, since we want to continue processing the rest of the transactions
            if (signer != user) {
                emit TransactionInvalidSigner(signer, "Invalid signer, it doesn't match the user");
                continue;
            }

            if (nonce != nonces[user]) {
                emit TransactionInvalidNonce(nonce, "Invalid nonce");
                continue;
            }
        }
    }
}
