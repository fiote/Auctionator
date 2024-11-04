AuctionatorShoppingResultsRowMixin = CreateFromMixins(AuctionatorResultsRowTemplateMixin)
  
local function debugtable(tab) 
  fprint("=====================================")
  fprint("SIZE:", #tab)
  fprint("{")
  if not tab then
    fprint("nil")
  else
    for k,v in pairs(tab) do
      fprint('"'..k..'" = '..tostring(v))
    end
  end
  fprint("}")
  fprint("=====================================")
end

local verbose = false

local function fprint(...)
  if verbose then
    print(...)
  end
end

purchasing = nil
toretry = nil

function PurchaseCommodity(row, itemID, quantity, price, cell)
  local itemName, itemLink = C_Item.GetItemInfo(itemID)

  fprint('=====================================')
  fprint('STARTING PURCHASE', itemLink, 'x'..quantity)

  if purchasing then
    fprint('ALREADY PURCHASING')
    return false
  end

  StartOneClickFlow({
    row = row,
    itemID = itemID,
    quantity = quantity,
    cell = cell,
    unitPrice = price,
    totalPrice = price * quantity
  })

  return true  
end

function StartOneClickFlow(data)
  purchasing = {
    row = data.row,
    itemID = data.itemID,
    quantity = data.quantity,
    cell = data.cell,
    unitPrice = data.unitPrice,
    totalPrice = data.totalPrice
  }

  toretry = nil

  fprint('unitPrice', Auctionator.Utilities.CreatePaddedMoneyString(purchasing.unitPrice))
  fprint('totalPrice', Auctionator.Utilities.CreatePaddedMoneyString(purchasing.totalPrice))
  
  purchasing.cell.text:SetText("starting")
  purchasing.cell.text:SetTextColor(0.9, 0.9, 0.9, 1)
  C_AuctionHouse.StartCommoditiesPurchase(purchasing.itemID, purchasing.quantity)
end

function TryRetryPurchase()
  if toretry and not purchasing then
    fprint('RETRYING PURCHASE')
    StartOneClickFlow(toretry)
  end
end
-- ============================================================================
-- ON COMMODITY PRICE UPDATED
-- ============================================================================

local function OnCommodityPriceUpdatedEvent(self, event, newUnitPrice, newTotalPrice)
  fprint('---------------')
  fprint('OnCommodityPriceUpdatedEvent', event)

  if not purchasing then
    fprint('... not purchasing')
    return
  end

  local diffUnit = newUnitPrice - purchasing.unitPrice
  local diffTotal = newTotalPrice - purchasing.totalPrice
  local prDiff = diffUnit / purchasing.unitPrice * 100
  
  fprint('prDiff', prDiff)

  local dsDiff = string.format("%.1f%%", prDiff)
  if prDiff > 0 then
    dsDiff = '+'..dsDiff
  end

  fprint('dsDiff', dsDiff)
  
  if prDiff > 5 then
    fprint('newTotalPrice', Auctionator.Utilities.CreatePaddedMoneyString(newTotalPrice))
    fprint('diffTotal', Auctionator.Utilities.CreatePaddedMoneyString(diffTotal))

    fprint('CANCELLING PURCHASE')
    purchasing.cell.text:SetText(dsDiff)
    purchasing.cell.text:SetTextColor(1, 176/255, 0, 1)

    C_AuctionHouse.CancelCommoditiesPurchase()
    purchasing.row.rowData.purchased = false

    toretry = purchasing
    purchasing = nil

    fprint('=====================================')
    return
  end
  
  fprint('new price is ok!')
end

local f = CreateFrame("Frame")
f:RegisterEvent("COMMODITY_PRICE_UPDATED")
f:SetScript("OnEvent", OnCommodityPriceUpdatedEvent)

-- ============================================================================
-- ON COMMODITY PRICE UNAVAILABLE
-- ============================================================================

local function OnCommodityPriceUnavailableEvent(self, event)
  fprint('---------------')
  fprint('OnCommodityPriceUnavailableEvent', event)

  if not purchasing then
    return
  end

  purchasing.cell.text:SetText("unavailable")
  purchasing = nil
  
  fprint('=====================================')
end

local f = CreateFrame("Frame")
f:RegisterEvent("COMMODITY_PRICE_UNAVAILABLE")
f:SetScript("OnEvent", OnCommodityPriceUnavailableEvent)

-- ============================================================================
-- ON PURCHASE DROPPED
-- ============================================================================

local function OnPurchaseDroppedEvent(self, event)  
  fprint('---------------')
  fprint('OnPurchaseDroppedEvent', event)

  if not purchasing then
    return
  end
end

local f = CreateFrame("Frame")
f:RegisterEvent("AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED")
f:SetScript("OnEvent", OnPurchaseDroppedEvent)

-- ============================================================================
-- ON READY TO CONFIRM PURCHASE
-- ============================================================================

local function OnReadyToConfirmPurchaseEvent(self, event)
  fprint('---------------')
  fprint('OnReadyToConfirmPurchaseEvent', event)

  if not purchasing then
    return
  end

  purchasing.cell.text:SetText("confirming")
  C_AuctionHouse.ConfirmCommoditiesPurchase(purchasing.itemID, purchasing.quantity)
end

local f = CreateFrame("Frame")
f:RegisterEvent("AUCTION_HOUSE_THROTTLED_SYSTEM_READY")
f:SetScript("OnEvent", OnReadyToConfirmPurchaseEvent)

-- ============================================================================
-- ON COMMODITY PURCHASE SUCCEEDED
-- ============================================================================

local function OnPurchaseCompletedEvent(self, event)  
  fprint('---------------')
  fprint('OnPurchaseCompletedEvent', event)

  if not purchasing then
    return
  end

  purchasing.cell.text:SetText("purchased")
  purchasing.cell.text:SetTextColor(139/255, 195/255, 74/255, 1)
  purchasing.row.rowData.purchased = false
  purchasing = nil
  
  fprint('=====================================')
end

local f = CreateFrame("Frame")
f:RegisterEvent("AUCTION_HOUSE_PURCHASE_COMPLETED")
f:SetScript("OnEvent", OnPurchaseCompletedEvent)

-- ============================================================================
-- ON CLICK
-- ============================================================================

function AuctionatorShoppingResultsRowMixin:OnClick(button, ...)
  Auctionator.Debug.Message("AuctionatorShoppingResultsRowMixin:OnClick()")

  if IsModifiedClick("DRESSUP") then
    AuctionHouseBrowseResultsFrameMixin.OnBrowseResultSelected({}, self.rowData)

  elseif button == "RightButton" then
    if C_AuctionHouse.GetItemKeyInfo(self.rowData.itemKey) then
      local itemKeyInfo = C_AuctionHouse.GetItemKeyInfo(self.rowData.itemKey)
      local quantity = self.rowData.purchaseQuantity or 1
      if itemKeyInfo.isCommodity then
        
        if self.rowData.purchased then
          return
        end

        local cell = self.cells[5]

        local started = PurchaseCommodity(self, itemKeyInfo.itemID, quantity, self.rowData.minPrice, cell)
        
        if started then
          self.rowData.purchased = true
        end

        return
      end
    end

    Auctionator.EventBus
      :RegisterSource(self, "ShoppingResultsRowMixin")
      :Fire(self, Auctionator.Shopping.Tab.Events.ShowHistoricalPrices, self.rowData)
      :UnregisterSource(self)

  elseif IsShiftKeyDown() then
    Auctionator.EventBus
      :RegisterSource(self, "ShoppingResultsRowMixin")
      :Fire(self, Auctionator.Shopping.Tab.Events.UpdateSearchTerm, self.rowData.plainItemName)
      :UnregisterSource(self)
  else
    AuctionatorResultsRowTemplateMixin.OnClick(self, button, ...)

    if C_AuctionHouse.GetItemKeyInfo(self.rowData.itemKey) then
      local itemKeyInfo = C_AuctionHouse.GetItemKeyInfo(self.rowData.itemKey)
      if itemKeyInfo.isCommodity then
        Auctionator.EventBus
          :RegisterSource(self, "ShoppingResultsRowMixin")
          :Fire(self, Auctionator.Buying.Events.ShowCommodityBuy, self.rowData, itemKeyInfo)
          :UnregisterSource(self)
      else
        Auctionator.EventBus
          :RegisterSource(self, "ShoppingResultsRowMixin")
          :Fire(self, Auctionator.Buying.Events.ShowItemBuy, self.rowData, itemKeyInfo)
          :UnregisterSource(self)
      end
      Auctionator.EventBus
        :RegisterSource(self, "ShoppingResultsRowMixin")
        :Fire(self, Auctionator.Shopping.Tab.Events.BuyScreenShown)
        :UnregisterSource(self)
    end
  end
end
