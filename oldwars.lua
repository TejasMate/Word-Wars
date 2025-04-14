-- AO Word Wars: Game Logic with Tokens, GUI, Wallet Addresses (Colorful, Wallet Address-Based Bomb, GetHint, BoostUp)

-- ANSI Color Codes for Styling
Colors = {
  gray = "\27[90m",
  blue = "\27[34m",
  green = "\27[32m",
  red = "\27[31m",
  reset = "\27[0m"
}

-- Game State
Letters = Letters or {}
Players = Players or {}
Leaderboard = Leaderboard or {}
Round = Round or 1
RoundStart = RoundStart or 0

-- Letter Point Values (based on rarity, inspired by Scrabble, only allowed letters)
LetterValues = {
  A=1, R=1, T=1, H=4, N=1, E=1, B=3, I=1, P=3, U=1,
  D=2, O=1, G=3, C=3, Z=10, Y=3, X=8
}

-- Valid Words Dictionary (Minimal, Using A,R,T,H,N,E,B,I,P,U,D,O,G,C,Z,Y,X)
ValidWords = {
  ["CAT"] = true,
  ["DOG"] = true,
  ["PUT"] = true,
  ["BIT"] = true,
  ["NET"] = true,
  ["RAT"] = true,
  ["HAT"] = true
}

-- Utility: Get table keys
function table.keys(tbl)
  local keys = {}
  for k in pairs(tbl) do keys[#keys + 1] = k end
  return keys
end

-- Calculate Points Based on Letter Rarity
function getLetterPoints(word)
  local points = 0
  for i = 1, #word do
    local char = string.sub(word, i, i)
    points = points + (LetterValues[char] or 1)
  end
  return points
end

-- Initialize Letters (Random from A,R,T,H,N,E,B,I,P,U,D,O,G,C,Z,Y,X)
function generateLetters()
  local pool = {}
  local alphabet = {"A","R","T","H","N","E","B","I","P","U","D","O","G","C","Z","Y","X"}
  for i = #alphabet, 2, -1 do
    local j = math.random(i)
    alphabet[i], alphabet[j] = alphabet[j], alphabet[i]
  end
  for i = 1, 10 do
    pool[alphabet[i]] = 1
  end
  return pool
end

-- Start New Round with Leaderboard Token Bonus
function startRound()
  if Round > 1 then
    local sorted = {}
    for addr, score in pairs(Leaderboard) do
      sorted[#sorted + 1] = { address = addr, score = score }
    end
    table.sort(sorted, function(a, b) return a.score > b.score end)
    if sorted[1] then Players[sorted[1].address].tokens = (Players[sorted[1].address].tokens or 0) + 5 end
    if sorted[2] then Players[sorted[2].address].tokens = (Players[sorted[2].address].tokens or 0) + 3 end
    if sorted[3] then Players[sorted[3].address].tokens = (Players[sorted[3].address].tokens or 0) + 1 end
  end
  
  Letters = generateLetters()
  Round = Round + 1
  RoundStart = os.time()
  for _, data in pairs(Players) do
    data.words = {}
    data.wordOrder = {}
    data.boostActive = false
  end
  local letterStr = table.concat(table.keys(Letters), ", ")
  ao.send({ 
    Target = ao.env.Process.Id, 
    Tags = { Action = "New-Round" }, 
    Data = Colors.gray .. "Round " .. Colors.blue .. Round .. Colors.gray .. ": Letters = " .. Colors.blue .. letterStr .. Colors.reset 
  })
end

-- Validate Word
function isValidWord(word)
  local letterCounts = {}
  for k, v in pairs(Letters) do letterCounts[k] = v end
  word = string.upper(word)
  if not ValidWords[word] then return false end
  for i = 1, #word do
    local char = string.sub(word, i, i)
    if not letterCounts[char] or letterCounts[char] <= 0 then return false end
    letterCounts[char] = letterCounts[char] - 1
  end
  return true
end

-- Check if Wallet Address is Unique
function isAddressUnique(wallet_address)
  return not Players[wallet_address]
end

-- Get Display Address (Truncated for Readability)
function getDisplayAddress(address)
--  if #address > 12 then
--    return address:sub(1, 6) .. "..." .. address:sub(-6)
--  end
  return address
end

-- Simplified GUI Panel Helper (No Vertical Lines, No Truncation, Only Dashes)
function formatPanel(title, lines)
  local dashCount = math.max(20, #title + 10)
  local panel = Colors.gray .. string.rep("-", dashCount) .. "\n"
  panel = panel .. Colors.blue .. title .. Colors.gray .. "\n"
  for _, line in ipairs(lines) do
    panel = panel .. line .. "\n"
  end
  panel = panel .. string.rep("-", dashCount) .. Colors.reset
  return panel
end

-- Join Game Handler (Mandatory Wallet Address)
Handlers.add("JoinGame", Handlers.utils.hasMatchingTag("Action", "JoinGame"), function(msg)
  local wallet_address = msg.Tags.Address
  local process_id = msg.From
  
  if not wallet_address then
    ao.send({ 
      Target = process_id, 
      Tags = { Action = "JoinGameResponse" }, 
      Data = formatPanel("Error", { Colors.red .. "Wallet address required (Address=<wallet_address>)" .. Colors.reset }) 
    })
    return
  end
  
  if not isAddressUnique(wallet_address) then
    ao.send({ 
      Target = process_id, 
      Tags = { Action = "JoinGameResponse" }, 
      Data = formatPanel("Error", { Colors.red .. "Wallet address already in use: " .. getDisplayAddress(wallet_address) .. Colors.reset }) 
    })
    return
  end
  
  Players[wallet_address] = {
    score = 0,
    words = {},
    wordOrder = {},
    tokens = 10,
    boostActive = false,
    process_id = process_id
  }
  ao.send({ 
    Target = ao.env.Process.Id, 
    Tags = { Action = "Player-Joined" }, 
    Data = Colors.gray .. "Player " .. Colors.blue .. getDisplayAddress(wallet_address) .. Colors.gray .. " joined" .. Colors.reset 
  })
  
  local displayAddress = getDisplayAddress(wallet_address)
  local lines = {
    Colors.green .. "Welcome to AO Word Wars!" .. Colors.reset,
    Colors.gray .. "Wallet Address: " .. Colors.blue .. displayAddress .. Colors.reset,
    Colors.gray .. "Round: " .. Colors.blue .. Round .. Colors.reset,
    Colors.gray .. "Letters: " .. Colors.blue .. table.concat(table.keys(Letters), ", ") .. Colors.reset,
    Colors.gray .. "Your Tokens: " .. Colors.green .. Players[wallet_address].tokens .. Colors.gray .. " (10 minted!)" .. Colors.reset,
    Colors.gray .. "Commands:" .. Colors.reset,
    Colors.gray .. "  SubmitWord (Address=<wallet_address>, Word=<word>)" .. Colors.reset,
    Colors.gray .. "  Bomb (Address=<wallet_address>, TargetAddress=<wallet_address>)" .. Colors.reset,
    Colors.gray .. "  TransferTokens (Address=<wallet_address>, TargetAddress=<wallet_address>, Amount=<number>)" .. Colors.reset,
    Colors.gray .. "  GetLeaderboard, GetState, GetHint, BoostUp, ShowGUI" .. Colors.reset
  }
  ao.send({ 
    Target = process_id, 
    Tags = { Action = "JoinGameResponse" }, 
    Data = formatPanel("Welcome", lines) 
  })
end)

-- Submit Word Handler (No From Validation, Supports BoostUp)
Handlers.add("SubmitWord", Handlers.utils.hasMatchingTag("Action", "SubmitWord"), function(msg)
  local wallet_address = msg.Tags.Address
  local word = msg.Tags.Word
  
  if not wallet_address or not Players[wallet_address] then
    ao.send({ 
      Target = Players[wallet_address] and Players[wallet_address].process_id or msg.From, 
      Tags = { Action = "SubmitWordResponse" }, 
      Data = formatPanel("Error", { Colors.red .. "Invalid or missing wallet address" .. Colors.reset }) 
    })
    return
  end
  
  if not word or #word < 1 then
    ao.send({ 
      Target = Players[wallet_address].process_id, 
      Tags = { Action = "SubmitWordResponse" }, 
      Data = formatPanel("Error", { Colors.red .. "No word provided" .. Colors.reset }) 
    })
    return
  end
  
  word = string.upper(word)
  if Players[wallet_address].words[word] then
    ao.send({ 
      Target = Players[wallet_address].process_id, 
      Tags = { Action = "SubmitWordResponse" }, 
      Data = formatPanel("Error", { Colors.red .. "Word already used this round: " .. word .. Colors.reset }) 
    })
    return
  end
  
  if isValidWord(word) then
    local basePoints = getLetterPoints(word)
    local timeElapsed = os.time() - RoundStart
    local speedBonus = (timeElapsed <= 10) and 2 or 0
    local points = basePoints + speedBonus
    local tokensEarned = points
    local boostApplied = Players[wallet_address].boostActive
    if boostApplied then
      points = points * 2
      tokensEarned = tokensEarned * 2
      Players[wallet_address].boostActive = false
    end
    Players[wallet_address].score = (Players[wallet_address].score or 0) + points
    Players[wallet_address].tokens = (Players[wallet_address].tokens or 0) + tokensEarned
    Players[wallet_address].words[word] = true
    Players[wallet_address].wordOrder[#Players[wallet_address].wordOrder + 1] = word
    Leaderboard[wallet_address] = (Leaderboard[wallet_address] or 0) + points
    local displayAddress = getDisplayAddress(wallet_address)
    local lines = {
      Colors.blue .. displayAddress .. Colors.gray .. " formed:" .. Colors.reset,
      Colors.gray .. "Word: " .. Colors.blue .. word .. Colors.reset,
      Colors.gray .. "Points: +" .. Colors.green .. points .. Colors.gray .. " (Base: " .. basePoints .. ", Bonus: " .. speedBonus .. (boostApplied and ", Boost: x2" or "") .. ")" .. Colors.reset,
      Colors.gray .. "Tokens: +" .. Colors.green .. tokensEarned .. Colors.reset,
      Colors.gray .. "New Score: " .. Colors.green .. Players[wallet_address].score .. Colors.reset,
      Colors.gray .. "New Token Balance: " .. Colors.green .. Players[wallet_address].tokens .. Colors.reset
    }
    ao.send({ 
      Target = Players[wallet_address].process_id, 
      Tags = { Action = "SubmitWordResponse" }, 
      Data = formatPanel("Success", lines) 
    })
  else
    ao.send({ 
      Target = Players[wallet_address].process_id, 
      Tags = { Action = "SubmitWordResponse" }, 
      Data = formatPanel("Error", { Colors.red .. "Invalid word: " .. word .. Colors.reset }) 
    })
  end
end)

-- Bomb Handler (Wallet Address-Based, No Process ID Validation)
Handlers.add("Bomb", Handlers.utils.hasMatchingTag("Action", "Bomb"), function(msg)
  local player_address = msg.Tags.Address
  local target_address = msg.Tags.TargetAddress
  
  if not player_address or not Players[player_address] then
    ao.send({ 
      Target = Players[player_address] and Players[player_address].process_id or msg.From, 
      Tags = { Action = "BombResponse" }, 
      Data = formatPanel("Error", { Colors.red .. "Invalid or missing player wallet address" .. Colors.reset }) 
    })
    return
  end
  
  if not target_address then
    ao.send({ 
      Target = Players[player_address].process_id, 
      Tags = { Action = "BombResponse" }, 
      Data = formatPanel("Error", { Colors.red .. "No target wallet address provided (TargetAddress=<wallet_address>)" .. Colors.reset }) 
    })
    return
  end
  
  if not Players[target_address] or player_address == target_address then
    ao.send({ 
      Target = Players[player_address].process_id, 
      Tags = { Action = "BombResponse" }, 
      Data = formatPanel("Error", { Colors.red .. "Invalid or same target wallet address: " .. getDisplayAddress(target_address) .. Colors.reset }) 
    })
    return
  end
  
  if (Players[player_address].tokens or 0) < 5 then
    ao.send({ 
      Target = Players[player_address].process_id, 
      Tags = { Action = "BombResponse" }, 
      Data = formatPanel("Error", { Colors.red .. "Not enough tokens (need 5)" .. Colors.reset }) 
    })
    return
  end
  
  local lastWord = Players[target_address].wordOrder[#Players[target_address].wordOrder]
  if lastWord and Players[target_address].words[lastWord] then
    local points = getLetterPoints(lastWord)
    Players[target_address].score = math.max(0, Players[target_address].score - points)
    Leaderboard[target_address] = math.max(0, Leaderboard[target_address] - points)
    Players[target_address].words[lastWord] = nil
    table.remove(Players[target_address].wordOrder, #Players[target_address].wordOrder)
    Players[player_address].tokens = Players[player_address].tokens - 5
    local playerDisplayAddress = getDisplayAddress(player_address)
    local targetDisplayAddress = getDisplayAddress(target_address)
    local bomberLines = {
      Colors.blue .. playerDisplayAddress .. Colors.gray .. " bombed " .. Colors.blue .. targetDisplayAddress .. Colors.gray .. ":" .. Colors.reset,
      Colors.gray .. "Removed Word: " .. Colors.blue .. lastWord .. Colors.reset,
      Colors.gray .. "Points Lost: " .. Colors.green .. points .. Colors.reset,
      Colors.gray .. "Tokens Spent: " .. Colors.red .. "-5" .. Colors.reset,
      Colors.gray .. "New Token Balance: " .. Colors.green .. Players[player_address].tokens .. Colors.reset
    }
    local targetLines = {
      Colors.blue .. playerDisplayAddress .. Colors.gray .. " bombed your word:" .. Colors.reset,
      Colors.gray .. "Removed Word: " .. Colors.blue .. lastWord .. Colors.reset,
      Colors.gray .. "Points Lost: " .. Colors.green .. points .. Colors.reset,
      Colors.gray .. "New Score: " .. Colors.green .. Players[target_address].score .. Colors.reset
    }
    ao.send({ 
      Target = Players[player_address].process_id, 
      Tags = { Action = "BombResponse" }, 
      Data = formatPanel("Bomb Result", bomberLines) 
    })
    ao.send({ 
      Target = Players[target_address].process_id, 
      Tags = { Action = "BombNotification" }, 
      Data = formatPanel("Word Bombed", targetLines) 
    })
  else
    ao.send({ 
      Target = Players[player_address].process_id, 
      Tags = { Action = "BombResponse" }, 
      Data = formatPanel("Error", { Colors.red .. "Target has no words to bomb" .. Colors.reset }) 
    })
  end
end)

-- Transfer Tokens Handler (Wallet Address-Based)
Handlers.add("TransferTokens", Handlers.utils.hasMatchingTag("Action", "TransferTokens"), function(msg)
  local player_address = msg.Tags.Address
  local process_id = msg.From
  local target_address = msg.Tags.TargetAddress
  local amount = tonumber(msg.Tags.Amount)
  
  if not player_address or not Players[player_address] then
    ao.send({ 
      Target = process_id, 
      Tags = { Action = "TransferResponse" }, 
      Data = formatPanel("Error", { Colors.red .. "Invalid or missing player wallet address" .. Colors.reset }) 
    })
    return
  end
  
  if not target_address or not amount or amount <= 0 then
    ao.send({ 
      Target = process_id, 
      Tags = { Action = "TransferResponse" }, 
      Data = formatPanel("Error", { Colors.red .. "Invalid target address or amount" .. Colors.reset }) 
    })
    return
  end
  
  if not Players[target_address] or target_address == player_address then
    ao.send({ 
      Target = process_id, 
      Tags = { Action = "TransferResponse" }, 
      Data = formatPanel("Error", { Colors.red .. "Invalid or same target wallet address: " .. getDisplayAddress(target_address) .. Colors.reset }) 
    })
    return
  end
  
  if (Players[player_address].tokens or 0) < amount then
    ao.send({ 
      Target = process_id, 
      Tags = { Action = "TransferResponse" }, 
      Data = formatPanel("Error", { Colors.red .. "Not enough tokens" .. Colors.reset }) 
    })
    return
  end
  
  Players[player_address].tokens = Players[player_address].tokens - amount
  Players[target_address].tokens = (Players[target_address].tokens or 0) + amount
  local senderAddress = getDisplayAddress(player_address)
  local receiverAddress = getDisplayAddress(target_address)
  local lines = {
    Colors.blue .. senderAddress .. Colors.gray .. " transferred:" .. Colors.reset,
    Colors.gray .. "To: " .. Colors.blue .. receiverAddress .. Colors.reset,
    Colors.gray .. "Amount: " .. Colors.green .. amount .. Colors.gray .. " tokens" .. Colors.reset,
    Colors.gray .. "New Balance: " .. Colors.green .. Players[player_address].tokens .. Colors.reset
  }
  ao.send({ 
    Target = process_id, 
    Tags = { Action = "TransferResponse" }, 
    Data = formatPanel("Transfer Success", lines) 
  })
  ao.send({ 
    Target = Players[target_address].process_id, 
    Tags = { Action = "TransferReceived" }, 
    Data = formatPanel("Tokens Received", { 
      Colors.blue .. senderAddress .. Colors.gray .. " sent you " .. Colors.green .. amount .. Colors.gray .. " tokens" .. Colors.reset, 
      Colors.gray .. "New Balance: " .. Colors.green .. Players[target_address].tokens .. Colors.reset 
    }) 
  })
end)

-- Get Leaderboard Handler
Handlers.add("GetLeaderboard", Handlers.utils.hasMatchingTag("Action", "GetLeaderboard"), function(msg)
  local process_id = msg.From
  local sorted = {}
  for addr, score in pairs(Leaderboard) do
    sorted[#sorted + 1] = { address = addr, score = score, tokens = Players[addr].tokens or 0 }
  end
  table.sort(sorted, function(a, b) return a.score > b.score end)
  local lines = {}
  for i = 1, math.min(5, #sorted) do
    local address = getDisplayAddress(sorted[i].address)
    lines[#lines + 1] = Colors.gray .. i .. ". " .. Colors.blue .. address .. Colors.gray .. ": " .. Colors.green .. sorted[i].score .. Colors.gray .. " pts, " .. Colors.green .. sorted[i].tokens .. Colors.gray .. " tokens" .. Colors.reset
  end
  ao.send({ 
    Target = process_id, 
    Tags = { Action = "LeaderboardResponse" }, 
    Data = formatPanel("Leaderboard", lines) 
  })
end)

-- Get State Handler (Modified to show only self-player details)
Handlers.add("GetState", Handlers.utils.hasMatchingTag("Action", "GetState"), function(msg)
  local wallet_address = msg.Tags.Address
  local process_id = msg.From
  
  local lines = {
    Colors.gray .. "Round: " .. Colors.blue .. Round .. Colors.reset,
    Colors.gray .. "Letters: " .. Colors.blue .. table.concat(table.keys(Letters), ", ") .. Colors.reset
  }
  
  if wallet_address and Players[wallet_address] then
    local address = getDisplayAddress(wallet_address)
    local words = table.concat(Players[wallet_address].wordOrder, ", ")
    lines[#lines + 1] = Colors.gray .. "Player: " .. Colors.blue .. address .. Colors.reset
    lines[#lines + 1] = Colors.gray .. "  Score: " .. Colors.green .. (Players[wallet_address].score or 0) .. Colors.reset
    lines[#lines + 1] = Colors.gray .. "  Words: " .. Colors.blue .. (words ~= "" and words or "None") .. Colors.reset
    lines[#lines + 1] = Colors.gray .. "  Tokens: " .. Colors.green .. (Players[wallet_address].tokens or 0) .. Colors.reset
    lines[#lines + 1] = Colors.gray .. "  Boost Active: " .. Colors.blue .. (Players[wallet_address].boostActive and "Yes" or "No") .. Colors.reset
  else
    lines[#lines + 1] = Colors.gray .. "Player: " .. Colors.red .. "Not registered" .. Colors.reset
  end
  
  ao.send({ 
    Target = process_id, 
    Tags = { Action = "StateResponse" }, 
    Data = formatPanel("Game State", lines) 
  })
end)

-- Get Hint Handler (Costs 5 Tokens)
Handlers.add("GetHint", Handlers.utils.hasMatchingTag("Action", "GetHint"), function(msg)
  local wallet_address = msg.Tags.Address
  local process_id = msg.From
  
  if not wallet_address or not Players[wallet_address] then
    ao.send({ 
      Target = process_id, 
      Tags = { Action = "HintResponse" }, 
      Data = formatPanel("Error", { Colors.red .. "Invalid or missing wallet address" .. Colors.reset }) 
    })
    return
  end
  
  if (Players[wallet_address].tokens or 0) < 5 then
    ao.send({ 
      Target = process_id, 
      Tags = { Action = "HintResponse" }, 
      Data = formatPanel("Error", { Colors.red .. "Not enough tokens (need 5)" .. Colors.reset }) 
    })
    return
  end
  
  local validOptions = {}
  for word in pairs(ValidWords) do
    if isValidWord(word) then
      validOptions[#validOptions + 1] = word
    end
  end
  if #validOptions > 0 then
    local hint = validOptions[math.random(1, #validOptions)]
    Players[wallet_address].tokens = Players[wallet_address].tokens - 5
    local lines = {
      Colors.gray .. "Suggested Word: " .. Colors.blue .. hint .. Colors.reset,
      Colors.gray .. "Tokens Spent: " .. Colors.red .. "-5" .. Colors.reset,
      Colors.gray .. "New Token Balance: " .. Colors.green .. Players[wallet_address].tokens .. Colors.reset
    }
    ao.send({ 
      Target = process_id, 
      Tags = { Action = "HintResponse" }, 
      Data = formatPanel("Hint", lines) 
    })
  else
    ao.send({ 
      Target = process_id, 
      Tags = { Action = "HintResponse" }, 
      Data = formatPanel("Error", { Colors.red .. "No valid words found" .. Colors.reset }) 
    })
  end
end)

-- BoostUp Handler (Doubles Next Word's Points/Tokens)
Handlers.add("BoostUp", Handlers.utils.hasMatchingTag("Action", "BoostUp"), function(msg)
  local wallet_address = msg.Tags.Address
  local process_id = msg.From
  
  if not wallet_address or not Players[wallet_address] then
    ao.send({ 
      Target = process_id, 
      Tags = { Action = "BoostUpResponse" }, 
      Data = formatPanel("Error", { Colors.red .. "Invalid or missing wallet address" .. Colors.reset }) 
    })
    return
  end
  
  if Players[wallet_address].boostActive then
    ao.send({ 
      Target = process_id, 
      Tags = { Action = "BoostUpResponse" }, 
      Data = formatPanel("Error", { Colors.red .. "Boost already active" .. Colors.reset }) 
    })
    return
  end
  
  if (Players[wallet_address].tokens or 0) < 3 then
    ao.send({ 
      Target = process_id, 
      Tags = { Action = "BoostUpResponse" }, 
      Data = formatPanel("Error", { Colors.red .. "Not enough tokens (need 3)" .. Colors.reset }) 
    })
    return
  end
  
  Players[wallet_address].boostActive = true
  Players[wallet_address].tokens = Players[wallet_address].tokens - 3
  local lines = {
    Colors.gray .. "Boost activated! Your next valid word scores double points and tokens." .. Colors.reset,
    Colors.gray .. "Tokens Spent: " .. Colors.red .. "-3" .. Colors.reset,
    Colors.gray .. "New Token Balance: " .. Colors.green .. Players[wallet_address].tokens .. Colors.reset
  }
  ao.send({ 
    Target = process_id, 
    Tags = { Action = "BoostUpResponse" }, 
    Data = formatPanel("Boost Activated", lines) 
  })
end)

-- Show GUI Handler
Handlers.add("ShowGUI", Handlers.utils.hasMatchingTag("Action", "ShowGUI"), function(msg)
  local wallet_address = msg.Tags.Address
  local process_id = msg.From
  
  if not wallet_address or not Players[wallet_address] then
    ao.send({ 
      Target = process_id, 
      Tags = { Action = "GUIResponse" }, 
      Data = formatPanel("Error", { Colors.red .. "Invalid or missing wallet address" .. Colors.reset }) 
    })
    return
  end
  
  if Players[wallet_address].process_id ~= process_id then
    ao.send({ 
      Target = process_id, 
      Tags = { Action = "GUIResponse" }, 
      Data = formatPanel("Error", { Colors.red .. "Process ID does not match wallet address" .. Colors.reset }) 
    })
    return
  end
  
  local displayAddress = getDisplayAddress(wallet_address)
  local lines = {
    Colors.gray .. "Round: " .. Colors.blue .. Round .. Colors.reset,
    Colors.gray .. "Letters: " .. Colors.blue .. table.concat(table.keys(Letters), ", ") .. Colors.reset,
    Colors.gray .. "Wallet Address: " .. Colors.blue .. displayAddress .. Colors.reset,
    Colors.gray .. "Your Score: " .. Colors.green .. (Players[wallet_address].score or 0) .. Colors.reset,
    Colors.gray .. "Your Tokens: " .. Colors.green .. (Players[wallet_address].tokens or 0) .. Colors.reset,
    Colors.gray .. "Boost Active: " .. Colors.blue .. (Players[wallet_address].boostActive and "Yes" or "No") .. Colors.reset,
    Colors.gray .. "Your Words: " .. Colors.blue .. table.concat(table.keys(Players[wallet_address].words), ", ") .. Colors.reset,
    Colors.gray .. "Commands:" .. Colors.reset,
    Colors.gray .. "  SubmitWord (Address=<wallet_address>, Word=<word>)" .. Colors.reset,
    Colors.gray .. "  Bomb (Address=<wallet_address>, TargetAddress=<wallet_address>)" .. Colors.reset,
    Colors.gray .. "  TransferTokens (Address=<wallet_address>, TargetAddress=<wallet_address>, Amount=<number>)" .. Colors.reset,
    Colors.gray .. "  GetLeaderboard, GetState, GetHint, BoostUp, ShowGUI" .. Colors.reset
  }
  ao.send({ 
    Target = process_id, 
    Tags = { Action = "GUIResponse" }, 
    Data = formatPanel("AO Word Wars", lines) 
  })
end)

-- Initialize with Cron (Solution 1: No initial startRound call)
ao.send({ Target = ao.env.Process.Id, Tags = { Action = "Cron", Interval = "1m" } })
Handlers.add("Cron", Handlers.utils.hasMatchingTag("Action", "Cron"), startRound)