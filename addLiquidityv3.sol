// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

//import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
//import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
//import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

import "@uniswap/v3-periphery/contracts/interfaces/IPoolInitializer.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IERC721Permit.sol";
// import "@uniswap/v3-core/contracts/libraries/TransferHelper.sol";
import 'https://github.com/Uniswap/v3-periphery/blob/22a7ead071fff53f00d9ddc13434f285f4ed5c7d/contracts/libraries/TransferHelper.sol';
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
//import "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolActions.sol";
//import "https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
//import "https://github.com/alianse777/solidity-standard-library/blob/master/Math.sol";
import "https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/Babylonian.sol";


// contract Math{
  
//    function sqrt(uint x) internal pure returns (uint){
//        uint n = x / 2;
//        uint lstX = 0;
//        while (n != lstX){
//            lstX = n;
//            n = (n + x/n) / 2; 
//        }
//        return uint(n);
//    }
	
   
//    function mexp(uint x, uint k, uint m) internal pure returns (uint r) {
//        r = 1;
//        for (uint s = 1; s <= k; s *= 2) {
//            if (k & s != 0) r = mulmod(r, x, m);
//             x = mulmod(x, x, m);
//        }
//     }
    
//     function abs(int x) internal pure returns (uint) {
//         if(x < 0) {
//             return uint(-x);
//         }
//         return uint(x);
//     }
    
//     function u_pow(uint x, uint p) internal pure returns (uint) {
//         if(p == 0) return 1;
//         if(p % 2 == 1) {
//             return u_pow(x, p-1)*x;
//         }
//         else
//         {
//             return u_pow(x, p / 2)*u_pow(x, p / 2);
//         }
//     }
    
//     function pow(int x, uint p) internal pure returns (int) {
//         int r = int(u_pow(abs(x), p));
//         if(p % 2 == 1) {
//             return -1*r;
//         }
//         return r;
//     }
// }



/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

contract LiquidityExamples is IERC721Receiver{

    INonfungiblePositionManager nonfungiblePositionManager;

     constructor(INonfungiblePositionManager _nonfungiblePositionManager) {
            nonfungiblePositionManager = _nonfungiblePositionManager;
    }
    // address public constant DAI = 0x20441E38e81fE008FFbeE99fd4fb972C04622815;//poke
    // address public constant USDC = 0x02784b58965182077131F27E9Ea6351cd6041055;//pick


    address public constant DAI = 0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735;//poke
    address public constant USDC = 0x953c5C6510C673f58d9f9c6328d0Bc1155dcb558;//pick

    // IERC20 DAItoken = IERC20(0x20441E38e81fE008FFbeE99fd4fb972C04622815);//poke
    // IERC20 USDCtoken = IERC20(0x02784b58965182077131F27E9Ea6351cd6041055);//pick

    IERC20 DAItoken = IERC20(0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735);//poke
    IERC20 USDCtoken = IERC20(0x953c5C6510C673f58d9f9c6328d0Bc1155dcb558);//pick

    IUniswapV3Factory v3Factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    IUniswapV3Pool v3pool = IUniswapV3Pool(0x11b815efB8f581194ae79006d24E0d814B7697F6);


    uint24 public constant poolFee = 3000;
    uint160 price = 10;



    
    


    // IPoolInitializer poolinit = IPoolInitializer(0xA5644E29708357803b5A882D272c41cC0dF92B34);

    //INonfungiblePositionManager nonfungiblePositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    //INonfungiblePositionManager nonfungiblePositionManager;
    /// @notice Represents the deposit of an NFT
    struct Deposit {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
    }

    /// @dev deposits[tokenId] => Deposit
    mapping(uint256 => Deposit) public deposits;

    // constructor(INonfungiblePositionManager _nonfungiblePositionManager) {
    //         nonfungiblePositionManager = _nonfungiblePositionManager;
    // }
    


    function _initializePool(address tokenA, address tokenB, uint24 fee) external returns(address pool){

       uint160 sqrtPriceX96 = uint160(Babylonian.sqrt(price) * 2 ** 96);

       pool = nonfungiblePositionManager.createAndInitializePoolIfNecessary(tokenA, tokenB, fee, sqrtPriceX96);

       return pool;
    }
    // Implementing `onERC721Received` so this contract can receive custody of erc721 tokens
    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        // get position information

        _createDeposit(operator, tokenId);

       //return  this.onERC721Received.selector;
         return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function _createDeposit(address owner, uint256 tokenId) internal {
        (, , address token0, address token1, , , , uint128 liquidity, , , , ) =
            nonfungiblePositionManager.positions(tokenId);

        // set the owner and data for position
        // operator is msg.sender
        deposits[tokenId] = Deposit({owner: owner, liquidity: liquidity, token0: token0, token1: token1});
    }

    // function initializePool() external {
    //     nonfungiblePositionManager
    // }

    /// @notice Calls the mint function defined in periphery, mints the same amount of each token.
    /// For this example we are providing 1000 DAI and 1000 USDC in liquidity
    /// @return tokenId The id of the newly minted ERC721
    /// @return liquidity The amount of liquidity for the position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mintNewPosition()
        external
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
            // address pool
        )
    {
        //nonfungiblePositionManager(payable(msg.sender)).createAndInitializePoolIfNecessary( DAI, USDC, 3000, sqrtPriceX96 ); 

        // (pool) = v3Factory.createPool(DAI, USDC, poolFee);
        // v3pool.initialize(sqrtPriceX96);

        // For this example, we will provide equal amounts of liquidity in both assets.
        // Providing liquidity in both assets means liquidity will be earning fees and is considered in-range.
        uint256 amount0ToMint = 167;
        uint256 amount1ToMint = 1000;


        // Approve the position manager
        DAItoken.approve(address(nonfungiblePositionManager), amount0ToMint);
        USDCtoken.approve(address(nonfungiblePositionManager), amount1ToMint);

        // transfer tokens to contract
        DAItoken.transferFrom(msg.sender, address(this), amount0ToMint);
        USDCtoken.transferFrom(msg.sender, address(this), amount1ToMint);
        
        //positionManager.connect(deployer).multicall(multiCallParams, {gasPrice: 0});

        //nonfungiblePositionManager.multicall(multiCallParams);
        

        
 
        INonfungiblePositionManager.MintParams memory params =
            INonfungiblePositionManager.MintParams({
                token0: DAI,
                token1: USDC,
                fee: poolFee,
                tickLower: TickMath.MIN_TICK,
                tickUpper: TickMath.MAX_TICK,
                amount0Desired: amount0ToMint,
                amount1Desired: amount1ToMint,
                amount0Min: 1,
                amount1Min: 1,
                recipient: address(this),
                deadline: block.timestamp
            });

        // Note that the pool defined by DAI/USDC and fee tier 0.3% must already be created and initialized in order to mint
        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(params);

        // Create a deposit
        _createDeposit(msg.sender, tokenId);

        // Remove allowance and refund in both assets.
        if (amount0 < amount0ToMint) {
            DAItoken.approve(address(nonfungiblePositionManager), 0);
            uint256 refund0 = amount0ToMint - amount0;
            DAItoken.transfer(msg.sender, refund0);
        }

        if (amount1 < amount1ToMint) {
            USDCtoken.approve(address(nonfungiblePositionManager), 0);
            uint256 refund1 = amount1ToMint - amount1;
            USDCtoken.transfer(msg.sender, refund1);
        }

        
    }

    /// @notice Collects the fees associated with provided liquidity
    /// @dev The contract must hold the erc721 token before it can collect fees
    /// @param tokenId The id of the erc721 token
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collectAllFees(uint256 tokenId) external returns (uint256 amount0, uint256 amount1) {
        // Caller must own the ERC721 position, meaning it must be a deposit

        // set amount0Max and amount1Max to uint256.max to collect all fees
        // alternatively can set recipient to msg.sender and avoid another transaction in `sendToOwner`
        INonfungiblePositionManager.CollectParams memory params =
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        (amount0, amount1) = nonfungiblePositionManager.collect(params);

        // send collected feed back to owner
        _sendToOwner(tokenId, amount0, amount1);
    }

    /// @notice A function that decreases the current liquidity by half. An example to show how to call the `decreaseLiquidity` function defined in periphery.
    /// @param tokenId The id of the erc721 token
    /// @return amount0 The amount received back in token0
    /// @return amount1 The amount returned back in token1
    function decreaseLiquidityInHalf(uint256 tokenId) external returns (uint256 amount0, uint256 amount1) {
        // caller must be the owner of the NFT
        require(msg.sender == deposits[tokenId].owner, 'Not the owner');
        // get liquidity data for tokenId
        uint128 liquidity = deposits[tokenId].liquidity;
        uint128 halfLiquidity = liquidity / 2;

        // amount0Min and amount1Min are price slippage checks
        // if the amount received after burning is not greater than these minimums, transaction will fail
        INonfungiblePositionManager.DecreaseLiquidityParams memory params =
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: halfLiquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(params);

        //send liquidity back to owner
        _sendToOwner(tokenId, amount0, amount1);
    }

    /// @notice Increases liquidity in the current range
    /// @dev Pool must be initialized already to add liquidity
    /// @param tokenId The id of the erc721 token
    /// @param amount0 The amount to add of token0
    /// @param amount1 The amount to add of token1
    function increaseLiquidityCurrentRange(
        uint256 tokenId,
        uint256 amountAdd0,
        uint256 amountAdd1
    )
        external
        returns (
            uint128 liquidity,  
            uint256 amount0,
            uint256 amount1
        ) {

        DAItoken.approve(address(nonfungiblePositionManager), amountAdd0);
        USDCtoken.approve(address(nonfungiblePositionManager), amountAdd1);

        DAItoken.transferFrom(msg.sender, address(this), amountAdd0);
        USDCtoken.transferFrom(msg.sender, address(this), amountAdd1);

        

        INonfungiblePositionManager.IncreaseLiquidityParams memory params = INonfungiblePositionManager.IncreaseLiquidityParams({
            tokenId: tokenId,
            amount0Desired: amountAdd0,
            amount1Desired: amountAdd1,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp
        });

        (liquidity, amount0, amount1) = nonfungiblePositionManager.increaseLiquidity(params);

    }

    /// @notice Transfers funds to owner of NFT
    /// @param tokenId The id of the erc721
    /// @param amount0 The amount of token0
    /// @param amount1 The amount of token1
    function _sendToOwner(
        uint256 tokenId,
        uint256 amount0,
        uint256 amount1
    ) internal {
        // get owner of contract
        address owner = deposits[tokenId].owner;

        address token0 = deposits[tokenId].token0;
        address token1 = deposits[tokenId].token1;
        // send collected fees to owner
        TransferHelper.safeTransfer(token0, owner, amount0);
        TransferHelper.safeTransfer(token1, owner, amount1);
    }

    /// @notice Transfers the NFT to the owner
    /// @param tokenId The id of the erc721
    function retrieveNFT(uint256 tokenId) external {
        // must be the owner of the NFT
        require(msg.sender == deposits[tokenId].owner, 'Not the owner');
        // transfer ownership to original owner
        nonfungiblePositionManager.safeTransferFrom(address(this), msg.sender, tokenId);
        //remove information related to tokenId
        delete deposits[tokenId];
    }
}


