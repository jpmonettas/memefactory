pragma solidity ^0.4.24;

import "RegistryEntry.sol";
import "MemeToken.sol";
import "./DistrictConfig.sol";
import "FactsDb.sol";

/**
 * @title Contract created for each submitted Meme into the MemeFactory TCR.
 *
 * @dev It extends base RegistryEntry with additional state for storing IPFS hashes for a meme image and meta data.
 * It also contains state and logic for handling initial meme offering.
 * Full copy of this contract is NOT deployed with each submission in order to save gas. Only forwarder contracts
 * pointing into single intance of it.
 */

contract Meme is RegistryEntry {

  DistrictConfig private constant districtConfig = DistrictConfig(0xABCDabcdABcDabcDaBCDAbcdABcdAbCdABcDABCd);
  MemeToken private constant memeToken = MemeToken(0xdaBBdABbDABbDabbDaBbDabbDaBbdaBbdaBbDAbB);
  FactsDb internal constant factsDb = FactsDb(0xaaffaaffaaffaaffaaffaaffaaffaaffaaffaaff);
  bytes private metaHash;
  uint private tokenIdStart;
  uint private totalSupply;
  uint private totalMinted;

  /**
   * @dev Constructor for this contract.
   * Native constructor is not used, because users create only forwarders pointing into single instance of this contract,
   * therefore constructor must be called explicitly.
   */
  function construct(address _creator,
                     uint _version,
                     bytes _imageHash,
                     uint _totalSupply,
                     string _title)
    external
  {
    super.construct(_creator, _version);

    require(_totalSupply > 0);
    require(_totalSupply <= registry.db().getUIntValue(registry.maxTotalSupplyKey()));

    totalSupply = _totalSupply;


    factsDb.transactUInt(uint(this), "meme/total-supply", version);
    factsDb.transactString(uint(this), "meme/title", _title);
    factsDb.transactBytes(uint(this), "meme/image-hash", _imageHash);

    registry.fireMemeConstructedEvent(version,
                                      _creator,
                                      "",
                                      totalSupply,
                                      deposit,
                                      challenge.challengePeriodEnd);

  }

  /**
   * @dev Transfers deposit to deposit collector
   * Must be callable only for whitelisted unchallenged registry entries
   */
  function transferDeposit()
    external
    notEmergency
    onlyWhitelisted
  {
    require(!challenge.wasChallenged());
    require(registryToken.transfer(districtConfig.depositCollector(), deposit));

  }

  function mint(uint _amount)
    public
    notEmergency
    onlyWhitelisted
  {
    uint restSupply = totalSupply.sub(totalMinted);
    if (_amount == 0 || _amount > restSupply) {
      _amount = restSupply;
    }

    require(_amount > 0);

    tokenIdStart = memeToken.totalSupply().add(1);
    uint tokenIdEnd = tokenIdStart.add(_amount);
    for (uint i = tokenIdStart; i < tokenIdEnd; i++) {
      memeToken.mint(creator, i);
      totalMinted = totalMinted + 1;
      factsDb.transactUInt(uint(keccak256(abi.encodePacked("token/id", i))), "token/id", i);
    }

    factsDb.transactUInt(uint(this), "meme/total-minted", totalMinted);
    factsDb.transactUInt(uint(this), "meme/token-id-start", tokenIdStart);
    factsDb.transactUInt(uint(this), "meme/token-id-end", tokenIdEnd);

    registry.fireMemeMintedEvent(version,
                                 creator,
                                 tokenIdStart,
                                 tokenIdEnd-1,
                                 totalMinted);
  }

}
