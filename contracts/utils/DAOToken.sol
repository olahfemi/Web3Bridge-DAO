// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "../interfaces/IERC20.sol";
import {IERC721} from "../interfaces/IERC721.sol";

/// @title Web3DAO-Token Implmentartion Contract
/// @notice this contract will be called anytime a session is started and last thoroughout the duration of that session.
/// @author team Web3Bridge  💯

contract DAOtoken is IERC20 {
    /**
     * ===================================================
     * ----------------- STATE VARIBLE -------------------
     * ===================================================
     */

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 _totalSupply;

    string private _name = "Web3bridge DAO TOKEN";
    string private _symbol = "WDT";

    uint256 private _mintAmountperPerson = 20;

    address private _owner;

    IERC20 nftcetificate;

    bool private _enableMinting;

    /**
     * ===================================================
     * ----------------- MODIFIERS -----------------------
     * ===================================================
     */

    modifier onlyOwner() {
        require(msg.sender == _owner, "not owner");
        _;
    }

    /**
     * ===================================================
     * ----------------- CONSTRUCTOR --------------------
     * ===================================================
     */

    constructor(address _nftaddress) {
        _owner = msg.sender;
        nftcetificate = IERC20(_nftaddress);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    //sets the amount to be minted for each members
    function setMintAmountPerPerson(uint256 newamount) public onlyOwner {
        _mintAmountperPerson = newamount;
    }

    // return the amount to be minted to members
    function getMintperPerson() external view returns (uint256) {
        return _mintAmountperPerson;
    }

    //gets the owner of the contracts
    function getOwner() public view returns (address) {
        return _owner;
    }

    /// @notice sets the owner to a new one
    /// @dev NOTE this script must transfer ownership imedately after deployment
    function setNewOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }

    /// @notice this fuction is used to get the state of minting
    /// this returns a bool (true or false)
    /// if state of minting is false, user can't mint token
    /// if true, users will be able to mint token
    function stateOfMinting() external view returns (bool) {
        return _enableMinting;
    }

    /// @notice this function is called by owner to enable minting every session 🤑
    function enableMinting(bool status) external onlyOwner {
        _enableMinting = status;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(owner, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] = fromBalance - amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    //the mint tokens to an address should have certificate nft before minting
    function _mint() internal virtual {
        require(nftcetificate.balanceOf(msg.sender) >= 1, "not a member");
        uint256 _amount = _mintAmountperPerson * 1e18;
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
        emit Transfer(address(0), msg.sender, _amount);

        _afterTokenTransfer(address(0), msg.sender, _amount);
    }

    function mint() external {
        require(_enableMinting, "session has not ended");
        uint256 accountBalance = _balances[msg.sender];
        require(accountBalance <= 0, "old tokens burn needed");
        _burn(msg.sender, accountBalance);

        _mint();
    }

    /// @dev the diamond would be able to burn users token during voting
    /// @notice this function would be used to burn DAO token from a percified user address
    /// @param _voter: this is the address that the burn would happen to
    /// @param _voting_power: this is the is the amount of power(token) this user is willing use for this vote
    function burn(address _voter, uint256 _voting_power) external onlyOwner {
        _burn(_voter, _voting_power);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
