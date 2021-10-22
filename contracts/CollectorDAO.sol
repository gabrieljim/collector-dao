//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface NftMarketplace {
    function getPrice(uint256 id) external view returns (uint256);

    function purchase(uint256 id) external;
}

contract CollectorDAO is Ownable {
    mapping(address => bool) public isMember;
    mapping(address => uint256) public contributedBy;
    mapping(address => uint256) public votingPower;
    mapping(address => mapping(address => bool)) public delegatedVote;
    mapping(uint256 => Proposal) public proposals;

    string private greeting;
    uint256 public memberCount;
    uint256 public proposalCounter;

    struct Proposal {
        address nftMarket;
        uint256 nftId;
        uint256 deadline;
        uint256 yay;
        uint256 nay;
        uint256 voteCount;
        bool alreadyExecuted;
        mapping(address => bool) alreadyVoted;
    }

    enum Vote {
        NO,
        YES
    }

    modifier activeProposal(uint256 proposalId) {
        uint256 quorum = Math.ceilDiv(25 * memberCount, 100);

        Proposal storage proposal = proposals[proposalId];
        console.log(proposal.deadline, block.timestamp);
        // If proposal is above deadline
        if (proposals[proposalId].deadline < block.timestamp) {
            // Less than 25% voted
            require(
                proposals[proposalId].voteCount >= quorum,
                "PROPOSAL_FAILED_NOT_ENOUGH_VOTES"
            );

            // At least one more vote in favor than against
            require(
                proposals[proposalId].yay > proposals[proposalId].nay,
                "PROPOSAL_FAILED_NOT_ENOUGH_YES_VOTES"
            );

            // These could probably be combined into one require statement, but on solidity I prefer going for readability
        }
        _;
    }

    modifier memberOnly() {
        require(isMember[msg.sender], "NOT_A_MEMBER");
        _;
    }

    function createProposal(
        address _nftMarket,
        uint256 _nftId,
        uint256 _deadline
    ) external memberOnly returns (uint256) {
        proposalCounter++;
        Proposal storage proposal = proposals[proposalCounter];
        proposal.nftMarket = _nftMarket;
        proposal.nftId = _nftId;
        proposal.deadline = _deadline;

        //return proposal id
        return proposalCounter;
    }

    function delegateVote(address _accountToDelegateTo) external {
        require(
            isMember[_accountToDelegateTo] && isMember[msg.sender],
            "NOT_A_MEMBER"
        );

        delegatedVote[_accountToDelegateTo][msg.sender] = true;
        votingPower[_accountToDelegateTo] += 1;
    }

    function undoDelegation(address _accountToRemoveDelegationFrom) external {
        require(
            delegatedVote[_accountToRemoveDelegationFrom][msg.sender],
            "NOT_DELEGATED"
        );

        delegatedVote[_accountToRemoveDelegationFrom][msg.sender] = false;
        if (votingPower[_accountToRemoveDelegationFrom] > 0) {
            votingPower[_accountToRemoveDelegationFrom] -= 1;
        }
    }

    function voteOnProposal(uint256 proposalId, Vote vote)
        external
        activeProposal(proposalId)
    {
        Proposal storage proposal = proposals[proposalId];
        _vote(proposal, msg.sender, vote);
    }

    function voteOnProposalFrom(
        uint256 proposalId,
        Vote vote,
        address voteFrom
    ) external activeProposal(proposalId) {
        require(delegatedVote[msg.sender][voteFrom], "NOT_ALLOWED");
        Proposal storage proposal = proposals[proposalId];
        _vote(proposal, voteFrom, vote);
    }

    function _vote(
        Proposal storage proposal,
        address account,
        Vote vote
    ) internal memberOnly {
        proposal.alreadyVoted[account] = true;
        proposal.voteCount++;
        if (vote == Vote.YES) {
            proposal.yay++;
        } else {
            proposal.nay++;
        }
    }

    function executeSuccesfulProposal(uint256 proposalId)
        external
        activeProposal(proposalId)
        onlyOwner
    {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.alreadyExecuted, "ALREADY_EXECUTED");

        uint256 nftPrice = NftMarketplace(proposal.nftMarket).getPrice(
            proposal.nftId
        );

        require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS_TO_BUY");

        proposal.alreadyExecuted = true;

        NftMarketplace(proposal.nftMarket).purchase(proposal.nftId);
    }

    function contribute() external payable {
        contributedBy[msg.sender] += msg.value;
        if (contributedBy[msg.sender] >= 1 ether && !isMember[msg.sender]) {
            _giveMembership(msg.sender);
        }
    }

    function _giveMembership(address account) internal {
        isMember[account] = true;
        memberCount++;
    }
}
