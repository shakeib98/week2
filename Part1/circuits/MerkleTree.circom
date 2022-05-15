pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mux1.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    var totalLeaves = 2**n;
    signal input leaves[totalLeaves];
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves
    signal totalHashes[totalLeaves-1];
    component poseidon[totalLeaves-1];

    var indexHashes=0;
    var leavesIndex = 0;

    var leafHashesLenght = totalLeaves/2;

    for(var i=0; i<leafHashesLenght; i++){
        poseidon[i].inputs[0] <== leaves[leavesIndex];
        poseidon[i].inputs[1] <== leaves[leavesIndex+1];

        leavesIndex = leavesIndex+2;

        totalHashes[i] <== poseidon[i].out;
    }

    for(var i=leafHashesLenght; i<totalLeaves-1; i++){
        poseidon[i].inputs[0] <== totalHashes[indexHashes];
        poseidon[i].inputs[0] <== totalHashes[indexHashes+1];

        indexHashes = indexHashes +2;

        totalHashes[i] <== poseidon[i].out;
    }

    root <== totalHashes[totalLeaves-1];

}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path

    component poseidon[n];
    component mux[n];

    signal hashes[n+1];

    hashes[0] <== leaf;

    for(var i=0; i<n; i++){
        poseidon[i] = Poseidon(2);
        mux[i] = MultiMux1(2);

        mux[i].c[0][0] <== hashes[i];
        mux[i].c[0][1] <== path_elements[i];

        mux[i].c[1][0] <== path_elements[i];
        mux[i].c[1][1] <== hashes[i];

        mux[i].s <== path_index[i];

        poseidon[i].inputs[0] <== mux[i].out[0];
        poseidon[i].inputs[1] <== mux[i].out[1];

        hashes[i+1] <== poseidon[i].out;

        
    }
    root <== hashes[n];
}