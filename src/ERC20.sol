// SPDX-License-Identifier: UNLICENSED
pragma solidity  ^0.8.0;

/**
 * @title ERC20 Token Implementation
 * @dev Standard implementation of the ERC20 token interface with additional functionality.
 */
contract ERC20 {
    // --- Storage ---
    uint256 internal _totalSupply;
    mapping (address => uint256) internal _balanceOf;
    mapping (address => mapping (address => uint256)) internal _allowance;

    // --- Token Information ---
    string public symbol;
    uint256 public decimals = 18; // standard token precision. Override to customize.
    string public name = "";     // Optional token name
    
    // --- Custom Errors ---
    error InsufficientApproval();
    error InsufficientBalance();

    // --- Events ---
    event Approval(address indexed owner, address indexed spender, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    event Mint(address indexed dst, uint wad);
    event Burn(address indexed src, uint wad);

    // --- Constructor ---
    /**
     * @dev Initializes the ERC20 token with a name and symbol.
     * @param name_ The name of the token.
     * @param symbol_ The symbol of the token.
     */
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    // --- View Functions ---

    /**
     * @dev Retrieves the total supply of the token.
     * @return The total supply.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Retrieves the balance of a given address.
     * @param guy The address to query.
     * @return The balance of the address.
     */
    function balanceOf(address guy) public view returns (uint256) {
        return _balanceOf[guy];
    }

    /**
     * @dev Retrieves the allowance granted to a spender by an owner.
     * @param owner The owner's address.
     * @param spender The spender's address.
     * @return The allowance amount.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowance[owner][spender];
    }

    // --- External Functions ---

    /**
     * @dev Approves a spender to spend a certain amount on behalf of the owner.
     * @param spender The address allowed to spend.
     * @param wad The amount to approve.
     * @return A boolean indicating success.
     */
    function approve(address spender, uint wad) public returns (bool) {
        return _approve(msg.sender, spender, wad);
    }

    /**
     * @dev Transfers a certain amount of tokens to another address.
     * @param dst The recipient's address.
     * @param wad The amount to transfer.
     * @return A boolean indicating success.
     */
    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    /**
     * @dev Transfers a certain amount of tokens from one address to another.
     * @param src The sender's address.
     * @param dst The recipient's address.
     * @param wad The amount to transfer.
     * @return A boolean indicating success.
     */
    function transferFrom(address src, address dst, uint wad) public returns (bool) {
        uint256 allowed = _allowance[src][msg.sender];
        if (src != msg.sender && allowed != type(uint).max) {
            if (allowed < wad) revert InsufficientApproval();
            _approve(src, msg.sender, allowed - wad);
        }
        
        if (_balanceOf[src] < wad) revert InsufficientBalance();
        _balanceOf[src] = _balanceOf[src] - wad;
        _balanceOf[dst] = _balanceOf[dst] + wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    // --- Internal Functions ---

    /**
     * @dev Approves a spender to spend a certain amount on behalf of the owner. Internal function.
     * @param owner The owner's address.
     * @param spender The spender's address.
     * @param wad The amount to approve.
     * @return A boolean indicating success.
     */
    function _approve(address owner, address spender, uint wad) internal returns (bool) {
        _allowance[owner][spender] = wad;
        emit Approval(owner, spender, wad);
        return true;
    }

    /**
     * @dev Mints new tokens and assigns them to the destination address.
     * @param dst The address to receive the minted tokens.
     * @param wad The amount of tokens to mint.
     */
    function _mint(address dst, uint wad) external {
        _balanceOf[dst] = _balanceOf[dst] + wad;
        _totalSupply = _totalSupply + wad;
        emit Mint(dst, wad);
    }

    /**
     * @dev Burns a certain amount of tokens from the source address.
     * @param src The address from which tokens will be burned.
     * @param wad The amount of tokens to burn.
     */
    function _burn(address src, uint wad) internal {
        uint256 allowed = _allowance[src][msg.sender];
        if (src != msg.sender && allowed != type(uint).max) {
            if (allowed < wad) revert InsufficientApproval();
            _approve(src, msg.sender, allowed - wad);
        }

        if (_balanceOf[src] < wad) revert InsufficientBalance();
        _balanceOf[src] = _balanceOf[src] - wad;
        _totalSupply = _totalSupply - wad;
        emit Burn(src, wad);
    }
}
