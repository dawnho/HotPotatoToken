pragma solidity ^0.4.8;


/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
contract ERC721 {
    // Required methods
    function approve(address _to, uint256 _tokenId) public;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function implementsERC721() public pure returns (bool);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
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
    string private _name = "Single Transfer Token";
    string private _symbol = "STT";

    uint256 private constant TOTAL_SUPPLY = 1;
    uint256 private constant TOKEN_ID = 2046;

    uint256 currentPrice;

    uint256 sellingPrice;

    uint256 private stepLimit = 2 ether;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    // Owner of this contract
    address private contractOwner;

    // Current owner of the token
    address public tokenOwner;

    // Allowed to transfer to this address
    address allowedTo = address(0);

    /// Access modifier for contract owner only functionality
    modifier onlyContractOwner() {
        require(msg.sender == contractOwner);
        _;
    }

    /// Access modifier for token owner only functionality
    modifier onlyTokenOwner() {
        require(msg.sender == tokenOwner);
        _;
    }

    /// Verifying that tokenId is valid
    modifier tokenIdMatches(uint256 _tokenId) {
        require(_tokenId == TOKEN_ID);
        _;
    }

    // Constructor
    function SingleTransferToken(string tokenName, string tokenSymbol, uint256 initialPrice, uint256 sLimit) public {

        _name = tokenName;

        _symbol = tokenSymbol;

        contractOwner = msg.sender;

        tokenOwner = msg.sender;

        stepLimit = sLimit;

        sellingPrice = initialPrice;

        currentPrice = initialPrice;

    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(
        address _to,
        uint256 _tokenId
    ) public onlyTokenOwner tokenIdMatches(_tokenId) {
        // Owner cannot grant approval to self.
        require(msg.sender != _to);

        allowedTo = _to;

        Approval(msg.sender, _to, _tokenId);
    }

    //  Required for ERC-721 compliance.
    //  For querying balance of a particular account
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _owner == tokenOwner ? 1 : 0;
    }

    function implementsERC721() public pure returns (bool) {
        return true;
    }

    function name() public view returns (string name) {
        name = _name;
    }

    /// Required for ERC-721 compliance.
    // For querying owner of token
    function ownerOf(uint256 _tokenId)
        public
        view
        tokenIdMatches(_tokenId)
        returns (address owner)
    {
        owner = tokenOwner;
    }

    function symbol() public view returns (string symbol) {
        symbol = _symbol;
    }

    function takeOwnership(uint256 _tokenId) public tokenIdMatches(_tokenId) {
        address newOwner = msg.sender;

        // Safety check to prevent against an unexpected 0x0 default.
        require(newOwner != address(0));

        require(approvalOf(newOwner));
        require(newOwner != tokenOwner);
        Transfer(tokenOwner, newOwner, _tokenId);
    }

    /// Required for ERC-721 compliance.
    /// For querying totalSupply of token
    function totalSupply() public view returns (uint256 total) {
        return TOTAL_SUPPLY;
    }

    /// Required for ERC-721 compliance.
    // Transfer the balance from owner's account to another account
    function transfer(
        address _to,
        uint256 _tokenId
    ) public  onlyTokenOwner tokenIdMatches(_tokenId) {
        // Safety check to prevent against an unexpected 0x0 default.
        require(newOwner != address(0));

        tokenOwner = _to;
        Transfer(msg.sender, _to, _tokenId);
    }

    // Send _tokenId token from address _from to address _to
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public tokenIdMatches(_tokenId) {
        oldOwner = _from;
        newOwner = _to;

        // Safety check to prevent against an unexpected 0x0 default.
        require(newOwner != address(0));

        require(approvalOf(newOwner));
        require(tokenOwner == oldOwner);

        tokenOwner = _to;
        Transfer(_from, _to, _tokenId);
    }

    // Allows someone to send ether and obtain the token
    function() public payable {

        //making sure token owner is not sending
        assert(tokenOwner != msg.sender);

        //making sure sent amount is greater than or equal to the sellingPrice
        assert(msg.value >= sellingPrice);

        //if sent amount is greater than sellingPrice refund extra
        if(msg.value > sellingPrice){

            msg.sender.transfer(msg.value - sellingPrice);

        }

        //update prices
        currentPrice = sellingPrice;

        if (currentPrice >= stepLimit) {

            sellingPrice = (currentPrice * 120)/94; //adding commission amount //1.2/(1-0.06)

        } else {

            sellingPrice = (currentPrice * 2 * 100)/94;//adding commission amount

        }

        transferToken(tokenOwner, msg.sender);

        //if contact balance is greater than 1000000000000000 wei,
        //transfer balance to the contract owner
        //if (this.balance >= 1000000000000000) {

        //    owner.transfer(this.balance);

        //}

    }

    function payout(address _to) public onlyContractOwner {
        if (this.balance > 1 ether) {
            if (_to == address(0)) {
                owner.transfer(this.balance - 1 ether);
            } else {
                _to.transfer(this.balance - 1 ether);
            }
        }
    }

    // Private functions
    function approvalOf(address _to) private view returns (bool approved) {
        return allowedTo == _to;
    }

    function transferToken(address prevOwner, address newOwner) private {

        //pay previous owner
        prevOwner.transfer((currentPrice*94)/100); //(1-0.06)

        tokenOwner = newOwner;

        Transfer(prevOwner, newOwner, 1);


    }
}
