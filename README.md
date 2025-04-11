# Word Wars - AO Word Game

**Word Wars** is a multiplayer word-building game built in Lua for the `ao` decentralized computing platform using the `aos` operating system. Players compete to form words from a shared set of letters, earn points and tokens, and strategically disrupt opponents with bombs. This README provides instructions for loading and running the game, along with an overview of its features and commands.

> **Note**: A web version of Word Wars is currently in progress to enhance accessibility beyond the `aos` CLI.

## Purpose

Word Wars is designed as an engaging, decentralized game where players:
- Form words from a randomly generated letter pool each round.
- Earn points based on letter rarity and speed, plus tokens for in-game actions.
- Use tokens to bomb opponents or buy hints, adding a layer of strategy.

It’s a showcase of how to build interactive, multiplayer experiences on `ao` using Lua.

## Features

- **Rounds**: A new set of 10 random letters is generated every minute (configurable via cron).
- **Word Submission**: Players submit words using available letters, earning points (based on Scrabble-like rarity) and tokens.
- **Usernames**: Players can set unique usernames (up to 15 characters) during registration for a personalized experience.
- **Token System**:
  - New players receive 10 tokens upon joining.
  - Earn tokens by submitting words (points = tokens earned).
  - Spend tokens on actions like bombing or buying hints.
- **Bomb Mechanic**: Spend 5 tokens to remove an opponent’s last word, reducing their score.
- **Token Transfers**: Send tokens to other players by their username.
- **Hints**: Free hints or paid hints (2 tokens) suggest valid words.
- **Leaderboard**: Tracks top players by score, displayed with usernames.
- **GUI**: Text-based panels provide game state, player info, and command feedback.

## Prerequisites

- **NodeJS**: Version 20+ (required to run `aos`).
- **aos**: Install via `npm i -g https://get_ao.g8way.io`.
- **Wallet**: An Arweave wallet file (e.g., `wallet.json`) or let `aos` generate one (`~/.aos.json`).

## How to Load and Run

1. **Install aos**:
   ```sh
   npm i -g https://get_ao.g8way.io
   ```

2. **Start aos**:
   ```sh
   aos --wallet wallet.json  # Replace with your wallet file, or omit for a new one
   ```

3. **Deploy the Game** (optional, for a persistent process):
   ```sh
   aos --deploy word-wars.lua --wallet wallet.json
   ```
   - Note the process ID (e.g., `svsmTtQkbZ30aVUdHHDGlO1h_g-99UcdCoMs7F3iuIA`) returned after deployment.

4. **Load Locally** (for testing):
   - Save `word-wars.lua` in your working directory.
   - In the `aos` prompt:
     ```lua
     .load word-wars.lua
     ```

5. **Join the Game**:
   - If deployed, use the process ID as the `Target`:
     ```lua
     Send({Target = "svsmTtQkbZ30aVUdHHDGlO1h_g-99UcdCoMs7F3iuIA", Action = "JoinGame", Username = "Alice"})
     ```
   - If local, it runs in your current process automatically.

6. **Play**:
   - Use commands (see below) to interact with the game.
   - Check `Inbox[#Inbox]` for responses after each action.

## Handlers and Commands

Word Wars uses the following `Handlers` to manage gameplay. Each corresponds to a specific `Action` tag you can send via `Send()`:

- **JoinGame**:
  - **Command**: `Send({Target = "svsmTtQkbZ30aVUdHHDGlO1h_g-99UcdCoMs7F3iuIA", Action = "JoinGame", Username = "YourName"})`
  - Registers you with an optional username and mints 10 tokens for new players.
- **SubmitWord**:
  - **Command**: `Send({Target = "svsmTtQkbZ30aVUdHHDGlO1h_g-99UcdCoMs7F3iuIA", Action = "SubmitWord", Word = "BOX"})`
  - Submits a word if valid, awarding points and tokens.
- **Bomb**:
  - **Command**: `Send({Target = "svsmTtQkbZ30aVUdHHDGlO1h_g-99UcdCoMs7F3iuIA", Action = "Bomb", Target = "player_id"})`
  - Spends 5 tokens to remove a target’s last word (use their AO process ID).
- **TransferTokens**:
  - **Command**: `Send({Target = "svsmTtQkbZ30aVUdHHDGlO1h_g-99UcdCoMs7F3iuIA", Action = "TransferTokens", Receiver = "Bob", Amount = "5"})`
  - Transfers tokens to another player by username.
- **GetLeaderboard**:
  - **Command**: `Send({Target = "svsmTtQkbZ30aVUdHHDGlO1h_g-99UcdCoMs7F3iuIA", Action = "GetLeaderboard"})`
  - Displays the top 5 players by score.
- **GetState**:
  - **Command**: `Send({Target = "svsmTtQkbZ30aVUdHHDGlO1h_g-99UcdCoMs7F3iuIA", Action = "GetState"})`
  - Shows current round, letters, and all players’ stats.
- **GetHint**:
  - **Command**: `Send({Target = "svsmTtQkbZ30aVUdHHDGlO1h_g-99UcdCoMs7F3iuIA", Action = "GetHint"})`
  - Provides a free hint (valid word).
- **BuyHint**:
  - **Command**: `Send({Target = "svsmTtQkbZ30aVUdHHDGlO1h_g-99UcdCoMs7F3iuIA", Action = "BuyHint"})`
  - Costs 2 tokens for a hint.

## Testing Multiplayer

To test with multiple players:
1. Open separate `aos` instances with different wallets:
   ```sh
   aos --wallet alice.json
   aos --wallet bob.json
   ```
2. Join from each instance with unique usernames and interact using the process ID of the deployed game.

## Web Version

A web-based interface for Word Wars is **in progress**, aiming to simplify interaction without needing the `aos` CLI. Stay tuned for updates!

## Contributing

Feel free to fork this project, enhance features, or suggest improvements via pull requests. See the `ao Cookbook` [CONTRIBUTING.md](https://github.com/permaweb/ao-cookbook/blob/main/CONTRIBUTING.md) for guidelines.

## License

Apache-2.0

---

This README provides a clear, concise guide for users to get started with `word-wars.lua`, focusing on its Lua-based nature and `aos` integration, while highlighting its features and commands. Let me know if you’d like to adjust anything!
