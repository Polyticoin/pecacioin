// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract PecaCoin is IERC20 {
    string public name = "PecaCoin";
    string public symbol = "PECA";
    uint8 public decimals = 18;
    uint256 public override totalSupply;

    address public owner = 0x88384801358701b6C3deb2b227b9e1F659FE2bdd;
    address public creatorWallet = 0x1Bd42A9787bdCbf437F4FfC31E980926e1e5Fd7D;

    uint256 public constant TOKEN_CREATOR_FEE = 3; // 3% en tokens para el creador por transacción
    uint256 public constant TOKEN_OWNER_FEE = 3; // 3% en tokens para el propietario por transacción
    uint256 public constant CREATOR_ALLOCATION_PERCENTAGE = 80; // 80% del suministro inicial para el creador
    uint256 public constant OWNER_ALLOCATION_PERCENTAGE = 20; // 20% del suministro inicial para el propietario
    uint256 public constant MAX_SUPPLY_AFTER_BURN = 1_000_000_000 * 10**18; // Quema detiene al llegar a 1,000 millones de tokens

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        uint256 initialSupply = 50_000_000_000_000_000 * 10**18; // 50 cuatrillones de tokens iniciales
        uint256 creatorAllocation = (initialSupply * CREATOR_ALLOCATION_PERCENTAGE) / 100;
        uint256 ownerAllocation = (initialSupply * OWNER_ALLOCATION_PERCENTAGE) / 100;

        balanceOf[creatorWallet] = creatorAllocation;
        balanceOf[owner] = ownerAllocation;
        totalSupply = initialSupply;

        emit Transfer(address(0), creatorWallet, creatorAllocation);
        emit Transfer(address(0), owner, ownerAllocation);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(allowance[sender][msg.sender] >= amount, "Allowance exceeded");
        allowance[sender][msg.sender] -= amount;
        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(balanceOf[sender] >= amount, "Insufficient balance");
        require(recipient != address(0), "Cannot transfer to zero address");

        uint256 creatorFee = calculateFee(amount, TOKEN_CREATOR_FEE);
        uint256 ownerFee = calculateFee(amount, TOKEN_OWNER_FEE);
        uint256 burnAmount = calculateBurnAmount(amount);
        uint256 amountAfterFees = amount - creatorFee - ownerFee - burnAmount;

        // Actualizar balances
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amountAfterFees;
        balanceOf[creatorWallet] += creatorFee;
        balanceOf[owner] += ownerFee;
        if (burnAmount > 0) {
            totalSupply -= burnAmount;
        }

        emit Transfer(sender, recipient, amountAfterFees);
        emit Transfer(sender, creatorWallet, creatorFee);
        emit Transfer(sender, owner, ownerFee);
        if (burnAmount > 0) {
            emit Transfer(sender, address(0), burnAmount);
        }
    }

    function calculateFee(uint256 _amount, uint256 _percentage) internal pure returns (uint256) {
        return (_amount * _percentage) / 100;
    }

    function calculateBurnAmount(uint256 _amount) internal view returns (uint256) {
        if (totalSupply <= MAX_SUPPLY_AFTER_BURN) {
            return 0; // No quemar más tokens si el suministro es igual o menor al máximo permitido
        }
        return (_amount * 1) / 100; // 1% de quema
    }

    function updateCreatorWallet(address newCreatorWallet) external onlyOwner {
        require(newCreatorWallet != address(0), "New creator wallet cannot be zero address");
        creatorWallet = newCreatorWallet;
    }

    function updateOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        owner = newOwner;
    }
}
