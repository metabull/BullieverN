//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./EnumerableMap.sol";
import "./ERC721Enumerable.sol";
import "./ERC1155.sol";
import "./token/SafeERC20.sol";


contract MyNFT is ERC721Enumerable, Ownable  {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public rewardToken = IERC20(0x9CBc63B1c5301F4C4Ba24bFc3a51E511e5DaC338);
    address masterAccountAddress = 0xB0606B70bEfa0fB3A9E6E933382192E5567B723a;
    
    uint256 public constant DURATION = 100 days;
    uint256 private totalReward = 20000000000000000000000000;
    uint256 public periodFinish;

    using SafeMath for uint256;
    mapping(address => mapping(uint256=>uint256)) public receivedTime;
    event RewardPaid(address indexed user, uint256 reward);
    
    // Token detail
    struct AlienDetail {
        uint256 first_encounter;
    }

    // Events
    event TokenMinted(uint256 tokenId, address owner, uint256 first_encounter);

    // Token Detail
    mapping( uint256 => AlienDetail) private _alienDetails;

    // Provenance number
    string public PROVENANCE = "";

    // Starting index
    uint256 public STARTING_INDEX;

    // Max amount of token to purchase per account each time
    uint public MAX_PURCHASE = 50;

    // Maximum amount of tokens to supply.
    uint256 public MAX_TOKENS = 10000;

    // Current price.
    uint256 public CURRENT_PRICE = 80;

    // Define if sale is active
    bool public saleIsActive = true;

    // Base URI
    string private baseURI;

    /**
     * Contract constructor
     */
    constructor(string memory name, string memory symbol, string memory baseURIp, uint256 startingIndex) ERC721(name, symbol) {
        setBaseURI(baseURIp);
        STARTING_INDEX = startingIndex;
        periodFinish= block.timestamp+DURATION;
    }

    /**
     * Withdraw
     */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * Reserve tokens
     */
    function reserveTokens() public onlyOwner {
        uint i;
        uint tokenId;
        uint256 first_encounter = block.timestamp;

        for (i = 1; i <= 50; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
                _alienDetails[tokenId] = AlienDetail(first_encounter);
                receivedTime[msg.sender][tokenId]=block.timestamp;
                emit TokenMinted(tokenId, msg.sender, first_encounter);
            }
        }
    }

    /**
     * Mint a specific token. 
     */
    function mintTokenId(uint tokenId) public onlyOwner {
        require(!_exists(tokenId), "Token was minted");
        uint256 first_encounter = block.timestamp;
        receivedTime[msg.sender][tokenId]=block.timestamp;
        _safeMint(msg.sender, tokenId);
        _alienDetails[tokenId] = AlienDetail(first_encounter);
        emit TokenMinted(tokenId, msg.sender, first_encounter);
    }

    /*     
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PROVENANCE = provenanceHash;
    }
    
    
    /*     
    * Set max tokens
    */
    function setMaxTokens(uint256 maxTokens) public onlyOwner {
        MAX_TOKENS = maxTokens;
    }

    /*
    * Pause sale if active, make active if paused
    */
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    /**
    * Mint Alien
    */
    function mintAlien(uint numberOfTokens) public payable {
        require(saleIsActive, "Mint is not available right now");
        require(numberOfTokens <= MAX_PURCHASE, "Can only mint 50 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply of Aliens");
        require(CURRENT_PRICE.mul(numberOfTokens) <= msg.value, "Value sent is not correct");
        uint256 first_encounter = block.timestamp;
        uint tokenId;
        
        for(uint i = 1; i <= numberOfTokens; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
                _alienDetails[tokenId] = AlienDetail(first_encounter);
                receivedTime[msg.sender][tokenId]=block.timestamp;
                emit TokenMinted(tokenId, msg.sender, first_encounter);
            }
        }
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        uint256 rewardAmount = getRewardAmount(receivedTime[msg.sender][tokenId]);
        super.safeTransferFrom(from, to, tokenId, "");
        receivedTime[to][tokenId]=block.timestamp;
      if(rewardAmount!=0)
      rewardToken.safeTransferFrom(masterAccountAddress,msg.sender,rewardAmount);
         
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        uint256 rewardAmount = getRewardAmount(receivedTime[msg.sender][tokenId]);
        super.safeTransferFrom(from, to, tokenId, _data);
        receivedTime[to][tokenId]=block.timestamp;
      if(rewardAmount!=0)
      rewardToken.safeTransferFrom(masterAccountAddress,msg.sender,rewardAmount);
        
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        uint256 rewardAmount = getRewardAmount(receivedTime[msg.sender][tokenId]);
        super.transferFrom(from, to, tokenId);
        if(rewardAmount!=0)
        rewardToken.safeTransferFrom(masterAccountAddress,msg.sender,rewardAmount);
        receivedTime[to][tokenId]=block.timestamp;
         
    }
    

    /**
     * Set the starting index for the collection
     */
    function setStartingIndex(uint256 startingIndex) public onlyOwner {
        STARTING_INDEX = startingIndex;
    }

    /**
    * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
    */
    function setBaseURI(string memory BaseURI) public onlyOwner {
       baseURI = BaseURI;
    }

     /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

   /**
     * Set the current token price
     */
    function setCurrentPrice(uint256 currentPrice) public onlyOwner {
        CURRENT_PRICE = currentPrice;
    }

    /**
     * Get the token detail
     */
    function getAlienDetail(uint256 tokenId) public view returns(AlienDetail memory detail) {
        require(_exists(tokenId), "Token was not minted");

        return _alienDetails[tokenId];
    }
    
    function getRewardAmount(uint256 timestamp) internal view returns(uint256 rewardAmount)
    {
        if(block.timestamp<periodFinish)
        return (block.timestamp.sub(timestamp)).mul(rewardRate());
        
        if(block.timestamp>periodFinish&&timestamp<periodFinish)
          return (periodFinish.sub(timestamp)).mul(rewardRate());
          
        return 0;
    }
    
    function rewardRate() internal view returns(uint256)
    {
        return totalReward.div(DURATION.mul(MAX_TOKENS));
    }
    
    function claimReward(uint256 _tokenId) public
    {
      require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
      require(msg.sender == ownerOf(_tokenId), "not from owner");
     /*
     yet to decide where to use master account to send token or contract only
     
     */    
      //rewardToken.safeTransfer(msg.sender,getRewardAmount(receivedTime[msg.sender][_tokenId]));
      rewardToken.safeTransferFrom(masterAccountAddress,msg.sender,getRewardAmount(receivedTime[msg.sender][_tokenId]));
      receivedTime[msg.sender][_tokenId]=block.timestamp;
    }
    
    function multiClaim(uint256[] memory _tokenIds) public
    {
        uint totalRewardAmount=0;
        for(uint i=0;i<_tokenIds.length;i++)
        {
          require(_exists(_tokenIds[i]), "ERC721Metadata: URI query for nonexistent token");
          require(msg.sender == ownerOf(_tokenIds[i]), "not from owner");
          totalRewardAmount = totalRewardAmount+getRewardAmount(receivedTime[msg.sender][_tokenIds[i]]);
          receivedTime[msg.sender][_tokenIds[i]]=block.timestamp;
        }
       rewardToken.safeTransferFrom(masterAccountAddress,msg.sender,totalRewardAmount);     
    }
    
    function getTotalRewards(uint256[] memory _tokenIds) public view returns(uint256 rewardAmount)
    {
        uint totalRewardAmount=0;
        for(uint i=0;i<_tokenIds.length;i++)
        {
          require(_exists(_tokenIds[i]), "ERC721Metadata: URI query for nonexistent token");
          require(msg.sender == ownerOf(_tokenIds[i]), "not from owner");
          totalRewardAmount = totalRewardAmount+getRewardAmount(receivedTime[msg.sender][_tokenIds[i]]);
        }
      return totalRewardAmount;     
    }
}
