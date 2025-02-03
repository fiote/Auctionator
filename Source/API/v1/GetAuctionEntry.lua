function Auctionator.API.v1.GetAuctionEntryByItemID(callerID, itemID, itemLevel)
  Auctionator.API.InternalVerifyID(callerID)

  if type(itemID) ~= "number" then
    return
  end

  if itemLevel ~= nil and type(itemLevel) ~= "number" then
    Auctionator.API.ComposeError(
      callerID,
      "Usage Auctionator.API.v1.GetAuctionEntryByItemID(string, number, number)"
    )
  end

  if Auctionator.Database == nil then
    return nil
  end

  local dbKey = tostring(itemID)

  if itemLevel ~= nil then
    dbKey = 'g:' .. itemID .. ':' .. itemLevel
  end

  return Auctionator.Database:GetEntry(dbKey)
end

function Auctionator.API.v1.GetAvailableByItemID(callerID, itemID, itemLevel)
  Auctionator.API.InternalVerifyID(callerID)

  if type(itemID) ~= "number" then
    return
  end

  if itemLevel ~= nil and type(itemLevel) ~= "number" then
    Auctionator.API.ComposeError(
      callerID,
      "Usage Auctionator.API.v1.GetAuctionEntryByItemID(string, number, number)"
    )
  end

  if Auctionator.Database == nil then
    return nil
  end

  local dbKey = tostring(itemID)

  if itemLevel ~= nil then
    dbKey = 'g:' .. itemID .. ':' .. itemLevel
  end

  if self.db[dbKey] ~= nil then
    return self.db[dbKey].available
  else
    return nil
  end
end

function Auctionator.API.v1.GetAuctionEntryByItemLink(callerID, itemLink)
  Auctionator.API.InternalVerifyID(callerID)

  if type(itemLink) ~= "string" then
    Auctionator.API.ComposeError(
      callerID,
      "Usage Auctionator.API.v1.GetAuctionEntryByItemLink(string, string)"
    )
  end

  if Auctionator.Database == nil then
    return nil
  end

  local dbKeys = nil
  -- Use that the callback is called immediately (and populates dbKeys) if the
  -- item info for item levels is available now.
  Auctionator.Utilities.DBKeyFromLink(itemLink, function(dbKeysCallback)
    dbKeys = dbKeysCallback
  end)

  if dbKeys then
    return Auctionator.Database:GetFirstEntry(dbKeys)
  else
    return Auctionator.Database:GetEntry(
      Auctionator.Utilities.BasicDBKeyFromLink(itemLink)
    )
  end
end
