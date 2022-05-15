#!/bin/bash

cd ../circuits

mkdir MerkleTree

if [ -f ./powersOfTau28_hez_final_10.ptau ]; then
    echo "powersOfTau28_hez_final_10.ptau already exists. Skipping."
else
    echo 'Downloading powersOfTau28_hez_final_10.ptau'
    wget https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_10.ptau
fi

echo "Compiling circuit.circom..."

# compile circuit

circom circuit.circom --r1cs --wasm --sym -o MerkleTree
snarkjs r1cs info MerkleTree/circuit.r1cs

# # Start a new zkey and make a contribution

snarkjs groth16 setup MerkleTree/circuit.r1cs powersOfTau28_hez_final_10.ptau MerkleTree/circuit_0000.zkey
snarkjs zkey contribute MerkleTree/circuit_0000.zkey MerkleTree/circuit_final.zkey --name="1st Contributor Name" -v -e="random text"
snarkjs zkey export verificationkey MerkleTree/circuit_final.zkey MerkleTree/verification_key.json

# generate solidity contract
snarkjs zkey export solidityverifier MerkleTree/circuit_final.zkey ../contracts/verifier.sol

cd ..
