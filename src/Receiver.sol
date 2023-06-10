// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";
// import {Functions, FunctionsClient} from "../contracts/dev/functions/FunctionsClient.sol";
// import {FunctionsConsumer} from "../contracts/FunctionsConsumer.sol";

// error Receiver__PaymentCaptureFailed();
// error Receiver__SendingPaymentFailed();
// error Receiver__TransactionAndSignatureLengthMismatch();

// contract Receiver {
//     using ECDSA for bytes32;

//     uint64 public subscriptionId;
//     FunctionsConsumer public functionsConsumer;
//     address public otcSwapProtocol;
//     mapping(string => Transaction) public orderIdToTransaction;

//     struct EIP712Domain {
//         string name;
//         string version;
//         uint256 chainId;
//         address verifyingContract;
//     }

//     struct Transaction {
//         address user;
//         uint256 rfsId;
//         address makerAddress;
//         string paypalEmail;
//         uint256 amountToBuy;
//         uint256 nonce;
//     }

//     //HASHES to comply with EIP712
//     bytes32 private constant EIP712_DOMAIN_TYPEHASH =
//         keccak256(
//             "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
//         );
//     bytes32 private constant TRANSACTION_TYPEHASH =
//         keccak256(
//             "Transaction(address user,uint256 rfsId,address makerAddress,string paypalEmail,uint256 amountToBuy,uint256 nonce)"
//         );

//     // Nonces to prevent replay attacks
//     mapping(address => uint256) private nonces;

//     // Domain separator
//     bytes32 private immutable domainSeparator;

//     event TransactionProcessed(address indexed target, address indexed signer);
//     event TransactionInvalidSigner(address indexed target, string reason);
//     event TransactionInvalidNonce(uint256 indexed nonce, string reason);
//     event TransactionInvalidAmount(uint256 indexed amount, string reason);

//     modifier onlyConsumer() {
//         require(
//             msg.sender == address(functionsConsumer),
//             "Only the consumer can call this function"
//         );
//         _;
//     }

//     constructor(
//         uint32 _gasLimit,
//         address _otcSwapProtocol,
//         uint64 _subscriptionId,
//         address _functionsConsumer
//     ) {
//         functionsConsumer = FunctionsConsumer(_functionsConsumer);
//         subscriptionId = _subscriptionId;
//         otcSwapProtocol = _otcSwapProtocol;
//         domainSeparator = keccak256(
//             abi.encode(
//                 EIP712_DOMAIN_TYPEHASH,
//                 keccak256(bytes("OTC Swap Protocol")),
//                 keccak256(bytes("1")),
//                 getChainId(),
//                 address(this)
//             )
//         );
//     }

//     function nonceOf(address user) external view returns (uint256) {
//         return nonces[user];
//     }

//     function getChainId() private view returns (uint256) {
//         uint256 chainId;
//         assembly {
//             chainId := chainid()
//         }
//         return chainId;
//     }

//     function getDomainSeparator() public view returns (bytes32) {
//         return domainSeparator;
//     }

//     /**
//      * @notice Execute a meta transaction
//      * @param transactions The transactions to execute
//      * @param signatures The signatures of the transactions
//      * @dev The transactions and signatures must be in the same order and of the same length
//      * @dev The transactions must be encoded as per the Transaction struct
//      * @dev onlyRelayer can call this function
//      */

//     //Could be added a modifier to check if the sender is a relayer
//     function executeMetaTransaction(
//         bytes[] calldata transactions,
//         bytes[] calldata signatures,
//         bytes[] calldata secrets
//     ) external {
//         //If they are not of the same length, we revert. Using error to lower gas costs and don't store strings in the contract
//         if (transactions.length != signatures.length || transactions.length != secrets.length) {
//             revert Receiver__TransactionAndSignatureLengthMismatch();
//         }

//         for (uint256 i = 0; i < transactions.length; i++) {
//             bytes memory transaction = transactions[i];
//             //Decode the transaction
//             (
//                 address user,
//                 uint256 rfsId,
//                 address makerAddress,
//                 /* TODO order_id */
//                 /* TODO currency */
//                 string memory paypalEmail,
//                 uint256 amountToBuy,
//                 uint256 nonce
//             ) = abi.decode(transaction, (address, uint256, address, string, uint256, uint256));
//             (bytes memory clientId, bytes memory clientSecret) = abi.decode(
//                 secrets[i],
//                 (bytes, bytes)
//             );

//             //Compute the hash of the transaction
//             bytes32 digest = keccak256(
//                 abi.encodePacked(
//                     "\x19\x01",
//                     domainSeparator,
//                     keccak256(
//                         abi.encode(
//                             TRANSACTION_TYPEHASH,
//                             user,
//                             rfsId,
//                             makerAddress,
//                             keccak256(bytes(paypalEmail)),
//                             amountToBuy,
//                             nonce
//                         )
//                     )
//                 )
//             );

//             //Recover the signer
//             address signer = digest.recover(signatures[i]);
//             //Using events to emit errors, since we want to continue processing the rest of the transactions
//             if (signer != user) {
//                 emit TransactionInvalidSigner(signer, "Invalid signer, it doesn't match the user");
//                 continue;
//             }

//             if (nonce != nonces[user]) {
//                 emit TransactionInvalidNonce(nonce, "Invalid nonce");
//                 continue;
//             }
//             capturePayment(
//                 0,
//                 rfsId,
//                 makerAddress,
//                 paypalEmail,
//                 amountToBuy,
//                 "EUR",
//                 nonce,
//                 clientId,
//                 clientSecret
//             );
//         }
//     }

//     function capturePayment(
//         uint256 order_id,
//         uint256 rfsId,
//         address makerAddress,
//         string memory paypalEmail,
//         uint256 amountToBuy,
//         string memory currency,
//         uint256 nonce,
//         bytes memory clientId,
//         bytes memory clientSecret
//     ) internal {
//         string
//             memory source = "const authUrl = 'https://api-m.sandbox.paypal.com/v1/oauth2/token'; const base64 = Buffer.from(`${secrets.clientId}:${secrets.clientSecret}`).toString('base64'); const order_id = args[0]; const body_data = { grant_type: `client_credentials`, }; let formBody = []; for (let property in body_data) { let encodedKey = encodeURIComponent(property); let encodedValue = encodeURIComponent(body_data[property]); formBody.push(encodedKey + `=` + encodedValue); } formBody = formBody.join(`&`); const responseAuthToken = Functions.makeHttpRequest({ url: authUrl, method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded', Accept: 'application/json', 'Accept-Language': 'en_US', Authorization: `Basic ${base64}`, }, data: formBody, }); const { data } = await responseAuthToken; const { access_token } = data; const response = Functions.makeHttpRequest({ url: `https://api-m.sandbox.paypal.com/v2/checkout/orders/${order_id}/capture`, method: 'POST', headers: { 'Content-Type': 'application/json', 'PayPal-Request-Id': '7b92603e-77ed-4896-8f78-5dea2050476a', Authorization: `Bearer ${access_token}`, }, }); const responseData = await response; console.log(responseData); return Functions.encodeString(JSON.stringify(responseData));";

//         bytes32 reqID = functionsConsumer.executeRequest(
//             source,
//             [clientId, clientSecret],
//             [order_id],
//             subscriptionId,
//             300000
//         );

//         if (reqID.length == 0) {
//             revert Receiver__PaymentCaptureFailed();
//         }
//         Transaction memory transaction = Transaction({
//             user: msg.sender,
//             rfsId: rfsId,
//             makerAddress: makerAddress,
//             paypalEmail: paypalEmail,
//             amountToBuy: amountToBuy,
//             currency: currency,
//             nonce: nonce
//         });
//         transactions[order_id] = transaction;
//         sendPayment(clientId, clientSecret, paypalEmail, amountToBuy, currency);
//     }

//     function performSwaps(bytes calldata order_id) public onlyConsumer {
//         Transaction memory transaction = orderIdToTransaction[order_id];

//         otcSwapProtocol.performSwaps(
//             transaction.rfsId,
//             transaction.amountToBuy,
//             transaction.makerAddress
//         );

//         sendPayment(
//             transaction.clientId,
//             transaction.clientSecret,
//             transaction.paypalEmail,
//             transaction.amountToBuy,
//             transaction.currency
//         );
//     }

//     function sendPayment(
//         bytes memory clientId,
//         bytes memory clientSecret,
//         string memory paypalEmail,
//         uint256 amountToBuy,
//         string memory currency
//     ) internal {
//         string
//             memory source = "const authUrl = 'https://api-m.sandbox.paypal.com/v1/oauth2/token'; const base64 = Buffer.from(`${secrets.clientId}:${secrets.clientSecret}`).toString('base64'); const uniqueId = Date.now().toString(); const sender_batch_id = `Payouts_${uniqueId}`; const sender_item_id = `Item_${uniqueId}`; const receiver = args[0]; const amount = args[1]; const currency = args[2]; const body_data = { grant_type: 'client_credentials', }; function sleep(ms) { return new Promise((resolve) => setTimeout(resolve, ms)); }; let formBody = []; for (let property in body_data) { let encodedKey = encodeURIComponent(property); let encodedValue = encodeURIComponent(body_data[property]); formBody.push(encodedKey + '=' + encodedValue); }; formBody = formBody.join('&'); const responseAuthToken = Functions.makeHttpRequest({ url: authUrl, method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded', Accept: 'application/json', 'Accept-Language': 'en_US', Authorization: `Basic ${base64}`, }, data: formBody, }); const { data } = await responseAuthToken; const { access_token } = data; const response = Functions.makeHttpRequest({ url: 'https://api-m.sandbox.paypal.com/v1/payments/payouts', method: 'POST', headers: { 'Content-Type': 'application/json', 'PayPal-Request-Id': '1111103e-77ad-4196-8a78-5dea2050476a', Authorization: `Bearer ${access_token}`, }, data: { sender_batch_header: { sender_batch_id: sender_batch_id, email_subject: 'You have a payout!', email_message: 'You have received a payout! Thanks for using our service!', }, items: [ { recipient_type: 'EMAIL', amount: { value: amount, currency: currency }, note: 'Thanks for your patronage!', sender_item_id: sender_item_id, receiver: receiver, }, ], }, }); const responseData = await response; const { payout_batch_id } = responseData.data.batch_header; let isPaymentSuccess = false; while (true) { const responseBatch = Functions.makeHttpRequest({ url: `https://api-m.sandbox.paypal.com/v1/payments/payouts/${payout_batch_id}`, method: 'GET', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${access_token}`, }, }); const paymentData = await responseBatch; const { batch_status } = paymentData.data.batch_header; if (batch_status == 'SUCCESS') { isPaymentSuccess = true; break; }; await sleep(2000); }; if (!isPaymentSuccess) { throw new Error('Payment failed'); }; return Functions.encodeString(JSON.stringify(responseData));";

//         bytes32 reqID = functionsConsumer.executeRequest(
//             source,
//             [clientId, clientSecret],
//             [paypalEmail, amountToBuy, currency],
//             subscriptionId,
//             300000
//         );

//         if (response.length == 0) {
//             revert Receiver__SendingPaymentFailed();
//         }
//     }

//     //PLACEHOLDER, but should call the OTC Swap Protocol to perform the swap
//     function performTask(uint256 rfsId, address makerAddress, uint256 amountToBuy) internal {
//         emit TransactionProcessed(makerAddress, address(this));
//     }
// }
