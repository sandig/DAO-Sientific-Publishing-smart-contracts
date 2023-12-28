// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract StakeholdersDAO {

    mapping(address => Stakeholder) public stakeholder;
    address[] activeEditors;
    address public owner;


    struct Stakeholder {
        bool isValid;
        StakeholderGroup stakeholderGroup;
        StakeholderStatus stakeholderStatus;
        string[] tags;
        address[] awaitEditors;
        // additional properties of the stakeholder
    }

    enum StakeholderGroup {
        Author, Reader, Reviewers, Editor
    }

    enum StakeholderStatus {
        Pending, Active, Deactivated
    }

    event NotifyActiveEditors(address _address);
    event StakeholderIsRegistered(address _address);
    event NewEditorRegistered(address _address);
    event EditorApprovedByAnEditor(address editor, address endorsedEditor);

    constructor() {
        owner = msg.sender;
        activeEditors.push(owner);
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "only the owner is allowed to trigger the function");
        _;
    }

    modifier validStakeholder(uint stakeholderGroup) {
        require(stakeholderGroup == 1 || stakeholderGroup == 2 || stakeholderGroup == 3, "only stakeholder groups [1-3] are allowed");
        _;
    }

    function registerStakeholder(uint _stakeholderGroup) public validStakeholder(_stakeholderGroup)
    {
        address _address = msg.sender;
        require(!stakeholder[_address].isValid, "the address is already registered");
        stakeholder[_address].isValid = true;

        if (_stakeholderGroup == 1 || _stakeholderGroup == 2 || _stakeholderGroup == 3) {
            stakeholder[_address].stakeholderGroup = _stakeholderGroup == 1 ? StakeholderGroup.Author : StakeholderGroup.Reader;
            stakeholder[_address].stakeholderStatus = StakeholderStatus.Active;
            emit StakeholderIsRegistered(_address);
        }
        else {
            //create a copy of the curently active verifying agents
            stakeholder[_address].awaitEditors = activeEditors;
            stakeholder[_address].stakeholderGroup = StakeholderGroup.Editor;
            stakeholder[_address].stakeholderStatus = StakeholderStatus.Pending;
            emit NotifyActiveEditors(_address);
        }
    }

    function registerTag(string memory tag) public onlyReviewer {
        stakeholder[msg.sender].tags.push(tag);
    }

    function confirmEditor(address _address) public onlyActiveEditors {
        bool found = false;

        for (uint8 i = 0; i < stakeholder[_address].awaitEditors.length; i++) {
            if (stakeholder[_address].awaitEditors[i] == msg.sender) {
                delete stakeholder[_address].awaitEditors[i];
                found = true;
                break;
            }
        }

        if (found && stakeholder[_address].awaitEditors.length == 0) {
            stakeholder[_address].stakeholderStatus = StakeholderStatus.Active;
            activeEditors.push(_address);
            emit NewEditorRegistered(_address);
        }
        else if (found) emit EditorApprovedByAnEditor(msg.sender, _address);
        else revert("invalid verifying agent or the agent already voted");
    }

    modifier onlyReviewer() {
        require(StakeholderGroup.Reviewers == stakeholder[msg.sender].stakeholderGroup, "caller should be reviewer");
        _;
    }

    modifier onlyActiveEditors() {
        require(owner == msg.sender || (StakeholderGroup.Editor == stakeholder[msg.sender].stakeholderGroup &&
        stakeholder[msg.sender].stakeholderStatus == StakeholderStatus.Active), "only the owner is allowed to trigger the function");
        _;
    }
}