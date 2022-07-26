// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.6;

import "../src/users/Actor.sol";
import "../lib/forge-std/src/Vm.sol";
import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/lib/ds-test/src/test.sol";

contract PolygonUtility is Test {

    /**********************************/
    /*** Polygon Contract Addresses ***/
    /**********************************/

    // Mainnet Addresses

    address constant MATIC  = 0x0000000000000000000000000000000000001010;  // https://polygonscan.com/token/0x0000000000000000000000000000000000001010  Decimals: 18
    address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;  // https://polygonscan.com/token/0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270  Decimals: 18
    address constant DAI    = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;  // https://polygonscan.com/token/0x8f3cf7ad23cd3cadbd9735aff958023239c6a063
    address constant USDC   = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;  // https://polygonscan.com/token/0x2791bca1f2de4661ed88a30c99a7a9449aa84174
    address constant USDT   = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;  // https://polygonscan.com/token/0xc2132d05d31c914a87c6611c10748aeb04b58e8f
    address constant WBTC   = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;  // https://polygonscan.com/token/0x1bfd67037b42cf73acf2047067bd4f2c47d9bfd6

    /**************/
    /*** Actors ***/
    /**************/

    Actor  dev = new Actor(); // Owner/Dev
    Actor  arn = new Actor(); // Aaron/Admin
    Actor  mgr = new Actor(); // Account Manager
    Actor  joe = new Actor(); // Stakeholder

    /*****************/
    /*** Constants ***/
    /*****************/

    uint256 constant USD = 10 ** 6;
    uint256 constant BTC = 10 ** 8;
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;

    /*****************/
    /*** Utilities ***/
    /*****************/

    struct Token {
        address addr; // ERC20 Mainnet address
        uint256 slot; // Balance storage slot
        address orcl; // Chainlink oracle address
    }
 
    mapping (bytes32 => Token) tokens;
    
    event Debug(string, uint256);
    event Debug(string, address);
    event Debug(string, bool);
    
    event logUint(string, uint256);

    /******************************/
    /*** Test Utility Functions ***/
    /******************************/

    function setUpTokens() public {

        tokens["USDC"].addr = USDC;
        tokens["USDC"].slot = 9;

        tokens["DAI"].addr = DAI;
        tokens["DAI"].slot = 2;
        //tokens["DAI"].orcl = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;

        //tokens["WETH"].addr = WETH;
        //tokens["WETH"].slot = 3;
        //tokens["WETH"].orcl = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

        tokens["WBTC"].addr = WBTC;
        tokens["WBTC"].slot = 0;
        //tokens["WBTC"].orcl = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c;
    }

    // Manipulate mainnet ERC20 balance.
    function mint(bytes32 symbol, address account, uint256 amt) public {
        address addr = tokens[symbol].addr;
        uint256 slot  = tokens[symbol].slot;
        uint256 bal = IERC20(addr).balanceOf(account);

        // use Foundry's vm to call store cheatcode
        vm.store(
            addr,
            keccak256(abi.encode(account, slot)), // Mint tokens
            bytes32(bal + amt)
        );

        assertEq(IERC20(addr).balanceOf(account), bal + amt); // Assert new balance
    }


    // Verify equality within accuracy decimals
    function withinPrecision(uint256 val0, uint256 val1, uint256 accuracy) public {
        uint256 diff  = val0 > val1 ? val0 - val1 : val1 - val0;
        if (diff == 0) return;

        uint256 denominator = val0 == 0 ? val1 : val0;
        bool check = ((diff * RAY) / denominator) < (RAY / 10 ** accuracy);

        if (!check){
            emit logUint("Error: approx a == b not satisfied, accuracy digits ", accuracy);
            emit logUint("  Expected", val0);
            emit logUint("    Actual", val1);
            //fail();
        }
    }

    // Verify equality within difference
    function withinDiff(uint256 val0, uint256 val1, uint256 expectedDiff) public {
        uint256 actualDiff = val0 > val1 ? val0 - val1 : val1 - val0;
        bool check = actualDiff <= expectedDiff;

        if (!check) {
            emit logUint("Error: approx a == b not satisfied, accuracy difference ", expectedDiff);
            emit logUint("  Expected", val0);
            emit logUint("    Actual", val1);
            //fail();
        }
    }

    function constrictToRange(uint256 val, uint256 min, uint256 max) public pure returns (uint256) {
        return constrictToRange(val, min, max, false);
    }

    function constrictToRange(uint256 val, uint256 min, uint256 max, bool nonZero) public pure returns (uint256) {
        if      (val == 0 && !nonZero) return 0;
        else if (max == min)           return max;
        else                           return val % (max - min) + min;
    }

}