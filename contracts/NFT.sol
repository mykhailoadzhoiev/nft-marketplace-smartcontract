pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTContract is ERC721, Ownable {

  /* events */
  event TokensMined(uint256[] _tokenIds);

  address private backendAddress;

  modifier onlyBackend() {
    require(msg.sender == backendAddress, "msg.sender is not backend");
    _;
  }

  /* storage */
  uint256 public totalSupply = 0;
  string public tokenBasicURI;

  /* methods */
  constructor (
    string memory _name,
    string memory _symbol,
    address _backendAddress
  ) ERC721(_name, _symbol) {
    backendAddress = _backendAddress;
  }

  function _baseURI() internal view override returns (string memory) {
    return this.tokenBasicURI();
  }

  function changeBasicURI(string memory _newURI) public onlyOwner {
    tokenBasicURI = _newURI;
  }

  function changeBackendAddress(address _backendAddress) public onlyOwner {
    backendAddress = _backendAddress;
  }

  function mint(uint256 amount, address to) public onlyBackend {
    uint256[] memory tokenIds = new uint256[](amount);
    for (uint i=0; i<amount; i++) {
      _safeMint(to, totalSupply);
      tokenIds[i] = totalSupply;
      totalSupply++;
    }

    emit TokensMined(tokenIds);
  }
}