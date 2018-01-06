pragma solidity ^0.4.18;
import "zeppelin-solidity/contracts/math/SafeMath.sol";


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


contract SingleTransferToken is ERC721 {

    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string private _name;
    string private _symbol;

    uint256 private _totalSupply;
    uint256 private _theTokenId;

    uint256 private sellingPrice;

    uint256 private stepLimit;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    // Owner of this contract
    address private owner;

    // Current owner of the token
    address public tokenOwner;

    // Allowed to transfer to this address
    address private approved = address(0);

    /// Access modifier for contract owner only functionality
    modifier onlyContractOwner() {
        require(msg.sender == owner);
        _;
    }

    /// Access modifier for token owner only functionality
    modifier onlyTokenOwner() {
        require(msg.sender == tokenOwner);
        _;
    }

    // Constructor
    function SingleTransferToken(string tokenName, string tokenSymbol, uint256 initialPrice, uint256 sLimit) public {

        _name = tokenName;

        _symbol = tokenSymbol;

        owner = msg.sender;

        tokenOwner = msg.sender;

        stepLimit = sLimit;

        sellingPrice = initialPrice;

        _totalSupply = 1;

        _theTokenId = 1;

    }

    // Allows someone to send ether and obtain the token
    function() public payable {
        address oldOwner = tokenOwner;
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

            sellingPrice = SafeMath.div(SafeMath.mul(sellingPrice, 200), 94);//adding commission amount

        }

        transferToken(oldOwner, newOwner);

        // Pay previous tokenOwner
        oldOwner.transfer(payment); //(1-0.06)

        // Pay commission to owner
        if (this.balance > 0.5 ether) {
            _payout(owner);
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
    ) public onlyTokenOwner {
        // Owner cannot grant approval to self.
        require(msg.sender != _to);

        // Check whether token ID is on record.
        require(tokenIdMatches(_tokenId));

        approved = _to;

        Approval(msg.sender, _to, _tokenId);
    }

    /// For querying balance of a particular account
    /// @param _owner The address for balance query
    /// @dev Required for ERC-721 compliance.
    function balanceOf(address _owner) public view returns (uint256 balance) {
        balance = (_owner == tokenOwner) ? 1 : 0;
    }

    function implementsERC721() public pure returns (bool) {
        return true;
    }

    function name() public constant returns (string) {
        return _name;
    }

    /// For querying owner of token
    /// @param _tokenId The tokenID for owner inquiry
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId)
        public
        view
        returns (address addr)
    {
        require(tokenIdMatches(_tokenId));
        return tokenOwner;
    }

    function payout(address _to) public onlyContractOwner {
        _payout(_to);
    }

    /// For querying the symbol of the contract
    function symbol() public view returns (string symb) {
        return _symbol;
    }

    /// @notice Allow pre-approved user to take ownership of a token
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function takeOwnership(uint256 _tokenId) public {
        address newOwner = msg.sender;

        // Safety check to prevent against an unexpected 0x0 default.
        require(notNullToAddress(newOwner));

        // Safety check to ensure token ID is correct
        require(tokenIdMatches(_tokenId));

        // Making sure transfer is approved
        require(isApproved(newOwner));

        // Making sure token owner is not sending to self
        require(newOwner != tokenOwner);

        transferToken(tokenOwner, newOwner);
    }

    /// For querying totalSupply of token
    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint256 total) {
        return _totalSupply;
    }

    /// Owner initates the transfer of the token to another account
    /// @param _to The address for the token to be transferred to.
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function transfer(
        address _to,
        uint256 _tokenId
    ) public  onlyTokenOwner {
        require(tokenIdMatches(_tokenId));
        require(notNullToAddress(_to));

        transferToken(msg.sender, _to);
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
        require(tokenOwner == _from);
        require(tokenIdMatches(_tokenId));
        require(notNullToAddress(_to));

        transferToken(_from, _to);
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
            owner.transfer(this.balance);
        } else {
            _to.transfer(this.balance);
        }
    }

    /// Verifying that token id _tokenId is valid
    function tokenIdMatches(uint256 _tokenId) private view returns (bool) {
        return _tokenId == _theTokenId;
    }

    /// For transfering token from address _from to address _to, and clearing approved log
    function transferToken(address _from, address _to) private {
        tokenOwner = _to;
        // reset approved log
        approved = address(0);
        Transfer(_from, _to, _theTokenId);
    }

    /// SafeMath fns from zeppelin-solidity/SafeMath
    /* function mul(uint256 a, uint256 b) private pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) private pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) private pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) private pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    } */
}
