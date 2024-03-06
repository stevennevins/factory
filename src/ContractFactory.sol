// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Create3} from "@0xsequence/create3/contracts/Create3.sol";
import {SSTORE2} from "@0xsequence/sstore2/contracts/SSTORE2.sol";

contract ContractFactory {
    mapping(bytes32 => address) public cache;

    event CodeAdded(bytes32 indexed codehash, address indexed pointer, string name);
    event CodeRemoved(bytes32 indexed codehash, address indexed pointer);
    event ContractDeployed(address indexed deployer, bytes32 indexed codehash, address indexed addr);
    event ContractDeployed(address indexed deployer, bytes32 indexed codehash, address indexed addr, bytes32 salt);

    error CodeNotFound();
    error InvalidSalt();

    function storeCode(bytes calldata creationCode, string calldata name) external {
        bytes32 codehash = keccak256(creationCode);
        address pointer = SSTORE2.write(creationCode);
        cache[codehash] = pointer;
        emit CodeAdded(codehash, pointer, name);
    }

    function removeCode(bytes32 codehash) external {
        address pointer = cache[codehash];
        delete cache[codehash];
        emit CodeRemoved(codehash, pointer);
    }

    function deploy(bytes32 codehash, bytes calldata constructorArgs) external {
        _deploy(codehash, constructorArgs);
    }

    function deploy2(bytes32 codehash, bytes32 salt, bytes calldata constructorArgs) external {
        _deploy2(codehash, salt, constructorArgs);
    }

    function deploy3(bytes32 codehash, bytes32 salt, bytes calldata constructorArgs) external {
        _deploy3(codehash, salt, constructorArgs);
    }

    function saferDeploy2(bytes32 codehash, bytes32 salt, bytes calldata constructorArgs) external {
        if (address(bytes20(salt)) != msg.sender) {
            revert InvalidSalt();
        }
        _deploy2(codehash, salt, constructorArgs);
    }

    function saferDeploy3(bytes32 codehash, bytes32 salt, bytes calldata constructorArgs) external {
        if (address(bytes20(salt)) != msg.sender) {
            revert InvalidSalt();
        }
        _deploy3(codehash, salt, constructorArgs);
    }

    function _deploy3(bytes32 codehash, bytes32 salt, bytes calldata constructorArgs) internal {
        address pointer = cache[codehash];
        if (pointer == address(0)) {
            revert CodeNotFound();
        }

        bytes memory creationCode = SSTORE2.read(pointer);
        bytes memory initCode = abi.encodePacked(creationCode, constructorArgs);
        address contractAddress = Create3.create3(salt, initCode);

        emit ContractDeployed(msg.sender, codehash, contractAddress, salt);
    }
    function _deploy(bytes32 codehash, bytes calldata constructorArgs) internal {
        address pointer = cache[codehash];
        if (pointer == address(0)) {
            revert CodeNotFound();
        }

        bytes memory creationCode = SSTORE2.read(pointer);
        bytes memory initCode = abi.encodePacked(creationCode, constructorArgs);
        address contractAddress;
        assembly {
            contractAddress := create(0, add(initCode, 32), mload(initCode))
        }

        emit ContractDeployed(msg.sender, codehash, contractAddress);
    }

    function _deploy2(bytes32 codehash, bytes32 salt, bytes calldata constructorArgs) internal {
        address pointer = cache[codehash];
        if (pointer == address(0)) {
            revert CodeNotFound();
        }

        bytes memory creationCode = SSTORE2.read(pointer);
        bytes memory initCode = abi.encodePacked(creationCode, constructorArgs);
        address contractAddress;
        assembly {
            contractAddress := create2(0, add(initCode, 32), mload(initCode), salt)
        }

        emit ContractDeployed(msg.sender, codehash, contractAddress, salt);
    }
}
