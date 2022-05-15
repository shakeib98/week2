const { poseidonContract } = require("circomlibjs");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { groth16 } = require("snarkjs");

function unstringifyBigInts(o) {
    if ((typeof(o) == "string") && (/^[0-9]+$/.test(o) ))  {
        return BigInt(o);
    } else if ((typeof(o) == "string") && (/^0x[0-9a-fA-F]+$/.test(o) ))  {
        return BigInt(o);
    } else if (Array.isArray(o)) {
        return o.map(unstringifyBigInts);
    } else if (typeof o == "object") {
        if (o===null) return null;
        const res = {};
        const keys = Object.keys(o);
        keys.forEach( (k) => {
            res[k] = unstringifyBigInts(o[k]);
        });
        return res;
    } else {
        return o;
    }
}

describe("MerkleTree", function () {
    let merkleTree;

    beforeEach(async function () {

        const PoseidonT3 = await ethers.getContractFactory(
            poseidonContract.generateABI(2),
            poseidonContract.createCode(2)
        )
        const poseidonT3 = await PoseidonT3.deploy();
        await poseidonT3.deployed();

        const MerkleTree = await ethers.getContractFactory("MerkleTree", {
            libraries: {
                PoseidonT3: poseidonT3.address
            },
          });

        merkleTree = await MerkleTree.deploy();
        await merkleTree.deployed();
    });

    it("Insert two new leaves and verify the first leaf in an inclusion proof", async function () {
        
        await merkleTree.insertLeaf(1);
        await merkleTree.insertLeaf(2);

        const node9 = (await merkleTree.hashes(9)).toString();
        const node13 = (await merkleTree.hashes(13)).toString();


        var Input = {
            "leaf": "1",
            "path_elements": ["2", node9, node13],
            "path_index": ["0", "0", "0"]
        }
        var { proof, publicSignals } = await groth16.fullProve(Input, "circuits/MerkleTree/circuit_js/circuit.wasm","circuits//MerkleTree/circuit_final.zkey");
        
        var editedPublicSignals = unstringifyBigInts(publicSignals);
        var editedProof = unstringifyBigInts(proof);
        var calldata = await groth16.exportSolidityCallData(editedProof, editedPublicSignals);
    
        var argv = calldata.replace(/["[\]\s]/g, "").split(',').map(x => BigInt(x).toString());
    
        var a = [argv[0], argv[1]];
        var b = [[argv[2], argv[3]], [argv[4], argv[5]]];
        var c = [argv[6], argv[7]];
        var input = argv.slice(8);

        expect(await merkleTree.verify(a, b, c, input)).to.be.true;

        // [bonus] verify the second leaf with the inclusion proof

        Input = {
            "leaf": "2",
            "path_elements": ["1", node9, node13],
            "path_index": ["1", "0", "0"]
        }

        var {proof, publicSignals} = await groth16.fullProve(Input, "circuits/MerkleTree/circuit_js/circuit.wasm","circuits//MerkleTree/circuit_final.zkey");
        console.log(publicSignals)
        editedPublicSignals = unstringifyBigInts(publicSignals);
        editedProof = unstringifyBigInts(proof);
        calldata = await groth16.exportSolidityCallData(editedProof, editedPublicSignals);
    
        argv = calldata.replace(/["[\]\s]/g, "").split(',').map(x => BigInt(x).toString());
    
        a = [argv[0], argv[1]];
        b = [[argv[2], argv[3]], [argv[4], argv[5]]];
        c = [argv[6], argv[7]];
        input = argv.slice(8);

        expect(await merkleTree.verify(a, b, c, input)).to.be.true;

    });
});
