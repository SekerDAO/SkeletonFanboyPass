// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

contract SkeletonStephGenesis is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds;
    uint256 public totalMint = 2100;
    uint256 public stephReserve = 30;
    uint256 public price = 0.076 ether;
    bool public isPresale = true;

    // struct Allowlist {
    //     uint256 claimed;
    //     address claimer;
    // }

    string public IMGURL = "https://sekerfactory.mypinata.cloud/ipfs/Qmdv289QGShGexdyhHPocBSSVRffjM4Kqdyr15FZXLv4ws/";
    address public FanboyPass = address(0xA8b3751b8fBBeF9EFefaeded0B920179E104fd65);

    mapping(uint256 => bool) public claimed;

    constructor() ERC721("Skeleton Steph Genesis Series", "Steph Genesis") {}

    function allowlistMint(uint256 _amount, uint256[] memory _ids) public payable {
        // require(_amount <= 5, "can only mint a max of 5 per account");
        require(isPresale, "presale has ended");
        require(_amount == _ids.length, "amount and number of ids missmatch");
        // require(IERC721(FanboyPass).balanceOf(msg.sender) >= _ids.length, "minter does not own enough FanboyPasses");
        for (uint256 i; i <= _ids.length; i++) {
            require(IERC721(FanboyPass).ownerOf(_ids[i]) == msg.sender, "minter does not own an id");
            require(claimed[_ids[i]] == false, "id has already been claimed");
            claimed[_ids[i]] = true;
        }
        require(msg.value == price * _amount, "Incorrect eth amount");
        for (uint256 i; i <= _amount - 1; i++) {
            uint256 newNFT = _tokenIds.current();
            _safeMint(msg.sender, newNFT);
            _tokenIds.increment();
        }
    }

    function mint(uint256 _amount) public payable {
        require(!isPresale, "public mint has not begun");
        require(
            (Counters.current(_tokenIds) + _amount) <= totalMint,
            "minting has reached its max"
        );
        require(msg.value == price * _amount, "Incorrect eth amount");
        for (uint256 i; i <= _amount - 1; i++) {
            uint256 newNFT = _tokenIds.current();
            _safeMint(msg.sender, newNFT);
            _tokenIds.increment();
        }
    }

    function mintSteph(uint256 _amount) public onlyOwner {
        require(
            (Counters.current(_tokenIds) + _amount) <= totalMint,
            "minting has reached its max"
        );
        for (uint256 i; i <= _amount - 1; i++) {
            require(stephReserve > 0, "steph reserve fully minted");
            uint256 newNFT = _tokenIds.current();
            _safeMint(msg.sender, newNFT);
            _tokenIds.increment();
            stephReserve--;
        }
    }

    function startPublicMint() public onlyOwner {
        isPresale = false;
    }

    function updateTokenURI(string memory _newURI) public onlyOwner {
        IMGURL = _newURI;
    }

    function updateTotalMint(uint256 _newSupply) public onlyOwner {
        require(_newSupply > _tokenIds.current(), "new supply less than already minted");
        totalMint = _newSupply;
    }

    function updatePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "Clearance Cards: URI query for nonexistent token"
        );
        return string(abi.encodePacked(IMGURL, tokenId.toString(), ".json"));
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    // Withdraw
    function withdraw(address payable withdrawAddress)
        external
        payable
        onlyOwner
    {
        require(
            withdrawAddress != address(0),
            "Withdraw address cannot be zero"
        );
        require(address(this).balance >= 0, "Not enough eth");
        (bool sent, ) = withdrawAddress.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}