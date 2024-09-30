AuctionatorShoppingResultsRowMixin = CreateFromMixins(AuctionatorResultsRowTemplateMixin)

local function debugtable(tab) 
  print("=====================================")
  print("SIZE:", #tab)
  print("{")
  if not tab then
    print("nil")
  else
    for k,v in pairs(tab) do
      print('"'..k..'" = '..tostring(v))
    end
  end
  print("}")
  print("=====================================")
end

local item = {}

function PurchaseCommodity(itemID, quantity)
	C_AuctionHouse.StartCommoditiesPurchase(itemID, quantity)
	item.itemID = itemID
	item.quantity = quantity
end

local function PurchaseCommodityOnEvent(self, event)
	if next(item) then
		C_AuctionHouse.ConfirmCommoditiesPurchase(item.itemID, item.quantity)
		wipe(item)
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("AUCTION_HOUSE_THROTTLED_SYSTEM_READY")
f:SetScript("OnEvent", PurchaseCommodityOnEvent)

function AuctionatorShoppingResultsRowMixin:OnClick(button, ...)
  Auctionator.Debug.Message("AuctionatorShoppingResultsRowMixin:OnClick()")

  if IsModifiedClick("DRESSUP") then
    AuctionHouseBrowseResultsFrameMixin.OnBrowseResultSelected({}, self.rowData)

  elseif button == "RightButton" then
    if C_AuctionHouse.GetItemKeyInfo(self.rowData.itemKey) then
      local itemKeyInfo = C_AuctionHouse.GetItemKeyInfo(self.rowData.itemKey)
      local quantity = self.rowData.purchaseQuantity or 1
      if itemKeyInfo.isCommodity then
        PurchaseCommodity(itemKeyInfo.itemID, quantity)
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
