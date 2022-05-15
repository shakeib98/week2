//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract


contract MerkleTree is Verifier{
    uint256 public constant TREE_LEVELS = 3;
    uint256 public constant MAX_NODES = 15;
    uint256 public constant NUMBER_OF_LEAVES = 8;
    
    uint256[MAX_NODES] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root

    


    constructor() public {
        // [assignment] initialize a Merkle tree of 8 with blank leaves

        for(uint8 i=0; i<NUMBER_OF_LEAVES; i++){
            hashes[i]=0;
        }

        uint8 offset = 0;

        for(uint256 i=NUMBER_OF_LEAVES; i<MAX_NODES; i++){
            hashes[i] = hashElements(hashes[offset], hashes[offset+1]);

            offset+=2;
        }

        root = hashes[MAX_NODES-1];
        
    }

    function hashElements(uint256 _left, uint256 _right) internal returns (uint256){
        uint256[2] memory input;
        input[0] = _left;
        input[1] = _right;
        return PoseidonT3.poseidon(input);
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree

        uint256 left;
        uint256 right;

        uint256 currentHash = hashedLeaf;
        uint256 currentIndex = index;

        uint256 levelIndex = index;

        hashes[index] = hashedLeaf;

        for(uint8 i=0; i<TREE_LEVELS; i++){

            if(currentIndex % 2 == 0){
                left = currentHash;
                right = hashes[currentIndex+1];

                levelIndex = (levelIndex / 2) + NUMBER_OF_LEAVES;
                
                hashes[levelIndex] = hashElements(left, right);
            }else{
                
                left = hashes[currentIndex-1];
                right = currentHash;

                levelIndex = ((levelIndex-1) / 2) + NUMBER_OF_LEAVES;
                
                hashes[levelIndex] = hashElements(left, right);
            }

            currentHash = hashes[levelIndex];

            currentIndex = levelIndex; 
        }

        root = hashes[MAX_NODES-1];

        index++;

        return root;
    }

    function verify(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input
        ) public view returns (bool) {

        // [assignment] verify an inclusion proof and check that the proof root matches current root
        require(input[0] == root, "Root not matched");
        return verifyProof(a,b,c,input);
    }
}
