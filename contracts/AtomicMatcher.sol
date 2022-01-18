pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AtomicMatcher is Ownable {

  using ECDSA for bytes32;

  event OrderMatched(Order order);

  address public feeTakerAddress1 = 0xFbc147659f5297983D2fBdf6C6aE45Ae9ceCF2E9;
  address public feeTakerAddress2 = 0x2e11d23151e595211e63D2724764477B0F4Fad1E;
  address public feeTakerAddress3 = 0x9987605c8741d945098D7D6ba30bC41ACc1B821e;

  address private backendAddress;

  modifier onlyBackend() {
    require(msg.sender == backendAddress, "msg.sender is not backend");
    _;
  }

  IERC20 public paymentToken;

  struct Order {
    address creator;
    uint8 creatorReward;
    address maker;
    address taker;
    bool isFixedPrice;
    uint256 price;
    uint256 extra;
    uint256 itemId;
    IERC721 itemContract;
  }

  constructor(IERC20 _paymentToken, address _backendAddress) {
    paymentToken = _paymentToken;
    backendAddress = _backendAddress;
  }

  function changeAddresses(address _feeTakerAddress1, address _feeTakerAddress2, address _feeTakerAddress3, address _backendAddress) public onlyOwner {
    feeTakerAddress1 = _feeTakerAddress1;
    feeTakerAddress2 = _feeTakerAddress2;
    feeTakerAddress3 = _feeTakerAddress3;
    backendAddress = _backendAddress;
  }

  function atomicMatch(Order memory order, bytes memory buyerSignature, bytes memory sellerSignature) onlyBackend public {
    require(order.maker != address(0), "Invalid maker");
    require(order.taker != address(0), "Invalid taker");
    require(order.price != 0, "Invalid price");
    require(order.creatorReward <= 15, "Invalid creator reward");
    
    if (!order.isFixedPrice) {
      require(order.extra != 0, "Invalid extra");
    }

    bytes32 sellerEthSignedMessageHash = keccak256(
      abi.encodePacked(order.maker, order.isFixedPrice, order.price, order.itemId, order.itemContract)
    );

    bytes32 buyerEthSignedMessageHash = keccak256(
      abi.encodePacked(order.taker, order.isFixedPrice, order.price, order.extra, order.itemId, order.itemContract)
    );

    // Signatures check
    require(recoverSigner(sellerEthSignedMessageHash, sellerSignature) == order.maker, "Invalid seller signature");
    require(recoverSigner(buyerEthSignedMessageHash, buyerSignature) == order.taker, "Invalid buyer signature");

    // Transfers
    distributeFunds(order);

    emit OrderMatched(order);
  }

  function recoverSigner(bytes32 dataHash, bytes memory signature) internal pure returns (address) {
    return dataHash.toEthSignedMessageHash().recover(signature);
  }

  function isOrderCreatorProvided(address providedCreator, address providedMaker) internal pure returns (bool) {
    return providedCreator != address(0) && providedCreator != providedMaker;
  }

  function getMakerAndCreatorRewards(Order memory order) internal pure returns (uint256 _creatorFee, uint256 _makerFee) {
    uint256 orderFullPrice = order.price + order.extra;
    _creatorFee = isOrderCreatorProvided(order.creator, order.maker) ? (orderFullPrice * order.creatorReward * 100 / 10000) : 0;
    _makerFee = orderFullPrice - _creatorFee;
  }

  function distributeFunds(Order memory order) internal {
    uint256 orderFullPrice = order.price + order.extra;
    uint256 creatorFee = isOrderCreatorProvided(order.creator, order.maker) ? (orderFullPrice * order.creatorReward * 100 / 10000) : 0;

    uint256 fee1 = (order.price + order.extra) * 300 / 10000; // fee 1
    uint256 fee2 = (order.price + order.extra) * 300 / 10000; // fee 2
    uint256 fee3 = (order.price + order.extra) * 400 / 10000; // fee 3

    uint256 makerFee = orderFullPrice - creatorFee - fee1 - fee2 - fee3;

    order.itemContract.transferFrom(order.maker, order.taker, order.itemId);

    if (isOrderCreatorProvided(order.creator, order.maker)) {
      paymentToken.transferFrom(order.taker, order.creator, creatorFee); // Creator fee
    }

    // Other distribution
    paymentToken.transferFrom(order.taker, order.maker, makerFee);
    paymentToken.transferFrom(order.taker, feeTakerAddress1, fee1);
    paymentToken.transferFrom(order.taker, feeTakerAddress2, fee2);
    paymentToken.transferFrom(order.taker, feeTakerAddress3, fee3);
  }
}