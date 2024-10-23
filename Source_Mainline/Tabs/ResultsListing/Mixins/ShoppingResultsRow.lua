AuctionatorShoppingResultsRowMixin = CreateFromMixins(AuctionatorResultsRowTemplateMixin)

local purchasing = nil

function PurchaseCommodity(itemID, quantity, cell)
  if purchasing then
    return false
  end

  purchasing = {
    itemID = itemID,
    quantity = quantity,
    cell = cell
  }
  
  purchasing.cell.text:SetText("starting")
  C_AuctionHouse.StartCommoditiesPurchase(purchasing.itemID, purchasing.quantity)
  return true  
end

local function OnReadyToConfirmPurchaseEvent(self, event)
  if not purchasing then
    return
  end

  purchasing.cell.text:SetText("confirming")
	C_AuctionHouse.ConfirmCommoditiesPurchase(purchasing.itemID, purchasing.quantity)
end

local function OnPurchaseCompletedEvent()
  if not purchasing then
    return
  end
  
  purchasing.cell.text:SetText("purchased")

  purchasing = nil
end

local f = CreateFrame("Frame")
f:RegisterEvent("AUCTION_HOUSE_THROTTLED_SYSTEM_READY")
f:SetScript("OnEvent", OnReadyToConfirmPurchaseEvent)

local f2 = CreateFrame("Frame")
f2:RegisterEvent("AUCTION_HOUSE_PURCHASE_COMPLETED")
f2:SetScript("OnEvent", OnPurchaseCompletedEvent)



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

        local started = PurchaseCommodity(itemKeyInfo.itemID, quantity, cell)
        
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
