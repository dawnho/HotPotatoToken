pragma solidity ^0.4.18; // solhint-disable-line
import "zeppelin-solidity/contracts/math/SafeMath.sol"; // solhint-disable-line


/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
contract ERC721 {
  // Required methods
  function approve(address _to, uint256 _tokenId) public;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint256 _tokenId) public view returns (address addr);
  function takeOwnership(uint256 _tokenId) public;
  function totalSupply() public view returns (uint256 total);
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;

  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Approval(address indexed owner, address indexed approved, uint256 amount);

  // Optional
  // function name() public view returns (string name);
  // function symbol() public view returns (string symbol);
  // function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
  // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}


contract CelebrityToken is ERC721 {

  /// @notice Name and symbol of the non fungible token, as defined in ERC721.
  string public constant name = "CryptoCelebrities"; // solhint-disable-line
  string public constant symbol = "CelebrityToken"; // solhint-disable-line

  /// @dev A mapping from person IDs to the address that owns them. All persons have
  ///  some valid owner address, even gen0 persons are created with a non-zero owner.
  mapping (uint256 => address) public personIndexToOwner;

  // @dev A mapping from owner address to count of tokens that address owns.
  //  Used internally inside balanceOf() to resolve ownership count.
  mapping (address => uint256) private ownershipTokenCount;

  /// @dev A mapping from PersonIDs to an address that has been approved to call
  ///  transferFrom(). Each Person can only have one approved address for transfer
  ///  at any time. A zero value means no approval is outstanding.
  mapping (uint256 => address) public personIndexToApproved;

  /* struct Person {
    uint32 productID;
    address owner;
  }

  Person[] persons; */

  uint256 private _totalSupply;
  uint256 private _theTokenId;

  uint256 public sellingPrice;

  uint256 private stepLimit;

  // The addresses of the accounts (or contracts) that can execute actions within each roles.
  address public ceoAddress;
  address public ctoAddress;

  // Allowed to transfer to this address
  address private approved = address(0);

  event Transfer(address indexed from, address indexed to, uint256 amount);


  /// @dev Access modifier for CEO-only functionality
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

  /// @dev Access modifier for CTO-only functionality
  modifier onlyCTO() {
    require(msg.sender == ctoAddress);
    _;
  }

  /// Access modifier for contract owner only functionality
  modifier onlyCLevel() {
    require(
      msg.sender == ceoAddress ||
      msg.sender == ctoAddress
    );
    _;
  }

    /// Access modifier for token owner only functionality
  modifier onlyTokenOwner(uint256 _tokenId) {
    require(msg.sender == personIndexToOwner[_tokenId]);
    _;
  }

  // Constructor
  function CelebrityToken(uint256 initialPrice, uint256 sLimit) public {

    ceoAddress = msg.sender;
    ctoAddress = msg.sender;

    stepLimit = sLimit;

    sellingPrice = initialPrice;

  }

  // Allows someone to send ether and obtain the token
  function() public payable {
    address oldOwner = address(0); //FIGURE OUT NEW WAY
    address newOwner = msg.sender;

    // Making sure token owner is not sending to self
    require(oldOwner != newOwner);

    // Safety check to prevent against an unexpected 0x0 default.
    require(notNullToAddress(newOwner));

    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= sellingPrice);

    uint256 payment = SafeMath.div(SafeMath.mul(sellingPrice, 94), 100);

    // Update prices

    if (sellingPrice >= stepLimit) {
      sellingPrice = SafeMath.div(SafeMath.mul(sellingPrice, 120), 94); //adding commission amount //1.2/(1-0.06)
    } else {
      sellingPrice = SafeMath.div(SafeMath.mul(sellingPrice, 200), 94); //adding commission amount
    }

    /* transferToken(oldOwner, newOwner, _tokenId); */

    // Pay previous tokenOwner
    oldOwner.transfer(payment); //(1-0.06)

    // Pay commission to owner
    if (this.balance > 0.5 ether) {
      _payout(ceoAddress);
    }
  }

  /// @notice Grant another address the right to transfer token via takeOwnership() and transferFrom().
  /// @param _to The address to be granted transfer approval. Pass address(0) to
  ///  clear all approvals.
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function approve(
    address _to,
    uint256 _tokenId
  ) public onlyTokenOwner(_tokenId) {
    // Owner cannot grant approval to self.
    require(msg.sender != _to);

    // Check whether token ID is on record.
    require(tokenIdValid(_tokenId));

    personIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

  /// For querying balance of a particular account
  /// @param _owner The address for balance query
  /// @dev Required for ERC-721 compliance.
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

  function implementsERC721() public pure returns (bool) {
    return true;
  }

  /// For querying owner of token
  /// @param _tokenId The tokenID for owner inquiry
  /// @dev Required for ERC-721 compliance.
  function ownerOf(uint256 _tokenId)
    public
    view
    returns (address addr)
  {
    require(tokenIdValid(_tokenId));
    return personIndexToOwner[_tokenId];
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

  /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
  /// @param _newCEO The address of the new CEO
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));

    ceoAddress = _newCEO;
  }

  /// @dev Assigns a new address to act as the CTO. Only available to the current CTO.
  /// @param _newCTO The address of the new CTO
  function setCTO(address _newCTO) public onlyCTO {
    require(_newCTO != address(0));

    ctoAddress = _newCTO;
  }

  /// @notice Allow pre-approved user to take ownership of a token
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = personIndexToOwner[_tokenId];

    // Safety check to prevent against an unexpected 0x0 default.
    require(notNullToAddress(newOwner));

    // Safety check to ensure token ID is correct
    require(tokenIdValid(_tokenId));

    // Making sure transfer is approved
    require(isApproved(newOwner));

    // Making sure token owner is not sending to self
    require(newOwner != oldOwner);

    transferToken(oldOwner, newOwner, _tokenId);
  }

  /// For querying totalSupply of token
  /// @dev Required for ERC-721 compliance.
  function totalSupply() public view returns (uint256 total) {
    return persons.length - 1;
  }

  /// Owner initates the transfer of the token to another account
  /// @param _to The address for the token to be transferred to.
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function transfer(
    address _to,
    uint256 _tokenId
  ) public  onlyTokenOwner(_tokenId) {
    require(tokenIdValid(_tokenId));
    require(notNullToAddress(_to));

    transferToken(msg.sender, _to, _tokenId);
  }

  /// Third-party initiates transfer of token from address _from to address _to
  /// @param _from The address for the token to be transferred from.
  /// @param _to The address for the token to be transferred to.
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public {
    require(isApproved(_to));
    require(personIndexToOwner[_tokenId] == _from);
    require(tokenIdValid(_tokenId));
    require(notNullToAddress(_to));

    transferToken(_from, _to, _tokenId);
  }

  /* PRIVATE FUNCTIONS */
  /// For checking approval of transfer for address _to
  function isApproved(address _to) private view returns (bool) {
    return approved == _to;
  }

  /// Safety check on _to address to prevent against an unexpected 0x0 default.
  function notNullToAddress(address _to) private pure returns (bool) {
    return _to != address(0);
  }

  /// For paying out balance on contract
  function _payout(address _to) private {
    if (_to == address(0)) {
      ceoAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }

  /// Verifying that token id _tokenId is valid
  function tokenIdValid(uint256 _tokenId) private view returns (bool) {
    return _tokenId == _theTokenId;
  }

  /// @dev Assigns ownership of a specific Person to an address.
  function transferToken(address _from, address _to, uint256 _tokenId) private {
    // Since the number of persons is capped to 2^32 we can't overflow this
    ownershipTokenCount[_to]++;
    //transfer ownership
    personIndexToOwner[_tokenId] = _to;

    // When creating new persons _from is 0x0, but we can't account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete personIndexToApproved[_tokenId];
    }

    // Emit the transfer event.
    Transfer(_from, _to, _theTokenId);
  }
}
