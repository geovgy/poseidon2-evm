// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import {LibPoseidon2Yul} from "./LibPoseidon2Yul.sol";

/// @notice Poseidon2 hash function optimized in Yul assembly
/// @dev ABI-compatible with IPoseidon2 interface
/// Supports hash_1(uint256), hash_2(uint256,uint256), hash_3(uint256,uint256,uint256)
/// Security: https://github.com/zemse/poseidon2-evm/blob/main/SECURITY.md
contract Poseidon2Yul_BN254 {
    uint256 private constant PRIME = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;

    /// @notice Hash a dynamic-length array of field elements (ABI: hash(uint256[]))
    /// @dev Inputs are treated as field elements mod PRIME (addmod handles reduction).
    function hash(uint256[] calldata inputs) external pure returns (uint256) {
        uint256 n = inputs.length;
        uint256 state0;
        uint256 state1;
        uint256 state2;
        uint256 state3 = n << 64;

        uint256 i;
        for (; i + 3 <= n; i += 3) {
            assembly {
                state0 := addmod(state0, calldataload(add(inputs.offset, mul(i, 0x20))), PRIME)
                state1 := addmod(state1, calldataload(add(inputs.offset, mul(add(i, 1), 0x20))), PRIME)
                state2 := addmod(state2, calldataload(add(inputs.offset, mul(add(i, 2), 0x20))), PRIME)
            }
            (state0, state1, state2, state3) = LibPoseidon2Yul.permute(state0, state1, state2, state3);
        }

        uint256 rem = n - i;
        if (rem != 0 || n == 0) {
            if (rem >= 1) {
                uint256 v0 = inputs[i];
                assembly {
                    state0 := addmod(state0, v0, PRIME)
                }
            }
            if (rem >= 2) {
                uint256 v1 = inputs[i + 1];
                assembly {
                    state1 := addmod(state1, v1, PRIME)
                }
            }
            (state0, state1, state2, state3) = LibPoseidon2Yul.permute(state0, state1, state2, state3);
        }

        return state0;
    }

    fallback() external {
        uint256 state0;
        uint256 state1;
        uint256 state2;
        uint256 state3;

        uint256 n;
        assembly {
            n := shr(5, sub(calldatasize(), 4))
        }

        state3 = n << 64;

        uint256 offset = 0x04;
        while (n >= 3) {
            uint256 a;
            uint256 b;
            uint256 c;
            assembly {
                a := calldataload(offset)
                b := calldataload(add(offset, 0x20))
                c := calldataload(add(offset, 0x40))
                state0 := addmod(state0, a, PRIME)
                state1 := addmod(state1, b, PRIME)
                state2 := addmod(state2, c, PRIME)
            }
            (state0, state1, state2, state3) = LibPoseidon2Yul.permute(state0, state1, state2, state3);
            offset += 0x60;
            n -= 3;
        }

        if (n != 0 || (state3 == 0)) {
            if (n >= 1) {
                uint256 a;
                assembly {
                    a := calldataload(offset)
                    state0 := addmod(state0, a, PRIME)
                }
            }
            if (n >= 2) {
                uint256 b;
                assembly {
                    b := calldataload(add(offset, 0x20))
                    state1 := addmod(state1, b, PRIME)
                }
            }
            (state0, state1, state2, state3) = LibPoseidon2Yul.permute(state0, state1, state2, state3);
        }

        uint256 result = state0;

        assembly {
            mstore(0, result)
            return(0, 32)
        }
    }
}
