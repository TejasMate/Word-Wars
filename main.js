// Word Wars Wallet Integration, Game State Display, and Word Submission
// Adapted from Word Wars sample and SceneLogin/ScenePlay/SceneGameOver (AOGames main.js)

const processId = "ewhFeEpwnsmEkxhcXBur6XcLSEvckA9ykAHukRzYlMc";

document.addEventListener("DOMContentLoaded", () => {
  const connectButton = document.getElementById("connect-wallet");
  const disconnectButton = document.getElementById("disconnect-wallet");
  const statusText = document.getElementById("status");
  const gameArea = document.getElementById("game-area");
  const roundDisplay = document.getElementById("round-display");
  const lettersDisplay = document.getElementById("letters-display");
  const pointsDisplay = document.getElementById("points-display");
  const tokensDisplay = document.getElementById("tokens-display");
  const wordsDisplay = document.getElementById("words-display");
  const boostDisplay = document.getElementById("boost-display");
  const pointsProgress = document.getElementById("points-progress");
  const tokensProgress = document.getElementById("tokens-progress");
  const leaderboardBody = document.getElementById("leaderboard-body");
  const wordInput = document.getElementById("word-input");
  const submitButton = document.getElementById("submit-word");
  const hintButton = document.getElementById("get-hint");
  const boostButton = document.getElementById("boost-up");
  const bombTargetInput = document.getElementById("bomb-target");
  const bombButton = document.getElementById("launch-bomb");
  const transferTargetInput = document.getElementById("transfer-target");
  const transferAmountInput = document.getElementById("transfer-amount");
  const transferButton = document.getElementById("transfer-tokens");
  const refreshLeaderboardButton = document.getElementById("refresh-leaderboard");
  const responseDiv = document.getElementById("response");
  let walletAddress = null;

  function showResponse(message, className) {
    responseDiv.textContent = message;
    responseDiv.className = className;
    responseDiv.classList.add("show");
    setTimeout(() => {
      responseDiv.classList.remove("show");
    }, 3000);
  }

  async function loadLeaderboard() {
    try {
      const dryrunResponse = await window.dryrun({
        process: processId,
        tags: [{ name: "Action", value: "GetLeaderboard" }]
      });
      const reply = dryrunResponse.Messages[0]?.Data || "";
      console.log("Dryrun leaderboard:", dryrunResponse, "Reply:", reply);

      if (reply.includes("Leaderboard")) {
        const colorCode = "\\x1B\\[[\\d;]*m";
        const entryRegex = new RegExp(
          `\\d+\\.\\s*${colorCode}*([\\w-]+.*?)${colorCode}*:.*?${colorCode}*(\\d+)${colorCode}*\\s*pts,.*?${colorCode}*(\\d+)${colorCode}*\\s*tokens`,
          "gm"
        );
        let entries = [];
        let match;
        while ((match = entryRegex.exec(reply)) !== null) {
          const address = match[1].trim();
          const score = match[2];
          const tokens = match[3];
          const shortAddress = address.length > 10 ? `${address.slice(0, 6)}...${address.slice(-4)}` : address;
          entries.push({ address: shortAddress, score, tokens });
        }

        if (entries.length === 0) {
          leaderboardBody.innerHTML = '<tr><td colspan="4" class="leaderboard-error">No leaderboard data available</td></tr>';
          showResponse("Leaderboard empty", "invalid");
          return;
        }

        entries = entries.slice(0, 5);
        leaderboardBody.innerHTML = entries
          .map((entry, index) => `
            <tr>
              <td>${index + 1}</td>
              <td>${entry.address}</td>
              <td>${entry.score}</td>
              <td>${entry.tokens}</td>
            </tr>
          `)
          .join("");
        // No response popup to avoid clutter
      } else {
        leaderboardBody.innerHTML = '<tr><td colspan="4" class="leaderboard-error">Error fetching leaderboard</td></tr>';
        showResponse(`Error fetching leaderboard: ${reply || "Unexpected response"}`, "invalid");
      }
    } catch (error) {
      console.error("Dryrun leaderboard failed:", error);
      leaderboardBody.innerHTML = '<tr><td colspan="4" class="leaderboard-error">Error fetching leaderboard</td></tr>';
      showResponse(`Error fetching leaderboard: ${error.message}`, "invalid");
    }
  }

  async function fetchGameState() {
    try {
      const result = await window.dryrun({
        process: processId,
        tags: [{ name: "Action", value: "GetState" }, { name: "Address", value: walletAddress || "" }]
      });
      const state = result.Messages[0]?.Data;
      if (!state) {
        throw new Error("No state data received");
      }

      const colorCode = "\\x1B\\[[\\d;]*m";
      const roundMatch = state.match(new RegExp(`Round:.*?${colorCode}*(\\d+)${colorCode}*`, "m"));
      const lettersMatch = state.match(new RegExp(`Letters:.*?${colorCode}*([^\\n]+)${colorCode}*`, "m"));
      const scoreMatch = state.match(new RegExp(`Score:.*?${colorCode}*(\\d+)${colorCode}*`, "m"));
      const wordsMatch = state.match(new RegExp(`Words:.*?${colorCode}*([^\\n]+)${colorCode}*`, "m"));
      const tokensMatch = state.match(new RegExp(`Tokens:.*?${colorCode}*(\\d+)${colorCode}*`, "m"));
      const boostMatch = state.match(new RegExp(`Boost Active:.*?${colorCode}*(Yes|No)${colorCode}*`, "m"));

      const round = roundMatch ? roundMatch[1] : "None";
      const letters = lettersMatch ? lettersMatch[1].trim() : "None";
      const points = scoreMatch && walletAddress ? scoreMatch[1] : "0";
      const words = wordsMatch && walletAddress ? (wordsMatch[1].trim() !== "None" ? wordsMatch[1].trim() : "None") : "None";
      const tokens = tokensMatch && walletAddress ? tokensMatch[1] : "0";
      const boostActive = boostMatch && walletAddress ? boostMatch[1] : "No";

      console.log("Fetched game state:", { tokens, points, words, boostActive });

      roundDisplay.textContent = round;
      lettersDisplay.textContent = letters;
      pointsDisplay.textContent = points;
      tokensDisplay.textContent = tokens;
      wordsDisplay.textContent = words;
      boostDisplay.textContent = boostActive;

      const pointsPercent = Math.min((parseInt(points) / 100) * 100, 100);
      const tokensPercent = Math.min((parseInt(tokens) / 100) * 100, 100);
      pointsProgress.style.width = `${pointsPercent}%`;
      tokensProgress.style.width = `${tokensPercent}%`;
    } catch (error) {
      console.error("Failed to fetch game state:", error);
      console.log("Fetched game state: { tokens: '0', points: '0', words: 'None', boostActive: 'No' } (error fallback)");
      showResponse(`Error fetching game state: ${error.message}`, "invalid");
      roundDisplay.textContent = "None";
      lettersDisplay.textContent = "None";
      pointsDisplay.textContent = "0";
      tokensDisplay.textContent = "0";
      wordsDisplay.textContent = "None";
      boostDisplay.textContent = "No";
      pointsProgress.style.width = "0%";
      tokensProgress.style.width = "0%";
    }
  }

  connectButton.addEventListener("click", async () => {
    try {
      if (!window.arweaveWallet) {
        statusText.textContent = "ArConnect not installed";
        showResponse("Please install ArConnect wallet extension.", "invalid");
        console.error("ArConnect is not installed.");
        return;
      }

      await window.arweaveWallet.connect([
        "ACCESS_ADDRESS",
        "SIGNATURE",
        "SIGN_TRANSACTION"
      ]);
      walletAddress = await window.arweaveWallet.getActiveAddress();

      if (typeof window.createDataItemSigner !== "function") {
        throw new Error("createDataItemSigner is not available.");
      }

      statusText.textContent = `Connected: ${walletAddress.slice(0, 8)}...`;
      connectButton.style.display = "none";
      disconnectButton.style.display = "inline-block";
      gameArea.style.display = "flex";
      showResponse("Wallet connected successfully!", "");

      const signer = window.createDataItemSigner(window.arweaveWallet);
      await window.message({
        process: processId,
        tags: [
          { name: "Action", value: "JoinGame" },
          { name: "Address", value: walletAddress }
        ],
        signer: signer
      })
      .then(response => {
        console.log("Joined game:", response);
        showResponse("Joined game successfully!", "");
        fetchGameState();
        loadLeaderboard();
      })
      .catch(error => {
        console.error("Join failed:", error);
        showResponse(`Error joining game: ${error.message}`, "invalid");
        walletAddress = null;
        statusText.textContent = "Not connected";
        connectButton.style.display = "inline-block";
        disconnectButton.style.display = "none";
        gameArea.style.display = "none";
        roundDisplay.textContent = "None";
        lettersDisplay.textContent = "None";
        pointsDisplay.textContent = "0";
        tokensDisplay.textContent = "0";
        wordsDisplay.textContent = "None";
        boostDisplay.textContent = "No";
        pointsProgress.style.width = "0%";
        tokensProgress.style.width = "0%";
      });
    } catch (error) {
      console.error("Wallet connection failed:", error);
      showResponse(`Error connecting wallet: ${error.message}`, "invalid");
    }
  });

  disconnectButton.addEventListener("click", async () => {
    try {
      if (window.arweaveWallet) {
        await window.arweaveWallet.disconnect();
      }
      walletAddress = null;
      statusText.textContent = "Not connected";
      connectButton.style.display = "inline-block";
      disconnectButton.style.display = "none";
      gameArea.style.display = "none";
      showResponse("Wallet disconnected successfully!", "");
      roundDisplay.textContent = "None";
      lettersDisplay.textContent = "None";
      pointsDisplay.textContent = "0";
      tokensDisplay.textContent = "0";
      wordsDisplay.textContent = "None";
      boostDisplay.textContent = "No";
      pointsProgress.style.width = "0%";
      tokensProgress.style.width = "0%";
      leaderboardBody.innerHTML = "";
      wordInput.value = "";
      bombTargetInput.value = "";
      transferTargetInput.value = "";
      transferAmountInput.value = "";
      console.log("Wallet disconnected");
    } catch (error) {
      console.error("Wallet disconnect failed:", error);
      showResponse(`Error disconnecting wallet: ${error.message}`, "invalid");
    }
  });

  refreshLeaderboardButton.addEventListener("click", () => {
    loadLeaderboard();
  });

  submitButton.addEventListener("click", async () => {
    if (!walletAddress) {
      showResponse("Please connect wallet first", "invalid");
      return;
    }

    const word = wordInput.value.trim().toUpperCase();
    if (!word) {
      showResponse("Please enter a word", "invalid");
      return;
    }

    try {
      const signer = window.createDataItemSigner(window.arweaveWallet);
      const dryrunResponse = await window.dryrun({
        process: processId,
        tags: [
          { name: "Action", value: "SubmitWord" },
          { name: "Address", value: walletAddress },
          { name: "Word", value: word }
        ],
        signer: signer
      });
      const reply = dryrunResponse.Messages[0]?.Data || "";
      console.log("Dryrun word submission:", dryrunResponse, "Reply:", reply);

      if (reply.includes("Success")) {
        const scoreMatch = reply.match(/Points: \+(\d+)/);
        const score = scoreMatch ? scoreMatch[1] : word.length;
        showResponse(`Correct: ${word} (+${score} points)`, "correct");
        wordInput.value = "";

        try {
          const messageResponse = await window.message({
            process: processId,
            tags: [
              { name: "Action", value: "SubmitWord" },
              { name: "Address", value: walletAddress },
              { name: "Word", value: word }
            ],
            signer: signer
          });
          console.log("Message word submission:", messageResponse);
          fetchGameState();
          loadLeaderboard();
        } catch (messageError) {
          console.error("Message submission failed:", messageError);
          showResponse(`Error persisting word ${word}: ${messageError.message}`, "invalid");
        }
      } else if (reply.includes("already used")) {
        showResponse(`Reused: ${word} (already submitted by you)`, "reused");
        wordInput.value = "";
      } else if (reply.includes("Invalid")) {
        showResponse(`Invalid: ${word} (check letters or dictionary)`, "invalid");
      } else {
        showResponse(`Error: ${word} (unexpected response)`, "invalid");
      }
    } catch (error) {
      console.error("Dryrun submission failed:", error);
      showResponse(`Error submitting word: ${error.message}`, "invalid");
    }
  });

  hintButton.addEventListener("click", async () => {
    if (!walletAddress) {
      showResponse("Please connect wallet first", "invalid");
      return;
    }

    console.log("GetHint called with walletAddress:", walletAddress);
    try {
      const signer = window.createDataItemSigner(window.arweaveWallet);
      const hintTags = [
        { name: "Action", value: "GetHint" },
        { name: "Address", value: walletAddress }
      ];
      console.log("GetHint dryrun tags:", hintTags);

      const dryrunResponse = await window.dryrun({
        process: processId,
        tags: hintTags,
        signer: signer
      });
      const reply = dryrunResponse.Messages[0]?.Data || "";
      console.log("Dryrun get hint:", dryrunResponse, "Reply:", reply);

      const colorCode = "\\x1B\\[[\\d;]*m";
      if (reply.includes("Suggested Word:")) {
        const hintMatch = reply.match(new RegExp(`Suggested Word:.*?${colorCode}*(\\w+)${colorCode}*`, "m"));
        const hint = hintMatch ? hintMatch[1] : "Unknown";
        showResponse(`Hint: ${hint} (will cost 5 tokens)`, "correct");

        try {
          const messageResponse = await window.message({
            process: processId,
            tags: hintTags,
            signer: signer
          });
          console.log("Message get hint:", messageResponse);
          showResponse(`Hint: ${hint} (-5 tokens)`, "correct");
          fetchGameState();
          loadLeaderboard();
        } catch (messageError) {
          console.error("Message get hint failed:", messageError);
          showResponse(`Error persisting hint: ${messageError.message}`, "invalid");
        }
      } else if (reply.includes("Not enough tokens")) {
        showResponse("Not enough tokens for hint (need 5)", "invalid");
      } else {
        showResponse(`Error getting hint: ${reply || "Unexpected response"}`, "invalid");
      }
    } catch (error) {
      console.error("Dryrun get hint failed:", error);
      showResponse(`Error getting hint: ${error.message}`, "invalid");
    }
  });

  boostButton.addEventListener("click", async () => {
    if (!walletAddress) {
      showResponse("Please connect wallet first", "invalid");
      return;
    }

    console.log("BoostUp called with walletAddress:", walletAddress);
    try {
      const signer = window.createDataItemSigner(window.arweaveWallet);
      const boostTags = [
        { name: "Action", value: "BoostUp" },
        { name: "Address", value: walletAddress }
      ];
      console.log("BoostUp dryrun tags:", boostTags);

      const dryrunResponse = await window.dryrun({
        process: processId,
        tags: boostTags,
        signer: signer
      });
      const reply = dryrunResponse.Messages[0]?.Data || "";
      console.log("Dryrun boost up:", dryrunResponse, "Reply:", reply);

      if (reply.includes("Boost Activated")) {
        showResponse(`Boost activated! Next word scores double (will cost 3 tokens)`, "correct");

        try {
          const messageResponse = await window.message({
            process: processId,
            tags: boostTags,
            signer: signer
          });
          console.log("Message boost up:", messageResponse);
          showResponse(`Boost activated! Next word scores double (-3 tokens)`, "correct");
          fetchGameState();
          loadLeaderboard();
        } catch (messageError) {
          console.error("Message boost up failed:", messageError);
          showResponse(`Error persisting boost: ${messageError.message}`, "invalid");
        }
      } else if (reply.includes("Not enough tokens")) {
        showResponse("Not enough tokens for boost (need 3)", "invalid");
      } else if (reply.includes("Boost already active")) {
        showResponse("Boost already active", "invalid");
      } else {
        showResponse(`Error activating boost: ${reply || "Unexpected response"}`, "invalid");
      }
    } catch (error) {
      console.error("Dryrun boost up failed:", error);
      showResponse(`Error activating boost: ${error.message}`, "invalid");
    }
  });

  bombButton.addEventListener("click", async () => {
    if (!walletAddress) {
      showResponse("Please connect wallet first", "invalid");
      return;
    }

    const targetAddress = bombTargetInput.value.trim();
    if (!targetAddress) {
      showResponse("Please enter a target wallet address", "invalid");
      return;
    }

    if (!/^[a-zA-Z0-9\-_]{43}$/.test(targetAddress)) {
      showResponse("Invalid wallet address format", "invalid");
      return;
    }

    console.log("Bomb called with walletAddress:", walletAddress, "targetAddress:", targetAddress);
    try {
      const signer = window.createDataItemSigner(window.arweaveWallet);
      const bombTags = [
        { name: "Action", value: "Bomb" },
        { name: "Address", value: walletAddress },
        { name: "TargetAddress", value: targetAddress }
      ];
      console.log("Bomb dryrun tags:", bombTags);

      const dryrunResponse = await window.dryrun({
        process: processId,
        tags: bombTags,
        signer: signer
      });
      const reply = dryrunResponse.Messages[0]?.Data || "";
      console.log("Dryrun bomb:", dryrunResponse, "Reply:", reply);

      const shortTarget = targetAddress.length > 10 ? `${targetAddress.slice(0, 6)}...${targetAddress.slice(-4)}` : targetAddress;

      const colorCode = "\\x1B\\[[\\d;]*m";
      if (reply.includes("Bomb Result")) {
        const bombMatch = reply.match(
          new RegExp(
            `Bomb Result.*?${colorCode}*([\\w-]+.*?)${colorCode}*\\s+bombed\\s+${colorCode}*([\\w-]+.*?)${colorCode}*:[\\s\\S]*?Removed Word:.*?${colorCode}*(\\w+)${colorCode}*.*?Points Lost:.*?${colorCode}*(\\d+)${colorCode}*.*?Tokens Spent:.*?${colorCode}*-(\\d+)${colorCode}*.*?New Token Balance:.*?${colorCode}*(\\d+)${colorCode}*`,
            "s"
          )
        );
        if (bombMatch) {
          const word = bombMatch[3];
          const pointsLost = bombMatch[4];
          const tokensSpent = bombMatch[5];
          showResponse(`Bombed ${shortTarget}! Removed ${word} (-${pointsLost} pts, -${tokensSpent} tokens)`, "correct");

          try {
            const messageResponse = await window.message({
              process: processId,
              tags: bombTags,
              signer: signer
            });
            console.log("Message bomb:", messageResponse);
            showResponse(`Bombed ${shortTarget}! Removed ${word} (-${pointsLost} pts, -${tokensSpent} tokens)`, "correct");
            bombTargetInput.value = "";
            fetchGameState();
            loadLeaderboard();
          } catch (messageError) {
            console.error("Message bomb failed:", messageError);
            showResponse(`Error persisting bomb: ${messageError.message}`, "invalid");
          }
        } else {
          console.log("Full reply:", reply);
          showResponse(`Error parsing bomb result`, "invalid");
        }
      } else if (reply.includes("Not enough tokens")) {
        showResponse("Not enough tokens for bomb (need 5)", "invalid");
      } else if (reply.includes("Invalid target")) {
        showResponse(`Invalid target: ${shortTarget} (not a player or same as sender)`, "invalid");
      } else {
        console.log("Full reply:", reply);
        showResponse(`Error launching bomb: ${reply || "Unexpected response"}`, "invalid");
      }
    } catch (error) {
      console.error("Dryrun bomb failed:", error);
      showResponse(`Error launching bomb: ${error.message}`, "invalid");
    }
  });

  transferButton.addEventListener("click", async () => {
    if (!walletAddress) {
      showResponse("Please connect wallet first", "invalid");
      return;
    }

    const targetAddress = transferTargetInput.value.trim();
    const amount = parseInt(transferAmountInput.value.trim());

    if (!targetAddress) {
      showResponse("Please enter a target wallet address", "invalid");
      return;
    }

    if (!amount || amount <= 0) {
      showResponse("Please enter a valid amount greater than 0", "invalid");
      return;
    }

    if (!/^[a-zA-Z0-9\-_]{43}$/.test(targetAddress)) {
      showResponse("Invalid wallet address format", "invalid");
      return;
    }

    console.log("TransferTokens called with walletAddress:", walletAddress, "targetAddress:", targetAddress, "amount:", amount);
    try {
      const signer = window.createDataItemSigner(window.arweaveWallet);
      const transferTags = [
        { name: "Action", value: "TransferTokens" },
        { name: "Address", value: walletAddress },
        { name: "TargetAddress", value: targetAddress },
        { name: "Amount", value: amount.toString() }
      ];
      console.log("TransferTokens dryrun tags:", transferTags);

      const dryrunResponse = await window.dryrun({
        process: processId,
        tags: transferTags,
        signer: signer
      });
      const reply = dryrunResponse.Messages[0]?.Data || "";
      console.log("Dryrun transfer tokens:", dryrunResponse, "Reply:", reply);

      const shortTarget = targetAddress.length > 10 ? `${targetAddress.slice(0, 6)}...${targetAddress.slice(-4)}` : targetAddress;

      const colorCode = "\\x1B\\[[\\d;]*m";
      if (reply.includes("Transfer Success")) {
        const transferMatch = reply.match(
          new RegExp(
            `Transfer Success.*?${colorCode}*([\\w-]+.*?)${colorCode}*\\s+transferred:.*?To:.*?${colorCode}*([\\w-]+.*?)${colorCode}*.*?Amount:.*?${colorCode}*(\\d+)${colorCode}*.*?New Balance:.*?${colorCode}*(\\d+)${colorCode}*`,
            "s"
          )
        );
        if (transferMatch) {
          const transferAmount = transferMatch[3];
          const newBalance = transferMatch[4];
          showResponse(`Transferred ${transferAmount} tokens to ${shortTarget}! New balance: ${newBalance}`, "correct");

          try {
            const messageResponse = await window.message({
              process: processId,
              tags: transferTags,
              signer: signer
            });
            console.log("Message transfer tokens:", messageResponse);
            showResponse(`Transferred ${transferAmount} tokens to ${shortTarget}! New balance: ${newBalance}`, "correct");
            transferTargetInput.value = "";
            transferAmountInput.value = "";
            fetchGameState();
            loadLeaderboard();
          } catch (messageError) {
            console.error("Message transfer tokens failed:", messageError);
            showResponse(`Error persisting transfer: ${messageError.message}`, "invalid");
          }
        } else {
          console.log("Full reply:", reply);
          showResponse(`Error parsing transfer result`, "invalid");
        }
      } else if (reply.includes("Not enough tokens")) {
        showResponse("Not enough tokens for transfer", "invalid");
      } else if (reply.includes("Invalid target address or amount")) {
        showResponse("Invalid target address or amount", "invalid");
      } else if (reply.includes("Invalid or same target wallet address")) {
        showResponse(`Invalid target: ${shortTarget} (not a player or same as sender)`, "invalid");
      } else if (reply.includes("Invalid or missing player wallet address")) {
        showResponse("Invalid or missing player wallet address", "invalid");
      } else if (reply.includes("Process ID does not match")) {
        showResponse("Process ID does not match player wallet address", "invalid");
      } else {
        console.log("Full reply:", reply);
        showResponse(`Error transferring tokens: ${reply || "Unexpected response"}`, "invalid");
      }
    } catch (error) {
      console.error("Dryrun transfer tokens failed:", error);
      showResponse(`Error transferring tokens: ${error.message}`, "invalid");
    }
  });

  wordInput.addEventListener("keypress", (event) => {
    if (event.key === "Enter") {
      submitButton.click();
    }
  });
});