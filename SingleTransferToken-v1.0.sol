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

    uint256 private currentPrice;

    uint256 private sellingPrice;

    uint256 private stepLimit = 2 ether;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    // Owner of this contract
    address private contractOwner;

    // Current owner of the token
    address public tokenOwner;

    // Allowed to transfer to this address
    address private approved = address(0);

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
    ///  @dev Required for ERC-721 compliance.
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _owner == tokenOwner ? 1 : 0;
    }

    function implementsERC721() public pure returns (bool) {
        return true;
    }

    function name() public view returns (string name) {
        name = _name;
    }

    /// For querying owner of token
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId)
        public
        view
        returns (address owner)
    {
        require(tokenIdMatches(_tokenId));
        owner = tokenOwner;
    }

    // Allows someone to send ether and obtain the token
    function purchaseToken() public payable {
        oldOwner = tokenOwner;
        newOwner = msg.sender;

        // Making sure token owner is not sending to self
        require(oldOwner != newOwner);

        // Safety check to prevent against an unexpected 0x0 default.
        require(notNullToAddress(newOwner));

        // Making sure sent amount is greater than or equal to the sellingPrice
        require(msg.value >= sellingPrice);

        // If sent amount is greater than sellingPrice, save diff and refund below.
        excessValue = msg.value - currentPrice;

        // Update prices
        currentPrice = sellingPrice;

        if (currentPrice >= stepLimit) {

            sellingPrice = (currentPrice * 120)/94; //adding commission amount //1.2/(1-0.06)

        } else {

            sellingPrice = (currentPrice * 2 * 100)/94;//adding commission amount

        }

        transferToken(oldOwner, newOwner);

        // Pay previous tokenOwner
        payment = currentPrice * 94/100;
        oldOwner.transfer(payment); //(1-0.06)
        
        // Pay commission to contractOwner
        contractOwner.transfer(currentPrice - payment);

        if (excessValue) {
            msg.sender.transfer(excessValue);
        }

        //if contact balance is greater than 1000000000000000 wei,
        //transfer balance to the contract owner
        //if (this.balance >= 1000000000000000) {

        //    owner.transfer(this.balance);

        //}

    }
/*
    function payout(address _to) public onlyContractOwner {
        if (this.balance > 1 ether) {
            if (_to == address(0)) {
                owner.transfer(this.balance - 1 ether);
            } else {
                _to.transfer(this.balance - 1 ether);
            }
        }
    } */

    function symbol() public view returns (string symbol) {
        symbol = _symbol;
    }

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
        return TOTAL_SUPPLY;
    }

    /// Transfer the token from owner's account to another account
    /// @dev Required for ERC-721 compliance.
    function transfer(
        address _to,
        uint256 _tokenId
    ) public  onlyTokenOwner {
        require(tokenIdMatches(_tokenId));
        require(notNullToAddress(_to));

        transferToken(msg.sender, _to);
    }

    /// Send _tokenId token from address _from to address _to
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

    // Private functions
    // For checking approval of transfer
    function isApproved(address _to) private view returns (bool approval) {
        return approved == _to;
    }

    // Safety check on _to address to prevent against an unexpected 0x0 default.
    function notNullToAddress(address _to) private view returns (bool notNull) {
        return _to != address(0);
    }

    /// Verifying that tokenId is valid
    function tokenIdMatches(uint256 _tokenId) private view returns (bool matches) {
        require(_tokenId == TOKEN_ID);
        _;
    }

    // For transfering token from one owner to the next, and clearing approved
    function transferToken(address _from, address _to) private {
        tokenOwner = _to;
        // reset approved transfers
        approved = address(0);
        Transfer(_from, _to, TOKEN_ID);
    }
}
