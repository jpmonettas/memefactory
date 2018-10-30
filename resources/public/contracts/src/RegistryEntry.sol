pragma solidity ^0.4.24;

import "Registry.sol";
import "FactsDb.sol";
import "token/minime/MiniMeToken.sol";
import "math/SafeMath.sol";
import "registryentry/RegistryEntryLib.sol";

/**
 * @title Contract created with each submission to a TCR
 *
 * @dev It contains all state and logic related to TCR challenging and voting
 * Full copy of this contract is NOT deployed with each submission in order to save gas. Only forwarder contracts
 * pointing into single instance of it.
 * This contract is meant to be extended by domain specific registry entry contracts (Meme, ParamChange)
 */

contract RegistryEntry is ApproveAndCallFallBack {
  using SafeMath for uint;
  using RegistryEntryLib for RegistryEntryLib.Challenge;

  Registry internal constant registry = Registry(0xfEEDFEEDfeEDFEedFEEdFEEDFeEdfEEdFeEdFEEd);
  FactsDb internal constant factsDb = FactsDb(0xaaffaaffaaffaaffaaffaaffaaffaaffaaffaaff);
  MiniMeToken internal constant registryToken = MiniMeToken(0xDeaDDeaDDeaDDeaDDeaDDeaDDeaDDeaDDeaDDeaD);

  address internal creator;
  uint internal version;
  uint internal deposit;
  RegistryEntryLib.Challenge internal challenge;

  /**
   * @dev Modifier that disables function if registry is in emergency state
   */
  modifier notEmergency() {
    require(!registry.isEmergency());
    _;
  }

  /**
   * @dev Modifier that disables function if challenge is not whitelisted
   */
  modifier onlyWhitelisted() {
    require(challenge.isWhitelisted());
    _;
  }

  /**
   * @dev Constructor for this contract.
   * Native constructor is not used, because users create only forwarders into single instance of this contract,
   * therefore constructor must be called explicitly.
   * Must NOT be callable multiple times
   * Transfers TCR entry token deposit from sender into this contract

   * @param _creator Creator of a meme
   * @param _version Version of Meme contract
   */
  function construct(
                     address _creator,
                     uint _version
                     )
    public
  {
    require(challenge.challengePeriodEnd == 0);
    deposit = registry.db().getUIntValue(registry.depositKey());
    require(registryToken.transferFrom(msg.sender, this, deposit));

    challenge.challengePeriodEnd = now.add(registry.db().getUIntValue(registry.challengePeriodDurationKey()));

    creator = _creator;
    version = _version;

    factsDb.transactAddress(uint(_creator), "user/created", address(this));
    factsDb.transactAddress(uint(this), "reg-entry/address", address(this));
    factsDb.transactUInt(uint(this), "reg-entry/challenge-period-end", challenge.challengePeriodEnd);
    factsDb.transactUInt(uint(this), "reg-entry/deposit", deposit);

  }

  /**
   * @dev Creates a challenge for this TCR entry
   * Must be within challenge period
   * Entry can be challenged only once
   * Transfers token deposit from challenger into this contract
   * Forks registry token (DankToken) in order to create single purpose voting token to vote about this challenge
   */
  function createChallenge(
                           address _challenger,
                           string _challengeReason
                           )
    external
    notEmergency
  {
    require(challenge.isChallengePeriodActive());
    require(!challenge.wasChallenged());
    require(registryToken.transferFrom(_challenger, this, deposit));

    challenge.challenger = _challenger;
    challenge.voteQuorum = registry.db().getUIntValue(registry.voteQuorumKey());
    uint commitDuration = registry.db().getUIntValue(registry.commitPeriodDurationKey());
    uint revealDuration = registry.db().getUIntValue(registry.revealPeriodDurationKey());

    challenge.commitPeriodEnd = now.add(commitDuration);
    challenge.revealPeriodEnd = challenge.commitPeriodEnd.add(revealDuration);
    challenge.rewardPool = uint(100).sub(registry.db().getUIntValue(registry.challengeDispensationKey())).mul(deposit).div(uint(100));

    uint challengeId = uint(keccak256(abi.encodePacked(uint(this),"challenge")));

    factsDb.transactAddress(uint(_challenger), "user/challenged", address(this));
    factsDb.transactUInt(uint(this), "reg-entry/challenge", challengeId);
    factsDb.transactAddress(challengeId, "challenge/challenger", challenge.challenger);
    factsDb.transactUInt(challengeId, "challenge/commit-period-end",challenge.commitPeriodEnd);
    factsDb.transactUInt(challengeId, "challenge/reveal-period-end",challenge.revealPeriodEnd);
    factsDb.transactUInt(challengeId, "challenge/reward-pool",challenge.rewardPool);
    factsDb.transactString(challengeId, "challenge/reason",_challengeReason);


  }

  /**
   * @dev Commits encrypted vote to challenged entry
   * Locks voter's tokens in this contract. Returns when vote is revealed
   * Must be within commit period
   * Same address can't make a second vote for the same challenge

   * @param _voter Address of a voter
   * @param _amount Amount of tokens to vote with
   * @param _secretHash Encrypted vote option with salt. sha3(voteOption, salt)
   */
  function commitVote(
                      address _voter,
                      uint _amount,
                      bytes32 _secretHash
                      )
    external
    notEmergency
  {
    require(challenge.isVoteCommitPeriodActive());
    require(_amount > 0);
    require(!challenge.hasVoted(_voter));
    require(registryToken.transferFrom(_voter, this, _amount));

    challenge.vote[_voter].secretHash = _secretHash;
    challenge.vote[_voter].amount += _amount;

    uint challengeId = uint(keccak256(abi.encodePacked(uint(this),"challenge")));
    uint voteId = uint(keccak256(abi.encodePacked(uint(this),"challenge",_voter)));

    factsDb.transactUInt(challengeId, "challenge/vote", voteId);
    factsDb.transactUInt(voteId, "vote/amount", challenge.vote[_voter].amount);
    factsDb.transactAddress(voteId, "vote/voter", _voter);

  }

  /**
   * @dev Reveals previously committed vote
   * Returns registryToken back to the voter
   * Must be within reveal period

   * @param _voteOption Vote option voter previously voted with
   * @param _salt Salt with which user previously encrypted his vote option
   */
  function revealVote(
                      RegistryEntryLib.VoteOption _voteOption,
                      string _salt
                      )
    external
    notEmergency
  {
    address _voter=msg.sender;
    require(challenge.isVoteRevealPeriodActive());
    require(keccak256(abi.encodePacked(uint(_voteOption), _salt)) == challenge.vote[_voter].secretHash);
    require(!challenge.isVoteRevealed(_voter));

    challenge.vote[_voter].revealedOn = now;
    uint amount = challenge.vote[_voter].amount;
    require(registryToken.transfer(_voter, amount));
    challenge.vote[_voter].option = _voteOption;

    if (_voteOption == RegistryEntryLib.VoteOption.VoteFor) {
      challenge.votesFor = challenge.votesFor.add(amount);
    } else if (_voteOption == RegistryEntryLib.VoteOption.VoteAgainst) {
      challenge.votesAgainst = challenge.votesAgainst.add(amount);
    } else {
      revert();
    }

    uint voteId = uint(keccak256(abi.encodePacked(uint(this),"challenge",_voter)));

    factsDb.transactUInt(voteId, "vote/option", uint(challenge.vote[_voter].option));
    factsDb.transactUInt(voteId, "vote/revealed-on", now);

  }

  /**
   * @dev Refunds vote deposit after reveal period
   * Can be called by anybody, to claim voter's reward to him
   * Can't be called if vote was revealed
   * Can't be called twice for the same vote

   * @param _voter Address of a voter
   */
  function reclaimVoteAmount(address _voter)
    public
    notEmergency {

    /* if (_voter == 0x0) { */
    /*   _voter = msg.sender; */
    /* } */

    require(challenge.isVoteRevealPeriodOver());
    require(!challenge.isVoteRevealed(_voter));
    require(!challenge.isVoteAmountReclaimed(_voter));

    uint amount = challenge.vote[_voter].amount;
    require(registryToken.transfer(_voter, amount));

    challenge.vote[_voter].reclaimedVoteAmountOn = now;

    uint voteId = uint(keccak256(abi.encodePacked(uint(this),"challenge",_voter)));
    factsDb.transactUInt(voteId, "vote/reclaimed-amount-on", now);

  }

  /**
   * @dev Claims vote reward after reveal period
   * Voter has reward only if voted for winning option
   * Voter has reward only when revealed the vote
   * Can be called by anybody, to claim voter's reward to him

   * @param _voter Address of a voter
   */
  function claimVoteReward(
                           address _voter
                           )
    external
    notEmergency
  {

    /* if (_voter == 0x0) { */
    /*   _voter = msg.sender; */
    /* } */

    require(challenge.isVoteRevealPeriodOver());
    require(!challenge.isVoteRewardClaimed(_voter));
    require(challenge.isVoteRevealed(_voter));
    require(challenge.votedWinningVoteOption(_voter));

    uint reward = challenge.voteReward(_voter);

    require(reward > 0);
    require(registryToken.transfer(_voter, reward));
    challenge.vote[_voter].claimedRewardOn = now;

    uint voteId = uint(keccak256(abi.encodePacked(uint(this),"challenge",_voter)));
    factsDb.transactUInt(voteId, "vote/reclaimed-reward-on", now);

  }

  /**
   * @dev Claims challenger's reward after reveal period
   * Challenger has reward only if winning option is VoteAgainst
   * Can be called by anybody, to claim challenger's reward to him/her
   */
  function claimChallengeReward()
    external
    notEmergency
  {
    require(challenge.isVoteRevealPeriodOver());
    require(!challenge.isChallengeRewardClaimed());
    require(!challenge.isWinningOptionVoteFor());
    require(registryToken.transfer(challenge.challenger, challenge.challengeReward(deposit)));

    challenge.claimedRewardOn = now;

    uint challengeId = uint(keccak256(abi.encodePacked(uint(this),"challenge")));

    factsDb.transactUInt(challengeId, "challenge/reclaimed-reward-on", now);
    factsDb.transactUInt(challengeId, "challenge/reclaimed-amount", challenge.challengeReward(deposit));


  }

  /**
   * @dev Function called by MiniMeToken when somebody calls approveAndCall on it.
   * This way token can be transferred to a recipient in a single transaction together with execution
   * of additional logic

   * @param _from Sender of transaction approval
   * @param _amount Amount of approved tokens to transfer
   * @param _token Token that received the approval
   * @param _data Bytecode of a function and passed parameters, that should be called after token approval
   */
  function receiveApproval(
                           address _from,
                           uint256 _amount,
                           address _token,
                           bytes _data)
    public
  {
    require(address(this).call(_data));
  }

}
