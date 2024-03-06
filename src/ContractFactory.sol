// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Create3} from "@0xsequence/create3/contracts/Create3.sol";
import {SSTORE2} from "@0xsequence/sstore2/contracts/SSTORE2.sol";

contract ContractFactory {
    mapping(bytes32 => address) public cache;

    event CodeAdded(bytes32 indexed creationCodeHash, address indexed pointer);
    event CodeRemoved(bytes32 indexed creationCodeHash, address indexed pointer);
    event ContractDeployed(address indexed deployer, address indexed addr);
    event ContractDeployed(address indexed deployer, address indexed addr, bytes32 salt);

    error TemplateNotFound();
    error InvalidSalt();

    function storeCode(bytes calldata creationCode) external {
        bytes32 codeHash = keccak256(creationCode);
        address pointer = SSTORE2.write(creationCode);
        cache[codeHash] = pointer;
        emit CodeAdded(codeHash, pointer);
    }

    function removeCode(bytes32 codeHash) external {
        address pointer = cache[codeHash];
        delete cache[codeHash];
        emit CodeRemoved(codeHash, pointer);
    }

    function deploy(bytes32 templateHash, bytes calldata constructorArgs) external {
        _deploy(templateHash, constructorArgs);
    }

    function deploy2(bytes32 templateHash, bytes32 salt, bytes calldata constructorArgs) external {
        _deploy2(templateHash, salt, constructorArgs);
    }

    function deploy3(bytes32 templateHash, bytes32 salt, bytes calldata constructorArgs) external {
        _deploy3(templateHash, salt, constructorArgs);
    }

    function saferDeploy2(bytes32 templateHash, bytes32 salt, bytes calldata constructorArgs) external {
        if (address(bytes20(salt)) != msg.sender) revert InvalidSalt();
        _deploy2(templateHash, salt, constructorArgs);
    }

    function saferDeploy3(bytes32 templateHash, bytes32 salt, bytes calldata constructorArgs) external {
        if (address(bytes20(salt)) != msg.sender) revert InvalidSalt();
        _deploy3(templateHash, salt, constructorArgs);
    }

    function _deploy3(bytes32 templateHash, bytes32 salt, bytes calldata constructorArgs) internal {
        address templatePointer = cache[templateHash];
        if (templatePointer == address(0)) {
            revert TemplateNotFound();
        }

        bytes memory templateCode = SSTORE2.read(templatePointer);
        bytes memory initCode = abi.encodePacked(templateCode, constructorArgs);
        address contractAddress = Create3.create3(salt, initCode);

        emit ContractDeployed(msg.sender, contractAddress, salt);
    }
    function _deploy(bytes32 templateHash, bytes calldata constructorArgs) internal {
        address templatePointer = cache[templateHash];
        if (templatePointer == address(0)) {
            revert TemplateNotFound();
        }

        bytes memory templateCode = SSTORE2.read(templatePointer);
        bytes memory initCode = abi.encodePacked(templateCode, constructorArgs);
        address contractAddress;
        assembly {
            contractAddress := create(0, add(initCode, 32), mload(initCode))
        }

        emit ContractDeployed(msg.sender, contractAddress);
    }

    function _deploy2(bytes32 templateHash, bytes32 salt, bytes calldata constructorArgs) internal {
        address templatePointer = cache[templateHash];
        if (templatePointer == address(0)) {
            revert TemplateNotFound();
        }

        bytes memory templateCode = SSTORE2.read(templatePointer);
        bytes memory initCode = abi.encodePacked(templateCode, constructorArgs);
        address contractAddress;
        assembly {
            contractAddress := create2(0, add(initCode, 32), mload(initCode), salt)
        }

        emit ContractDeployed(msg.sender, contractAddress, salt);
    }
}
