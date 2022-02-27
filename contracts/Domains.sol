// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

// We first import some OpenZeppelin Contracts.
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import {StringUtils} from "./libraries/StringUtils.sol";
// We import another help function
import {Base64} from "./libraries/Base64.sol";

import "hardhat/console.sol";

contract Domains is ERC721URIStorage {

  // Magic given to us by OpenZeppelin to help us keep track of tokenIds.
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  // We'll be storing our NFT images on chain as SVGs
  string svgPartOne = '<svg width="128" height="128" viewBox="0 0 128 128" xmlns="http://www.w3.org/2000/svg"><path d="M64 29.659 26.667 59.525v41.808h26.666V80h21.334v21.333h26.666V62.091a5.338 5.338 0 0 0-2-4.166L64 29.659ZM64 16l41.995 33.595A15.99 15.99 0 0 1 112 62.091v39.242A10.663 10.663 0 0 1 101.333 112H26.667C20.779 112 16 107.227 16 101.333V59.525c0-3.237 1.472-6.304 4.005-8.33L64 16Z"/><text x="50%" y="6.5%" dominant-baseline="middle" text-anchor="middle">';
  string svgPartTwo = '</text></svg>';
  
  // Here's our domain TLD!
  string public tld;

  // Stores the users that have registered with the service
  mapping(string => address) public domains;
  // Stores a url pointing to the user's profile picture in the call data
  mapping(string => string) public images;
  // Add this at the top of your contract next to the other mappings
  mapping (uint => string) public names;
  address payable public owner;

  // We make the contract "payable" by adding this to the constructor
  constructor(string memory _tld) payable ERC721("WhoAmI Profile Service", "WPS") {
    owner = payable(msg.sender);
    tld = _tld;
    console.log("%s name service deployed", _tld);
  }

  // This function will give us the price of a domain based on length
  function price(string calldata name) public pure returns(uint) {
    uint len = StringUtils.strlen(name);
    if(len > 8) revert InvalidName(name);
    // Cost is directly correlated with length of string
    // and cheap.
    return len * 2 * 10**15; // 0.00X MATIC
  }

  function getNextNftToken() internal returns(uint256) {
      uint256 nextToken = _tokenIds.current();
      _tokenIds.increment();
      return nextToken;
  }

  function register(string calldata name) public payable {
    // Validate message sender
    if (domains[name] != address(0)) revert AlreadyRegistered();
    // Validate price
    uint256 _price = price(name);
    console.log("Got %s matic, need %s matic", msg.value, _price);
    if (msg.value < _price) revert InsufficientFunds();
	
    // --- Construct NFT Metadata ---
	// Combine the name passed into the function  with the TLD
    string memory _name = string(abi.encodePacked(name, ".", tld));
	// Create the SVG (image) for the NFT with the name
    string memory finalSvg = string(abi.encodePacked(svgPartOne, _name, svgPartTwo));
    // Get the length of the string to encode into the NFT's metadata
  	uint256 length = StringUtils.strlen(name);
	string memory strLen = Strings.toString(length);
	// Create the JSON metadata of our NFT. We do this by combining strings and encoding as base64
    string memory base64encodedJson = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            
            '{"name": "',
            _name,
            '", "description": "A domain on the whoami name service", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(finalSvg)),
            '","length":"',
            strLen,
            '"}'
          )
        )
      )
    );
    string memory finalTokenUri = string(abi.encodePacked("data:application/json;base64,", base64encodedJson));
    // --- End Construct NFT Metadata ---

	console.log("\n--------------------------------------------------------");
	console.log("Final tokenURI", finalTokenUri);
	console.log("--------------------------------------------------------\n");

    uint256 newRecordId = getNextNftToken();
    console.log("Registering %s.%s on the contract with tokenID %d", name, tld, newRecordId);
    _safeMint(msg.sender, newRecordId);
    _setTokenURI(newRecordId, finalTokenUri);
    names[newRecordId] = name;
    domains[name] = msg.sender;
  }

  function getAddress(string calldata name) public view returns (address) {
      // Check that the owner is the transaction sender
      return domains[name];
  }

  function setImage(string calldata name, string calldata image_url) public {
      // Check that the owner is the transaction sender
      if(domains[name] != msg.sender) revert Unauthorized();
      images[name] = image_url;
  }

  function getImage(string calldata name) public view returns(string memory) {
      return images[name];
  }

  modifier onlyOwner() {
    if(!isOwner()) revert Unauthorized();
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function withdraw() public onlyOwner {
    uint amount = address(this).balance;
    
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Failed to withdraw Matic");
  } 

  // Add this anywhere in your contract body
  function getAllNames() public view returns (string[] memory) {
    console.log("Getting all names from the contract");
    string[] memory allNames = new string[](_tokenIds.current());
    uint i = 0;
    uint top = _tokenIds.current();
    while (i < top) {
      allNames[i] = names[i];
      i++;
    }

    return allNames;
  }

  error Unauthorized();
  error AlreadyRegistered();
  error InvalidName(string name);
  error InsufficientFunds();
}
