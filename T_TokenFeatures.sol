pragma solidity ^0.4.15;
import './T_BaseToken.sol';
import './T_DateTime.sol';


contract DividendInEthEnabledToken is BaseToken{

    //to avoid rounding off errors
    uint256 constant pointsMultiplier = 10e18;
    uint256 totalDividendPoints;

    mapping (address => uint256) lastDividendPoints;

    function dividendOwing(address account) internal returns(uint256){
        var newDividendPoints = totalDividendPoints.sub(lastDividendPoints[account]);
        return (balances[account].mul(newDividendPoints)).div(pointsMultiplier);
    }
    
    function updateAccount(address account) {
        var owing = dividendOwing(account);
        if(owing > 0) {
            lastDividendPoints[account] = totalDividendPoints;
            msg.sender.transfer(owing);
            Dividend(account,owing);
        }
    }
    
    function disburse() payable {
        require(msg.sender == owner && msg.value >0);
        totalDividendPoints = totalDividendPoints.add((msg.value.mul(pointsMultiplier)).div(totalSupply));
        //owner.transfer(msg.value);
    }
    
    function claimDividend(){
        //this will just run the updateAccount modifier
        updateAccount(msg.sender);
    }
    
    function checkBalance() returns (uint256) {
        return this.balance;
    }
    
    event Dividend(address indexed account, uint256 amount);
}



contract VotingEnabledToken_blocking is DateTime,BaseToken {

    uint256 _totalSupply = 100;
    
    struct proposal {
        string description;
        uint256 yays;
        uint256 nays;
        mapping(address=>bool) voted;
        address owner;
        uint deadline; //timestamp
        mapping(address=>int256) voters;//key is the address and the value is the no. of tokens held by the member
        
    }
    
    mapping(address=>uint) blockedTill; //stores timestamp of time till a particular address is blocked

    mapping(uint=>proposal) public voting;
    uint8 latestProposalIndex = 1;

    //event Transfer(address indexed _from, address indexed _to, uint _value);
    //event Approval(address indexed _owner, address indexed _spender, uint _value);

    event Vote(address indexed _by,uint8 indexed _voteIndex, string _vote);

    function createProposal(string _desc,uint8 _daysOpen) {
        voting[latestProposalIndex].owner = msg.sender;
        voting[latestProposalIndex].description = _desc;
        voting[latestProposalIndex].yays=0;
        voting[latestProposalIndex].nays=0;
        //voting[latestProposalIndex].deadline = addDaystoTimeStamp(_daysOpen);
        //for testing adding minutes rather than days
        voting[latestProposalIndex].deadline = addMinutestoTimeStamp(_daysOpen);
        latestProposalIndex += 1;
        
    }

    function vote(uint8 _index, uint256 _response){ //1 for Yes 0 for No
        require(balances[msg.sender] > 0);
        require(!compareDates(voting[_index].deadline,now));        
        require(voting[_index].voters[msg.sender]==0);
        if(_response == 1 ){
            voting[_index].yays = voting[_index].yays.add(balances[msg.sender]);//INCREASE BY balance IF 1 token 1 vote
            voting[_index].voters[msg.sender]=int256(balances[msg.sender]);
            blockedTill[msg.sender]=voting[_index].deadline;
            Vote(msg.sender,_index,"yes");
        } else if (_response == 0){
            voting[_index].nays = voting[_index].nays.add(balances[msg.sender]);            
            voting[_index].voters[msg.sender]=-int256(balances[msg.sender]);
            blockedTill[msg.sender]=voting[_index].deadline;
            Vote(msg.sender,_index,"no");
        }
    }
    
    
    function voteResult(uint8 _index) returns (string description,uint256 yays,uint256 nays, address owner,uint deadline,int256){
        require(compareDates(voting[_index].deadline,now));
        return (
            voting[_index].description,
            voting[_index].yays,
            voting[_index].nays,
            voting[_index].owner,
            voting[_index].deadline,
            voting[_index].voters[msg.sender]
        );
    }
    
    function transfer(address _to, uint _value) returns (bool success){
        //_value = _value.mul(1e18);
        require(
            balances[msg.sender]>=_value 
            && _value > 0
            && compareDates(blockedTill[msg.sender],now)
        );
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender,_to,_value);
        return true;
    }
    
    
}


contract fileUploadEnabled is BaseToken {
    
    uint fileNumber=0;
    
    struct file{
        string hash;
        string name;
        string desc;
    }
    mapping(uint=>file) public fileStorage;
    function uploadFileHash(string fileHash, string fileName, string fileDescription){
        require(msg.sender==owner);
        fileStorage[fileNumber].hash = fileHash;
        fileStorage[fileNumber].name = fileName;
        fileStorage[fileNumber].desc = fileDescription;
    }

}