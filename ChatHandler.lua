--============================================== DESCRIPTION ===========================================================
-- The ChatHandler handles the exchange of Data and special functionality via Chat.
-- The ingame workflow to use this feature is for the group leader to use one of the "Special Commands". For the data
-- exchange the addon will post the encrypted data to the Chat-Input box of all group members that have this addon.
-- It is not possible to automatically send Messages, so the user has to press ENTER to manually send the code.
--=============================================== SETUP ================================================================
local RO = RO

RO.Chat = {}
local this = RO.Chat
local Chat = RO.Chat

--========================================== LOCAL VARIABLES ===========================================================

-- Modules that want to use the ChatHandler have to register a prefix.
-- Prefix are always sent after an special identifier symbol which gets generated automatically by the ChatHandler.
local customPrefixTable = {}
-- identifier used to seperate submessages
local identifierNum = 33
local identifierSymbol = string.char(identifierNum)
-- prefix that gets sent at the start of the message as identifier
local prefix = "S###"
-- used for special chat commands that will not get interpreted as a message but as a request and call a function
local specialPrefix = "S#??"

-- Variables for Code Generation
local codeKey = 70
local offset = 40
local seperatorNum = 35
local seperatorChar = string.char(seperatorNum)

--========================================== LOCAL FUNCTIONS ===========================================================

--[[ Splits a message into a submessages. Submessages only contain data, without identifiers
     Returns a list of the form:
     [customPrefix] = subMessage ]]
local function ExtractSubMessages( message )
    local length = #message
    -- index will always the first unknown element in the message.
    local index = 1
    -- distance from index
    local offset = 0
    -- all submessages that have been found so far
    local submessages = { }

    -- AFTERWARDS: submessages contains all substrings.
    while(index < length) do
        -- should always evaluate as true
        if( message:byte(index) == identifierNum ) then
            -- check if there is any data following. (at the same makes sure we won't index nil in the next step)
            if( length - index > 1 ) then
                -- the identifier has been processed, so set index to next.
                index = index + 1
                offset = 0
                -- find the next identifierSymbol.
                -- AFTERWARDS: index + offset = position of next identifier
                while((index + offset) <= length and message:sub(index + offset, index + offset) ~= identifierSymbol ) do
                    offset = offset + 1
                end
                --== process the discovered substring ==
                if(index + offset > length) then
                    -- there is no more submessages
                    submessages[message:sub(index, index)] = (message:sub(index + 1))
                else
                    -- we found a new identifier
                    submessages[message:sub(index, index)] = (message:sub(index + 1, index + offset - 1))
                end
                index = index + offset
            end
        end

        -- only time we can get here is if the message that we get as parameter doesn't start with an identifier symbol.
        -- In that case, just ingore all data before the first identifier
        index = index +1
    end
    return submessages
end




--========================================= PUBLIC FUNCTIONS ===========================================================

--[[
Receives a number and generates a String from it that can be sent in chat
 ]]
function Chat.GenerateCode(number)
    local representationTable = {}
    local remainder, processed, newNum
    local code = ""

    -- AFTERWARDS: resultTable contains number represenation to base (codeKey).
    -- Algorithm used analog to decimal number => binary number.
    while(number > 0) do

        -- initialize
        remainder = 0
        processed = 0

        -- divide by key, safe remainder and continue with the rest
        remainder = number % codeKey
        newNum = math.floor(number / codeKey)
        processed = number - newNum
        local s = "Num: " .. number .. "\tR: " .. remainder .. "\tP:" .. processed
        --d(s)
        number = newNum

        --insert new element at the start of the list and add the local offset to it.
        table.insert(representationTable,remainder)
    end

    for i,v in ipairs(representationTable) do
        code = code .. string.char(v+offset)
        --d(code)
    end

    return code
end


function Chat.ProcessCode( code )
    local representationTable = {}
    local num = 0
    --d(code)
    for i=1, #code do
        table.insert(representationTable,i,code:byte(i)-offset)
    end
    --d(representationTable)


    for i,v in ipairs(representationTable) do
        num = num + v*(codeKey^(i-1))
    end
    --d(num)

    return num

end

-- Initializes the ChatHandler.
function Chat.Init()

end

-- Generate a string containing information from all modules and paste it to Chat (USER HAS TO PRESS ENTER TO SEND)
function Chat.SendMessage()
    local message = prefix
    -- Tell all registered modules to send
    for k, v in pairs(customPrefixTable) do
        message =   message .. identifierSymbol .. k .. v.GenerateChatData()
    end
    -- Will paste the string to the chat-input box. (USER HAS TO PRESS ENTER TO SEND)
    StartChatInput(message,CHAT_CHANNEL_PARTY,nil)
end

-- Handles the
function Chat.ProcessMessage( atname, message )
    -- Check if message needs handling
    local pre = message:sub(1, #prefix)
    if( pre ~= prefix ) then
        -- Either message is a request for a special command or it's just a normal message
        -- CASE: Special Command
        if( pre == specialPrefix ) then
            -- make sure it was sent by Group Leader to prevent trolling
            if(GetUnitDisplayName(GetGroupLeaderUnitTag()) == atname) then
                Chat.SpecialPrefix(message:sub(#prefix+1,#message))
            else
                -- insult imposters
                d(atname .. "is a fa'goat")
            end
        end
    end

    -- Get all submessages
    local submessages = ExtractSubMessages( message )

    -- Redirect Submessage to correct modules
    for customPrefix, module in pairs(submessages) do
        if( customPrefixTable[customPrefix] ~= nil ) then
            customPrefixTable[customPrefix].ProcessChatData(atname, module)
        end
    end
end

-- Used to send special commands
function Chat.SendSpecial( num )
    if(IsUnitGroupLeader("player")) then
        StartChatInput(specialPrefix..num,CHAT_CHANNEL_PARTY,nil)
    end

end

-- Used to process special commands
function Chat.SpecialPrefix( num )

    if ( num == "1") then
        RO.Combat.ToggleDamageVisGlobal()
    elseif (num == "2") then
        RO.Combat.ResetCombatData()
    end
end

-- Used for other modules to use the Chat handler.
function Chat.RegisterPrefix( prefix , module )
    -- prefix has to have length 1 and must not be in use already
    if(#prefix ~= 1 or customPrefixTable[prefix] ~= nil) then
        return false
    else
        customPrefixTable[prefix] = module
        return true
    end
end


