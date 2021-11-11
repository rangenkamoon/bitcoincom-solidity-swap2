// SPDX-License-Identifier: BCOM

pragma solidity ^0.8.9;

import "./IWETH.sol";
import "./IERC20.sol";
import "./ISwapsFactory.sol";
import "./ISwapsPair.sol";
import "./TransferHelper.sol";

contract SwapsRouter {

    address public immutable FACTORY;
    address public immutable WETH;
    address public immutable PAIR;

    modifier ensure(
        uint256 _deadline
    ) {
        require(
            _deadline >= block.timestamp,
            'SwapsRouter: DEADLINE_EXPIRED'
        );
        _;
    }

    constructor(
        address _factory,
        address _WETH
    ) {
        FACTORY = _factory;
        WETH = _WETH;
        PAIR = ISwapsFactory(_factory).cloneTarget();
    }

    receive()
        external
        payable
    {
        require(
            msg.sender == WETH,
            'SwapsRouter: INVALID_SENDER'
        );
    }

    function _addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _amountAMin,
        uint256 _amountBMin
    )
        internal
        returns (uint256, uint256)
    {
        if (ISwapsFactory(FACTORY).getPair(_tokenA, _tokenB) == ZERO_ADDRESS) {
            ISwapsFactory(FACTORY).createPair(_tokenA, _tokenB);
        }

        (uint256 reserveA, uint256 reserveB) = getReserves(
            FACTORY,
            _tokenA,
            _tokenB
        );

        if (reserveA == 0 && reserveB == 0) {
            return (
                _amountADesired,
                _amountBDesired
            );
        }

        uint256 amountBOptimal = quote(
            _amountADesired,
            reserveA,
            reserveB
        );

        if (amountBOptimal <= _amountBDesired) {
            require(
                amountBOptimal >= _amountBMin,
                'INSUFFICIENT_B_AMOUNT'
            );

            return (
                _amountADesired,
                amountBOptimal
            );
        }

        uint256 amountAOptimal = quote(
            _amountBDesired,
            reserveB,
            reserveA
        );

        assert(
            amountAOptimal <= _amountADesired
        );

        require(
            amountAOptimal >= _amountAMin,
            'INSUFFICIENT_A_AMOUNT'
        );

        return (
            amountAOptimal,
            _amountBDesired
        );
    }

    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    )
        external
        ensure(_deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = _addLiquidity(
            _tokenA,
            _tokenB,
            _amountADesired,
            _amountBDesired,
            _amountAMin,
            _amountBMin
        );

        address pair = _pairFor(
            FACTORY,
            _tokenA,
            _tokenB,
            PAIR
        );

        _safeTransferFrom(
            _tokenA,
            msg.sender,
            pair,
            amountA
        );

        _safeTransferFrom(
            _tokenB,
            msg.sender,
            pair,
            amountB
        );

        liquidity = ISwapsPair(pair).mint(_to);
    }

    function addLiquidityETH(
        address _token,
        uint256 _amountTokenDesired,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        address _to,
        uint256 _deadline
    )
        external
        payable
        ensure(_deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amountToken, amountETH) = _addLiquidity(
            _token,
            WETH,
            _amountTokenDesired,
            msg.value,
            _amountTokenMin,
            _amountETHMin
        );

        address pair = _pairFor(
            FACTORY,
            _token,
            WETH,
            PAIR
        );

        _safeTransferFrom(
            _token,
            msg.sender,
            pair,
            amountToken
        );

        IWETH(WETH).deposit{
            value: amountETH
        }();

        assert(
            IWETH(WETH).transfer(
                pair,
                amountETH
            )
        );

        liquidity = ISwapsPair(pair).mint(_to);

        if (msg.value > amountETH) {
            safeTransferETH(
                msg.sender,
                msg.value - amountETH
            );
        }
    }

    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _liquidity,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    )
        public
        ensure(_deadline)
        returns (
            uint256 amountA,
            uint256 amountB
        )
    {
        address pair = _pairFor(
            FACTORY,
            _tokenA,
            _tokenB,
            PAIR
        );

        ISwapsPair(pair).transferFrom(
            msg.sender,
            pair,
            _liquidity
        );

        (uint256 amount0, uint256 amount1) = ISwapsPair(pair).burn(_to);

        (address token0,) = sortTokens(
            _tokenA,
            _tokenB
        );

        (amountA, amountB) = _tokenA == token0
            ? (amount0, amount1)
            : (amount1, amount0);

        require(
            amountA >= _amountAMin,
            'INSUFFICIENT_A_AMOUNT'
        );

        require(
            amountB >= _amountBMin,
            'INSUFFICIENT_B_AMOUNT'
        );
    }

    function removeLiquidityETH(
        address _token,
        uint256 _liquidity,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        address _to,
        uint256 _deadline
    )
        public
        ensure(_deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH
        )
    {
        (amountToken, amountETH) = removeLiquidity(
            _token,
            WETH,
            _liquidity,
            _amountTokenMin,
            _amountETHMin,
            address(this),
            _deadline
        );

        _safeTransfer(
            _token,
            _to,
            amountToken
        );

        IWETH(WETH).withdraw(
            amountETH
        );

        safeTransferETH(
            _to,
            amountETH
        );
    }

    function removeLiquidityWithPermit(
        address _tokenA,
        address _tokenB,
        uint256 _liquidity,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
        returns (uint256, uint256)
    {
        address pair = _pairFor(
            FACTORY,
            _tokenA,
            _tokenB,
            PAIR
        );

        uint256 value = _approveMax
            ? U256_MAX
            : _liquidity;

        ISwapsPair(pair).permit(
            msg.sender,
            address(this),
            value,
            _deadline,
            _v,
            _r,
            _s
        );

        return removeLiquidity(
            _tokenA,
            _tokenB,
            _liquidity,
            _amountAMin,
            _amountBMin,
            _to,
            _deadline
        );
    }

    function removeLiquidityETHWithPermit(
        address _token,
        uint256 _liquidity,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        address _to,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
        returns (uint256, uint256)
    {
        address pair = _pairFor(
            FACTORY,
            _token,
            WETH,
            PAIR
        );

        uint256 value = _approveMax
            ? U256_MAX
            : _liquidity;

        ISwapsPair(pair).permit(
            msg.sender,
            address(this),
            value,
            _deadline,
            _v,
            _r,
            _s
        );

        return removeLiquidityETH(
            _token,
            _liquidity,
            _amountTokenMin,
            _amountETHMin,
            _to,
            _deadline
        );
    }

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address _token,
        uint256 _liquidity,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        address _to,
        uint256 _deadline
    )
        public
        ensure(_deadline)
        returns (uint256 amountETH)
    {
        (, amountETH) = removeLiquidity(
            _token,
            WETH,
            _liquidity,
            _amountTokenMin,
            _amountETHMin,
            address(this),
            _deadline
        );

        _safeTransfer(
            _token,
            _to,
            IERC20(_token).balanceOf(address(this))
        );

        IWETH(WETH).withdraw(
            amountETH
        );

        safeTransferETH(
            _to,
            amountETH
        );
    }

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address _token,
        uint256 _liquidity,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        address _to,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
        returns (uint256 amountETH)
    {
        address pair = _pairFor(
            FACTORY,
            _token,
            WETH,
            PAIR
        );

        uint256 value = _approveMax
            ? U256_MAX
            : _liquidity;

        ISwapsPair(pair).permit(
            msg.sender,
            address(this),
            value,
            _deadline,
            _v,
            _r,
            _s
        );

        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            _token,
            _liquidity,
            _amountTokenMin,
            _amountETHMin,
            _to,
            _deadline
        );
    }

    function _swap(
        uint256[] memory _amounts,
        address[] memory _path,
        address _to
    )
        internal
    {
        for (uint256 i; i < _path.length - 1; i++) {

            (address input, address output) = (
                _path[i],
                _path[i + 1]
            );

            (address token0,) = sortTokens(
                input,
                output
            );

            uint256 amountOut = _amounts[i + 1];

            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint(0), amountOut)
                : (amountOut, uint(0));

            address to = i < _path.length - 2
                ? _pairFor(FACTORY, output, _path[i + 2], PAIR)
                : _to;

            ISwapsPair(
                _pairFor(
                    FACTORY,
                    input,
                    output,
                    PAIR
                )
            ).swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }

    function swapExactTokensForTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    )
        external
        ensure(_deadline)
        returns (uint256[] memory amounts)
    {
        amounts = _getAmountsOut(
            FACTORY,
            _amountIn,
            _path
        );

        require(
            amounts[amounts.length - 1] >= _amountOutMin,
            'INSUFFICIENT_OUTPUT_AMOUNT'
        );

        _safeTransferFrom(
            _path[0],
            msg.sender,
            _pairFor(
                FACTORY,
                _path[0],
                _path[1],
                PAIR
            ),
            amounts[0]
        );

        _swap(
            amounts,
            _path,
            _to
        );
    }

    function swapTokensForExactTokens(
        uint256 _amountOut,
        uint256 _amountInMax,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    )
        external
        ensure(_deadline)
        returns (uint256[] memory amounts)
    {
        amounts = _getAmountsIn(
            FACTORY,
            _amountOut,
            _path
        );

        require(
            amounts[0] <= _amountInMax,
            'EXCESSIVE_INPUT_AMOUNT'
        );

        _safeTransferFrom(
            _path[0],
            msg.sender,
            _pairFor(
                FACTORY,
                _path[0],
                _path[1],
                PAIR
            ),
            amounts[0]
        );

        _swap(
            amounts,
            _path,
            _to
        );
    }

    function swapExactETHForTokens(
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    )
        external
        payable
        ensure(_deadline)
        returns (uint256[] memory amounts)
    {
        require(
            _path[0] == WETH,
            'INVALID_PATH'
        );

        amounts = _getAmountsOut(
            FACTORY,
            msg.value,
            _path
        );

        require(
            amounts[amounts.length - 1] >= _amountOutMin,
            'INSUFFICIENT_OUTPUT_AMOUNT'
        );

        IWETH(WETH).deposit{
            value: amounts[0]
        }();

        assert(
            IWETH(WETH).transfer(
                _pairFor(
                    FACTORY,
                    _path[0],
                    _path[1],
                    PAIR
                ),
                amounts[0]
            )
        );

        _swap(
            amounts,
            _path,
            _to
        );
    }

    function swapTokensForExactETH(
        uint256 _amountOut,
        uint256 _amountInMax,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    )
        external
        ensure(_deadline)
        returns (uint256[] memory amounts)
    {
        require(
            _path[_path.length - 1] == WETH,
            'INVALID_PATH'
        );

        amounts = _getAmountsIn(
            FACTORY,
            _amountOut,
            _path
        );

        require(
            amounts[0] <= _amountInMax,
            'EXCESSIVE_INPUT_AMOUNT'
        );

        _safeTransferFrom(
            _path[0],
            msg.sender,
            _pairFor(
                FACTORY,
                _path[0],
                _path[1],
                PAIR
            ),
            amounts[0]
        );

        _swap(
            amounts,
            _path,
            address(this)
        );

        IWETH(WETH).withdraw(
            amounts[amounts.length - 1]
        );

        safeTransferETH(
            _to,
            amounts[amounts.length - 1]
        );
    }

    function swapExactTokensForETH(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    )
        external
        ensure(_deadline)
        returns (uint256[] memory amounts)
    {
        require(
            _path[_path.length - 1] == WETH,
            'INVALID_PATH'
        );

        amounts = _getAmountsOut(
            FACTORY,
            _amountIn,
            _path
        );

        require(
            amounts[amounts.length - 1] >= _amountOutMin,
            'INSUFFICIENT_OUTPUT_AMOUNT'
        );

        _safeTransferFrom(
            _path[0],
            msg.sender,
            _pairFor(
                FACTORY,
                _path[0],
                _path[1],
                PAIR
            ),
            amounts[0]
        );

        _swap(
            amounts,
            _path,
            address(this)
        );

        IWETH(WETH).withdraw(
            amounts[amounts.length - 1]
        );

        safeTransferETH(
            _to,
            amounts[amounts.length - 1]
        );
    }

    function swapETHForExactTokens(
        uint256 _amountOut,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    )
        external
        payable
        ensure(_deadline)
        returns (uint256[] memory amounts)
    {
        require(
            _path[0] == WETH,
            'INVALID_PATH'
        );

        amounts = _getAmountsIn(
            FACTORY,
            _amountOut,
            _path
        );

        require(
            amounts[0] <= msg.value,
            'EXCESSIVE_INPUT_AMOUNT'
        );

        IWETH(WETH).deposit{
            value: amounts[0]
        }();

        assert(
            IWETH(WETH).transfer(
                _pairFor(
                    FACTORY,
                    _path[0],
                    _path[1],
                    PAIR
                ),
                amounts[0]
            )
        );

        _swap(
            amounts,
            _path,
            _to
        );

        if (msg.value > amounts[0]) {
            unchecked {
                safeTransferETH(
                    msg.sender,
                    msg.value - amounts[0]
                );
            }
        }
    }

    function _swapSupportingFeeOnTransferTokens(
        address[] memory _path,
        address _to
    )
        internal
    {
        for (uint256 i; i < _path.length - 1; i++) {

            (address input, address output) = (
                _path[i],
                _path[i + 1]
            );

            (address token0,) = sortTokens(
                input,
                output
            );

            ISwapsPair pair = ISwapsPair(
                _pairFor(
                    FACTORY,
                    input,
                    output,
                    PAIR
                )
            );

            uint256 amountInput;
            uint256 amountOutput;

            {

            (uint256 reserve0, uint256 reserve1,) = pair.getReserves();

            (uint256 reserveInput, uint256 reserveOutput) = input == token0
                ? (reserve0, reserve1)
                : (reserve1, reserve0);

            amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
            amountOutput = getAmountOut(amountInput, reserveInput, reserveOutput);

            }

            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint(0), amountOutput)
                : (amountOutput, uint(0));

            address to = i < _path.length - 2
                ? _pairFor(FACTORY, output, _path[i + 2], PAIR)
                : _to;

            pair.swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    )
        external
        ensure(_deadline)
    {
        _safeTransferFrom(
            _path[0],
            msg.sender,
            _pairFor(
                FACTORY,
                _path[0],
                _path[1],
                PAIR
            ),
            _amountIn
        );

        uint256 balanceBefore = IERC20(_path[_path.length - 1]).balanceOf(_to);

        _swapSupportingFeeOnTransferTokens(
            _path,
            _to
        );

        require(
            IERC20(_path[_path.length - 1]).balanceOf(_to) - balanceBefore >= _amountOutMin,
            'INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    )
        external
        payable
        ensure(_deadline)
    {
        require(
            _path[0] == WETH,
            'INVALID_PATH'
        );

        uint256 amountIn = msg.value;

        IWETH(WETH).deposit{
            value: amountIn
        }();

        assert(
            IWETH(WETH).transfer(
                _pairFor(
                    FACTORY,
                    _path[0],
                    _path[1],
                    PAIR
                ),
                amountIn
            )
        );

        delete amountIn;

        uint256 balanceBefore = IERC20(_path[_path.length - 1]).balanceOf(_to);

        _swapSupportingFeeOnTransferTokens(
            _path,
            _to
        );

        require(
            IERC20(_path[_path.length - 1]).balanceOf(_to) - balanceBefore >= _amountOutMin,
            'INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    )
        external
        ensure(_deadline)
    {
        require(
            _path[_path.length - 1] == WETH,
            'SwapsRouter: INVALID_PATH'
        );

        _safeTransferFrom(
            _path[0],
            msg.sender,
            _pairFor(
                FACTORY,
                _path[0],
                _path[1],
                PAIR
            ),
            _amountIn
        );

        _swapSupportingFeeOnTransferTokens(
            _path,
            address(this)
        );

        uint256 amountOut = IERC20(WETH).balanceOf(
            address(this)
        );

        require(
            amountOut >= _amountOutMin,
            'INSUFFICIENT_OUTPUT_AMOUNT'
        );

        IWETH(WETH).withdraw(
            amountOut
        );

        safeTransferETH(
            _to,
            amountOut
        );
    }

    function sortTokens(
        address _tokenA,
        address _tokenB
    )
        internal
        pure
        returns (
            address token0,
            address token1
        )
    {
        require(
            _tokenA != _tokenB,
            'IDENTICAL_ADDRESSES'
        );

        (token0, token1) = _tokenA < _tokenB
            ? (_tokenA, _tokenB)
            : (_tokenB, _tokenA);

        require(
            token0 != ZERO_ADDRESS,
            'ZERO_ADDRESS'
        );
    }

    function pairFor(
        address _factory,
        address _tokenA,
        address _tokenB
    )
        external
        view
        returns (address predicted)
    {
        predicted = _pairFor(
            _factory,
            _tokenA,
            _tokenB,
            PAIR
        );
    }

    function _pairFor(
        address _factory,
        address _tokenA,
        address _tokenB,
        address _implementation
    )
        internal
        pure
        returns (address predicted)
    {
        (address token0, address token1) = _tokenA < _tokenB
            ? (_tokenA, _tokenB)
            : (_tokenB, _tokenA);

        bytes32 salt = keccak256(
            abi.encodePacked(
                token0,
                token1
            )
        );

        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, _implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, _factory))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    function getAmountsOut(
        uint256 _amountIn,
        address[] memory _path
    )
        external
        view
        returns (uint256[] memory amounts)
    {
        return _getAmountsOut(
            FACTORY,
            _amountIn,
            _path
        );
    }

    function getAmountsIn(
        uint256 _amountOut,
        address[] memory _path
    )
        external
        view
        returns (uint256[] memory amounts)
    {
        return _getAmountsIn(
            FACTORY,
            _amountOut,
            _path
        );
    }

    function getReserves(
        address _factory,
        address _tokenA,
        address _tokenB
    )
        internal
        view
        returns (
            uint256 reserveA,
            uint256 reserveB
        )
    {
        (address token0,) = sortTokens(
            _tokenA,
            _tokenB
        );

        (uint256 reserve0, uint256 reserve1,) = ISwapsPair(
            _pairFor(
                _factory,
                _tokenA,
                _tokenB,
                PAIR
            )
        ).getReserves();

        (reserveA, reserveB) = _tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    function quote(
        uint256 _amountA,
        uint256 _reserveA,
        uint256 _reserveB
    )
        public
        pure
        returns (uint256 amountB)
    {
        require(
            _amountA > 0,
            'INSUFFICIENT_AMOUNT'
        );

        require(
            _reserveA > 0 && _reserveB > 0,
            'INSUFFICIENT_LIQUIDITY'
        );

        amountB = _amountA
            * _reserveB
            / _reserveA;
    }

    function getAmountOut(
        uint256 _amountIn,
        uint256 _reserveIn,
        uint256 _reserveOut
    )
        public
        pure
        returns (uint256 amountOut)
    {
        require(
            _amountIn > 0,
            'INSUFFICIENT_INPUT_AMOUNT'
        );

        require(
            _reserveIn > 0 && _reserveOut > 0,
            'INSUFFICIENT_LIQUIDITY'
        );

        uint256 amountInWithFee = _amountIn * 997;
        uint256 numerator = amountInWithFee * _reserveOut;
        uint256 denominator = _reserveIn * 1000 + amountInWithFee;

        amountOut = numerator / denominator;
    }

    function getAmountIn(
        uint256 _amountOut,
        uint256 _reserveIn,
        uint256 _reserveOut
    )
        public
        pure
        returns (uint256 amountIn)
    {
        require(
            _amountOut > 0,
            'INSUFFICIENT_OUTPUT_AMOUNT'
        );

        require(
            _reserveIn > 0 && _reserveOut > 0,
            'INSUFFICIENT_LIQUIDITY'
        );

        uint256 numerator = _reserveIn * _amountOut * 1000;
        uint256 denominator = (_reserveOut - _amountOut) * 997;

        amountIn = numerator / denominator + 1;
    }

    function _getAmountsOut(
        address _factory,
        uint256 _amountIn,
        address[] memory _path
    )
        internal
        view
        returns (uint256[] memory amounts)
    {
        require(
            _path.length >= 2,
            'INVALID_PATH'
        );

        amounts = new uint256[](_path.length);
        amounts[0] = _amountIn;

        for (uint256 i; i < _path.length - 1; i++) {

            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                _factory,
                _path[i],
                _path[i + 1]
            );

            amounts[i + 1] = getAmountOut(
                amounts[i],
                reserveIn,
                reserveOut
            );
        }
    }

    function _getAmountsIn(
        address _factory,
        uint256 _amountOut,
        address[] memory _path
    )
        internal
        view
        returns (uint256[] memory amounts)
    {
        require(
            _path.length >= 2,
            'INVALID_PATH'
        );

        amounts = new uint256[](
            _path.length
        );

        amounts[amounts.length - 1] = _amountOut;

        for (uint256 i = _path.length - 1; i > 0; i--) {

            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                _factory,
                _path[i - 1],
                _path[i]
            );

            amounts[i - 1] = getAmountIn(
                amounts[i],
                reserveIn,
                reserveOut
            );
        }
    }
}
