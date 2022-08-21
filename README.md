# Getting Started

Welcome to the light documentation of Meme Market Smart Contracts!

## System Requirements

- [Node.js](https://nodejs.org/en/) 14 or later
- MacOS, Windows (including WSL), and Linux are supported

## Setup

1. Clone this repo using `git clone <REPOSITORY_URL> <YOUR_PROJECT_NAME>`
2. Move to the appropriate directory: `cd <YOUR_PROJECT_NAME>`.
3. Run `yarn` or `npm install` to install dependencies .
4. Run `yarn dev` or `npm run dev` to see the app at `http://localhost:3000`.

These scripts refer to the different stages of developing an application:

- `build` - Runs `hardhat` build which builds the smart contracts
- `deploymeem <network>` - Runs `hardhat` start which deploys the $MEEM Token Smart Contract
- `deploymemestonk <network>` - Runs `hardhat` start which deploys the Meme Stonk Market Smart Contract
- `deploymemestonkupgradeable <network>` - Runs `hardhat` start which deploys the upgradeable Meme Stonk Market Smart Contract

Now you're ready to rumble! :traffic_light:

## Tech

This application is built with the following packages/tech:

1. ETH/Polygon

   - Polygon is the blockchain of choice to that powers $MEEM token and Meme Stonk Market.

   - $MEEM Token

     - $MEEM ERC-20 Token is the platform’s currency which unlocks functionality within Meme Quests, the Meme Stonk Market, and in the future with Meme Contests and Meme battles as well.

   - Meme Quests

     - Meme Quests enable anyone to earn free $MEEM tokens while giving brands access to crowdsourced memes. Anyone may create a new account for free. Account holders then complete various tasks, called Quests and receive free $MEEM tokens in exchange.

   - Meme Stonk Market
     - The Meme Stonk Market Game enables players to share memes and speculate on meme popularity with a simulated market environment. Each Meme Stonk will be initialized on an ERC-1155 Token Smart Contract with a unique Stonk ID. To speculate on the popularity of a meme a player must use $MEEM tokens to buy Stonks of their favorite Memes which increases or decreases the Memes popularity values.

2. Openzeppelin

   - Smart Contracts

     - Majority of the smart contract logic is powered by Openzeppelin's smart contract templates. This serves as a tested & secure smart contract backbone to power Meme Market.

   - Defender

     - Defender is used as a relayer to process Meta Transactions. Meta Transaction (gasless transaction) is a concept, in the context of EVM, where a user does not need to pay for their blockchain transaction gas fees. Instead of gas fees, each user will pay a transaction fee in $MEEM to Meme Market to avoid spammy behavior. Below is the transaction flow:

       1. User prepares the transaction on front-end
       2. User signs the transaction using their browser or mobile wallet.
       3. Signed transaction is sent to the back-end api
       4. Signed transaction is processed and sent to Defender Relayer to be paid for and executed
       5. Relayer pays for the gas fees & sends the transaction to the intended address
       6. Transaction is securely executed on the blockchain

## Authors

- Bhargav Patel (bhargav@meme.market)
- Eric Gilbert-Williams (eric@meme.market)
