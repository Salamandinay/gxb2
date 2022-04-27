local ChoosePartnerDebrisWindow = class("ChoosePartnerDebrisWindow", import(".BaseWindow"))
local BackpackItem = import(".BackpackWindow"):getBackpackItemClass()

function ChoosePartnerDebrisWindow:ctor(name, params)
	ChoosePartnerDebrisWindow.super.ctor(self, name, params)

	self.params_ = params
	self.mTableID_ = self.params_.mTableID
	self.mTableIDList_ = self.params_.mTableIDList
	self.clickId_ = self.params_.clickId
	self.closeCallBack = self.params_.closeCallback
	self.collectionBefore_ = xyd.models.slot:getCollection()
end

function ChoosePartnerDebrisWindow:excuteCallBack(isCloseAll)
	if not isCloseAll and self.params_ and self.closeCallBack then
		self.closeCallBack()
	end
end

function ChoosePartnerDebrisWindow:initWindow()
	ChoosePartnerDebrisWindow.super.initWindow(self)
	self:getComponent()
	self:initDebris()
	self:registerEvent()

	self.winTtile_.text = __("CHOOSE_PARTNER_DEBRIS_WINDOW")
end

function ChoosePartnerDebrisWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.winTtile_ = winTrans:ComponentByName("title", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("backBtn").gameObject
	self.debrisScroller_ = winTrans:ComponentByName("debrisScroller", typeof(UIScrollView))
	self.grid_ = winTrans:ComponentByName("debrisScroller/wrapContent", typeof(MultiRowWrapContent))
	local itemCell = winTrans:NodeByName("item").gameObject
	self.multiWrapDebris_ = require("app.common.ui.FixedMultiWrapContent").new(self.debrisScroller_, self.grid_, itemCell, BackpackItem, self)
end

function ChoosePartnerDebrisWindow:initDebris()
	local debrisDatas = xyd.models.backpack:getCanComposeDebris()
	local itemList = {}

	if self.params_.isShelter then
		itemList = self:shelterDebrisFilter(debrisDatas)
	else
		local mTableIDList = {}

		if self.mTableIDList_ then
			mTableIDList = self.mTableIDList_
		else
			mTableIDList = {
				self.mTableID_
			}
		end

		for _, mTableID in ipairs(mTableIDList) do
			if tonumber(mTableID) % 1000 == 999 then
				local group = math.floor(tonumber(mTableID) % 10000 / 1000)
				local star = math.floor(tonumber(mTableID) / 10000)

				if star < 6 then
					if debrisDatas and debrisDatas[group] and debrisDatas[group][star] then
						itemList = debrisDatas[group][star]
					end
				elseif star == 6 then
					if debrisDatas and debrisDatas[group] and debrisDatas[group][6] then
						local tList = debrisDatas[group][6]

						for _, item in ipairs(tList) do
							if xyd.DogFood_Six[item.itemID] then
								table.insert(itemList, item)
							end
						end
					end
				else
					local select = nil

					if star == 9 then
						select = xyd.DogFood_Nine
					else
						select = xyd.DogFood_Ten
					end

					if debrisDatas then
						for _, list in pairs(debrisDatas) do
							local tList = list[6] or {}

							for _, item in ipairs(tList) do
								if select[item.itemID] then
									table.insert(itemList, item)
								end
							end
						end
					end
				end
			else
				local itemID = xyd.tables.partnerTable:getPartnerShard(mTableID)
				local itemNum = xyd.models.backpack:getItemNumByID(itemID)
				local cost = xyd.tables.itemTable:partnerCost(itemID)

				if cost[2] <= itemNum then
					table.insert(itemList, {
						itemID = itemID,
						itemNum = itemNum
					})
				end
			end
		end
	end

	self.itemList_ = itemList

	self.multiWrapDebris_:setInfos(self.itemList_, {})
end

function ChoosePartnerDebrisWindow:shelterDebrisFilter(debrisDatas)
	local debrisList = {}
	local job = xyd.tables.partnerIDRuleTable:getJob(self.mTableID_)
	local group = xyd.tables.partnerIDRuleTable:getGroup(self.mTableID_)
	local star = xyd.tables.partnerIDRuleTable:getStar(self.mTableID_)

	if debrisDatas ~= nil and debrisDatas[group] ~= nil and debrisDatas[group][star] ~= nil then
		debrisList = debrisDatas[group][star]
	end

	if job == 0 then
		return debrisList
	end

	local resList = {}

	for i = 1, #debrisList do
		local debrisId = debrisList[i].itemID
		local partnerCost = xyd.tables.itemTable:partnerCost(debrisId)
		local partnerId = partnerCost[1]
		local partnerJob = xyd.tables.partnerTable:getJob(partnerId)

		if job == partnerJob then
			table.insert(resList, debrisList[i])
		end
	end

	return resList
end

function ChoosePartnerDebrisWindow:registerEvent()
	ChoosePartnerDebrisWindow.super.register(self)

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
	self.eventProxy_:addEventListener(xyd.event.SUMMON, handler(self, self.summonCallback))
end

function ChoosePartnerDebrisWindow:onItemChange()
	self:initDebris()
end

function ChoosePartnerDebrisWindow:summonCallback(event)
	self.collectionBefore_ = xyd.models.slot:getCollection()
	local items = event.data.summon_result.items
	local partners = event.data.summon_result.partners
	local params = {}
	local flag = false
	local itemID_ = 0
	local callback = nil
	local hasFive = false

	local function checkMore(itemID)
		if itemID_ ~= 0 and itemID_ ~= itemID then
			flag = true
		else
			itemID_ = itemID
		end
	end

	if #items > 0 then
		for i, _ in ipairs(items) do
			table.insert(params, items[i])
			checkMore(items[i].item_id)
		end
	end

	local new5stars = {}
	local res_partners = {}

	if #partners > 0 then
		local summonCost = xyd.tables.summonTable:getCost(event.data.summon_id)
		local summonItemID = summonCost[1]

		if xyd.tables.itemTable:getType(summonItemID) == xyd.ItemType.HERO_RANDOM_DEBRIS and xyd.tables.itemTable:getQuality(summonItemID) == xyd.QualityColor.RED then
			new5stars = xyd.isHasNew5Stars(event, self.collectionBefore)
		end

		for i, _ in ipairs(partners) do
			local star = xyd.tables.partnerTable:getStar(partners[i].table_id) + partners[i].awake

			table.insert(params, {
				item_num = 1,
				noWays = true,
				item_id = partners[i].table_id,
				star = star
			})
			table.insert(res_partners, partners[i].table_id)
			checkMore(partners[i].table_id)

			if not hasFive then
				local star = xyd.tables.partnerTable:getStar(partners[i].table_id)

				if star > 5 then
					hasFive = true
				end
			end
		end
	end

	if hasFive then
		function callback()
			xyd.EventDispatcher.inner():dispatchEvent({
				name = xyd.event.HIGH_PRAISE
			})
		end
	end

	local function effectCallBack()
		self.collectionBefore_ = xyd.models.slot:getCollection()

		if flag then
			xyd.WindowManager.get():openWindow("alert_heros_window", {
				data = params,
				callback = callback
			})
		else
			local tmpData = {}
			local starData = {}
			local noWaysData = {}

			for _, item in ipairs(params) do
				local itemID = item.item_id

				if tmpData[itemID] == nil then
					tmpData[itemID] = 0
				end

				starData[itemID] = item.star
				noWaysData[itemID] = item.noWays
				tmpData[itemID] = tmpData[item.item_id] + item.item_num
			end

			local datas = {}

			for k, v in pairs(tmpData) do
				table.insert(datas, {
					item_id = tonumber(k),
					item_num = v,
					star = starData[k],
					noWays = noWaysData[k]
				})
			end

			if #datas == 1 then
				xyd.WindowManager.get():openWindow("alert_award_window", {
					items = datas,
					callback = callback,
					title = __("SUMMON")
				})
			else
				xyd.WindowManager.get():openWindow("alert_item_window", {
					items = datas,
					callback = callback,
					title = __("SUMMON")
				})
			end
		end
	end

	if xyd.GuideController.get():isGuideComplete() then
		xyd.onGetNewPartnersOrSkins({
			destory_res = true,
			partners = res_partners,
			callback = effectCallBack
		}, self.collectionBefore_)
	else
		effectCallBack()
	end
end

function ChoosePartnerDebrisWindow:willClose()
	ChoosePartnerDebrisWindow.super.willClose(self)

	if self.isCloseAll then
		return
	end
end

return ChoosePartnerDebrisWindow
