// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./StakeholdersDAO.sol";

contract ScientificPublishingProcessDAO is StakeholdersDAO {

    enum ManuscriptStatus{
        Submitted,
        Accepted,
        Rejected
    }

    enum DecisionStatus{
        Accept,
        Minor,
        Major,
        Reject
    }

    event SuccessSubmission(string addr);
    event DecisionSubmitted(string str, address a, DecisionStatus ds);
    event FinalDecision(string str, ManuscriptStatus ms);

    mapping(string => Manuscript) public manuscript;

    struct Manuscript {
        address author;
        uint256 submissionBlock;
        ManuscriptStatus manuscriptStatus;
        mapping(address => DecisionStatus) decisionStatus;
        address reviewer1;
        address reviewer2;
        string cid;
    }

    constructor() StakeholdersDAO() {
        // may be extended with deployment specifics
    }

    // submit manuscript to be reviewed
    function manuscriptSubmission(string memory uuid) public
    {
        manuscript[uuid].author = msg.sender;
        manuscript[uuid].submissionBlock = block.timestamp;
        manuscript[uuid].manuscriptStatus = ManuscriptStatus.Submitted;
        emit SuccessSubmission(uuid);
    }

    // review manuscript - accept, reject
    function review(string memory uuid, DecisionStatus decisionStatus) public onlyReviewer
    {
        require(manuscript[uuid].reviewer1 == msg.sender || manuscript[uuid].reviewer2 == msg.sender,
            "only registered reviewers are allowed to review the manuscript");
        manuscript[uuid].decisionStatus[msg.sender] = decisionStatus;
        emit DecisionSubmitted(uuid, msg.sender, decisionStatus);
    }

    // accept or reject the manuscript
    function finalDecision(string memory uuid, ManuscriptStatus status, string memory cid) public onlyActiveEditors {
        manuscript[uuid].manuscriptStatus = status;

        if (status == ManuscriptStatus.Accepted)
            manuscript[uuid].cid = cid;

        emit FinalDecision(uuid, status);
    }

    function setReviewer1(string memory uuid, address reviewer) public onlyActiveEditors {
        require(stakeholder[reviewer].stakeholderGroup == StakeholderGroup.Reviewers ||
            stakeholder[reviewer].stakeholderGroup == StakeholderGroup.Editor && stakeholder[reviewer].isValid,
            "only active reviewers or editors are alowed");
        manuscript[uuid].reviewer1 = reviewer;
    }

    function setReviewer2(string memory uuid, address reviewer) public onlyActiveEditors {
        require(stakeholder[reviewer].stakeholderGroup == StakeholderGroup.Reviewers ||
            stakeholder[reviewer].stakeholderGroup == StakeholderGroup.Editor && stakeholder[reviewer].isValid,
            "only active reviewers or editors are alowed");
        manuscript[uuid].reviewer2 = reviewer;
    }
}