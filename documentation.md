# TradeContract

## Overview

`TradeContract`, facilitates a decentralized trade system where sellers can list orders, buyers can register themselves, and funds are released upon verification through a signature mechanism.

## Features

- List orders with native tokens or ERC20 tokens.
- Register as a potential buyer by sending a random number.
- Release funds from an order by verifying a signature.

## Contract Functions

### 1. `listOrder`

Allows sellers to list orders with a specified amount and token.

- **Parameters:**
  - `_amount`: The amount of tokens or Ether to be listed in the order.
  - `_tokenAddress`: The address of the ERC20 token to be listed, or `address(0)` for native Ether.

### 2. `registerBuyer`

Enables buyers to register themselves by providing a random number.

- **Parameters:**
  - `_orderId`: The ID of the order to which the buyer wants to register.
  - `_message`: A random number or message sent by the buyer.

### 3. `releaseFunds`

This Allows sellers to release funds from an order by verifying the signature.

- **Parameters:**
  - `_orderId`: The ID of the order from which the seller wants to release funds.
  - `_sign`: The signature provided by the seller.

## Usage

1. Sellers can use `listOrder` to create orders.
2. Buyers can register themselves using `registerBuyer`.
3. Sellers can release funds through `releaseFunds` by providing the order ID and buyer's signature.

## Assumptions

- The buyer and seller had an off-chain agreement about the deal.
- It's only a transfer of token from seller to the buyer.

## Testing

Before deploying the smart contract, it's essential to run and pass the provided tests. 
Ensure that your development environment and dependencies are properly set up. Run the following tests for the `TradeContract`:

- testFailBuyerRegistersAgian
- testFailBuyersInvalidId
- testFailForAlreadyReleasedFunds
- testFailReleaseToUnverifiedMessage
- testFailSellerRegisterAsBuyer
- testFailUnregisteredBuyer
- testFetchOrderDetails
- testListMultipleOrdersWithERC20token
- testListMultipleOrdersWithEther
- testListMultipleOrdersWithEtherAndERC20
- testListOrderWithERC20token
- testListOrderWithEther
- testRegisterBuyer
- testRegisterMultipleBuyers
- testReleaseERC20Funds
- testReleaseEtherFunds

## License

This contract is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
