// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title Pre-Certificate Token
/// @author https://github.com/Realkayzee, https://github.com/fesimaxu, https://github.com/centie22
/// The Pre-Certifcate Token contract is used as a proof of payment
/// Students that paid the required amount can mint
/// Student can pay installmentally
/// The mode of payment can either be in USDT or MATIC
/// The admin will set the fee to be paid by students

contract PreCertificateToken is ERC20("Pre-Certificate Token", "WPC") {
    // ===========================
    // CUSTOM ERROR
    // ===========================
    error notAdmin(string);
    error notCompleted(string);
    error NOT_DAIMOND();


    // ===========================
    // EVENTS
    // ===========================
    event AdminMint(address to);


    // ===========================
    // STATE VARIABLE
    // ===========================
    bytes32 public merkleRoot;
    IERC20 public USDTContractAddr;
    uint256 public cohortFee;
    address public admin;
    uint40 paymentStart;
    uint40 elapsedTime;
    uint40 additionalTime;
    address vault10;
    address vault5_;
    address vault5__;
    address diamond;


    struct StudentDetails {
        uint256 amountPaid;
        bool claimed;
        uint8 tokenRecieved;
        uint40 timeOfLastPayment;
    }

    mapping(address => StudentDetails) studentDetails;

    /// @param _admin: this would be the address that would be handling admin opeartions
    /// @param _vault10: this is the address this would be 
    constructor(address _admin, address _vault10, address _vault5, address _vault5__, address _diamond) {
        admin = _admin;
        vault10 = _vault10;
        vault5_ = _vault5;
        vault5__ = _vault5__;
        diamond = _diamond;
    }

    /// @notice this function can only be called by the admin
    function setFee(
        uint40 _amount,
        bytes32 _merkleRoot,
        IERC20 _USDTContractAddr,
        uint40 _elapsedTime,
        uint40 _additionalTime
    ) public {
        if (msg.sender == admin) {
            cohortFee = _amount;
            merkleRoot = _merkleRoot;
            USDTContractAddr = _USDTContractAddr;
            paymentStart = uint40(block.timestamp);
            elapsedTime = uint40(block.timestamp + (_elapsedTime * 4 weeks));
            additionalTime = uint40(block.timestamp + (_additionalTime * 4 weeks));
        } else {
            revert notAdmin("Not an Admin");
        }
    }

    /// @dev A function for student's payment
    /// @notice A seperate function is created for fee payment in other allow installmental payment
    function payFee(uint40 _stableAmount, bytes32[] calldata _merkleProof) public {
        StudentDetails storage sd = studentDetails[msg.sender];
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (MerkleProof.verify(_merkleProof, merkleRoot, leaf) && block.timestamp < additionalTime) {
            // assert(_stableAmount >= (cohortFee * 70)/100) ;
            USDTContractAddr.transferFrom(msg.sender, address(this), _stableAmount);
            sd.amountPaid += _stableAmount;
            sd.timeOfLastPayment = uint40(block.timestamp);
        } else if (block.timestamp > additionalTime && sd.amountPaid < cohortFee) {
            uint256 amount = sd.amountPaid;
            sd.amountPaid = 0;
            USDTContractAddr.transfer(msg.sender, amount);
        }
    }

    /// @notice this is a view function that would be used to see if a user have paid the cohort fee
    /// @param _addr: this is a the address that is to be checked if the account has paid 
    function checkCompleted(address _addr) public view returns (bool) {
        StudentDetails memory sd = studentDetails[_addr];
        if (sd.amountPaid >= cohortFee) {
            return true;
        } else {
            return false;
        }
    }

    function claimToken(bytes32[] calldata _merkleProof) public {
        StudentDetails storage sd = studentDetails[msg.sender];
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (MerkleProof.verify(_merkleProof, merkleRoot, leaf)) {
            assert(checkCompleted(msg.sender));
            assert(!sd.claimed);
            if (sd.timeOfLastPayment < elapsedTime) {
                _mint(msg.sender, 2e18);
                sd.tokenRecieved = 2;
            } else if (sd.timeOfLastPayment > elapsedTime) {
                _mint(msg.sender, 1e18);
                sd.tokenRecieved = 1;
            }
        }

        sd.claimed = true;
    }

    function updateAdmin(address newAdmin) internal {
        assert(newAdmin != address(0));
        if(msg.sender != admin){
            revert notAdmin("Not an Admin");  
        }
        admin = newAdmin;
    }

    /// @dev this function would move any ERC20 token that is transfered to this address
    /// @param _receiver: this is the address that would be receiving the tokens 
    /// @param _tokenContractAddress: this is the address of the erc 20 contract 
    /// @param _amount: this is the amount of token the manager want to get out of this contract
    function movingGeneric(address _receiver, address _tokenContractAddress, uint256 _amount) public {
        if(msg.sender == admin) {
            revert notAdmin("Not an Admin");
        }
        IERC20(_tokenContractAddress).transfer(_receiver, _amount); // this would transfer the token from the contract to the address
    }

    function diamond_mint(address _to) external {
        if(msg.sender != diamond) {
            revert NOT_DAIMOND();
        }
        _mint(msg.sender, 1e18);

        emit AdminMint(_to);
    }
}