// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract test1 {

    /**
        一个mapping来存储候选人的得票数,
        一个vote函数，允许用户投票给某个候选人,
        一个getVotes函数，返回某个候选人的得票数,
        一个resetVotes函数，重置所有候选人的得票数
    **/

    // 计票map
    mapping (address => uint) private votesMap;
    // 候选人列表
    address[] private candidates;

    function vote(address candidate) public {
        // 零值，候选人不存在，push
        if (votesMap[candidate] == 0) {
            candidates.push(candidate);
        }
        votesMap[candidate] += 1;
    }

    // 根据address获取得票数
    function getvotes(address candidate) public view returns (uint voteCount) {
        return votesMap[candidate];
    }

    // 重置候选人票数
    function resetVotes() public {
        for (uint i = 0; i < candidates.length; i++) {
            // delete，删除仅会重置为零值，不会删除key
            delete votesMap[candidates[i]];
        }
    }
}