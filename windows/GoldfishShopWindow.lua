local GoldfishShopWindow = class("GoldfishShopWindow", import(".BaseWindow"))
local GoldfishShopItem = class("GoldfishShopItem", import("app.components.CopyComponent"))
local cjson = require("cjson")

function GoldfishShopItem:ctor(go, parent, index)
	self.parent_ = parent
	self.index_ = index

	GoldfishShopItem.super.ctor(self, go)
end

function GoldfishShopItem:initUI()
	local goTrans = self.go.transform
	self.itemRoot_ = goTrans:NodeByName("itemRoot").gameObject
	self.lockImg_ = goTrans:NodeByName("lockImg").gameObject
	self.selectImg_ = goTrans:NodeByName("selectImg").gameObject
	self.maskImg_ = goTrans:NodeByName("maskImg").gameObject
	self.buyBtn_ = goTrans:NodeByName("buyBtn").gameObject
	self.buyBtnLabel_ = goTrans:ComponentByName("buyBtn/label", typeof(UILabel))
	self.limitLabel_ = goTrans:ComponentByName("limitLabel", typeof(UILabel))
	UIEventListener.Get(self.buyBtn_).onClick = handler(self, self.onClickBuy)
end

function GoldfishShopItem:setInfo(params)
	dump(params, "params")

	self.id_ = params.id
	self.buyTimes_ = params.buy_times
	self.limit_time = params.limit_times
	self.awards_ = params.awards
	self.cost_ = params.cost
	self.isUnlock_ = params.is_unlock

	NGUITools.DestroyChildren(self.itemRoot_.transform)
	xyd.getItemIcon({
		notShowGetWayBtn = true,
		scale = 0.7962962962962963,
		show_has_num = true,
		uiRoot = self.itemRoot_,
		itemID = self.awards_[1],
		num = self.awards_[2],
		wndType = xyd.ItemTipsWndType.ACTIVITY,
		dragScrollView = self.parent_.scrollerView_
	})

	self.limitLabel_.text = __("BUY_GIFTBAG_LIMIT", self.limit_time - self.buyTimes_)
	self.buyBtnLabel_.text = self.cost_[2]

	if not self.isUnlock_ then
		self.maskImg_:SetActive(true)
		self.lockImg_:SetActive(true)
	else
		self.maskImg_:SetActive(false)
		self.lockImg_:SetActive(false)
	end

	if self.limit_time - self.buyTimes_ <= 0 then
		self.maskImg_:SetActive(true)
		self.selectImg_:SetActive(true)
	else
		self.selectImg_:SetActive(false)
	end
end

function GoldfishShopItem:onClickBuy()
	self.parent_:onClickItem(self.id_, self.limit_time - self.buyTimes_, self.index_)
end

function GoldfishShopWindow:ctor(name, params)
	GoldfishShopWindow.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_GOLDFISH)
	self.select_ = self.activityData:getStartSelect()
	self.shopItemList_ = {}
end

function GoldfishShopWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:updateItemNum()
	self:initDescLabel()
	self:register()

	self.effect_ = xyd.Spine.new(self.effectRoot_)

	self.effect_:setInfo("heermosi_pifu04", function ()
		self.effect_:play("idle", 0, 1)
	end)
end

function GoldfishShopWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.effectRoot_ = winTrans:NodeByName("effectRoot").gameObject
	self.contentLabel_ = winTrans:ComponentByName("tipsGroup/contentLabel", typeof(UILabel))
	self.btnTips_ = winTrans:NodeByName("tipsGroup/btnTips").gameObject
	self.awardsGroup_ = winTrans:NodeByName("awardsGroup").gameObject
	self.awardsGroupImg = self.awardsGroup_:ComponentByName("awardsGroupImg", typeof(UISprite))
	self.resItemNum_ = winTrans:ComponentByName("resItem/labelNum", typeof(UILabel))

	for i = 1, 4 do
		self["valueLabel" .. i] = winTrans:ComponentByName("awardsGroup/value" .. i, typeof(UILabel))
		self["tipsLabel" .. i] = winTrans:ComponentByName("awardsGroup/label" .. i, typeof(UILabel))
	end

	self.itemGroup_ = winTrans:ComponentByName("scrollView/itemGroup", typeof(UIGrid))
	self.itemContent_ = winTrans:NodeByName("itemContent").gameObject
	self.scrollerView_ = winTrans:ComponentByName("scrollView", typeof(UIScrollView))
end

function GoldfishShopWindow:updateItemNum()
	self.resItemNum_.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.GOLDFISH_ICON)
end

function GoldfishShopWindow:initDescLabel()
	local expectNum = xyd.tables.miscTable:split2Cost("activity_goldfish_expectation", "value", "|")
	local point = self.activityData:getPoint()
	local expectPoint = math.floor((expectNum[1]^point - 1) * expectNum[2] + expectNum[3] * point)
	local hisCoin = self.activityData:getHisCoin()
	self.contentLabel_.text = __("ACTIVITY_GOLDFISH_SHOP_TEXT01", expectPoint - hisCoin)

	if hisCoin < expectPoint then
		self.contentLabel_.text = __("ACTIVITY_GOLDFISH_SHOP_TEXT01", expectPoint - hisCoin)
	else
		self.contentLabel_.text = __("ACTIVITY_GOLDFISH_SHOP_TEXT02")
	end

	if xyd.Global.lang == "fr_fr" then
		self.contentLabel_.width = 290
	end

	local countTipsLabelMaxWidth = 0

	for i = 1, 4 do
		self["tipsLabel" .. i].text = __("ACTIVITY_GOLDFISH_SHOP_TEXT0" .. 3 + i)

		if countTipsLabelMaxWidth < self["tipsLabel" .. i].width then
			countTipsLabelMaxWidth = self["tipsLabel" .. i].width
		end
	end

	self.awardsGroupImg.width = countTipsLabelMaxWidth + 110
	self.valueLabel1.text = point
	self.valueLabel2.text = hisCoin
	self.valueLabel3.text = expectPoint
	self.valueLabel4.text = xyd.checkCondition(hisCoin < expectPoint, expectPoint - hisCoin, 0)
end

function GoldfishShopWindow:layout()
	local ids = xyd.tables.activityGoldfishShopTable:getIDsByLimitNum(self.select_)

	table.sort(ids)

	local awards = self.activityData.detail.awarded or {}

	for index, id in ipairs(ids) do
		local info = {
			id = id,
			buy_times = awards[id],
			limit_times = xyd.tables.activityGoldfishShopTable:getLimit(id),
			awards = xyd.tables.activityGoldfishShopTable:getAwards(id),
			cost = xyd.tables.activityGoldfishShopTable:getCost(id),
			is_unlock = self.activityData:checkUnlock(self.select_)
		}

		if not self.shopItemList_[index] then
			local newRoot = NGUITools.AddChild(self.itemGroup_.gameObject, self.itemContent_)

			newRoot:SetActive(true)

			self.shopItemList_[index] = GoldfishShopItem.new(newRoot, self, index)
		end

		self.shopItemList_[index]:setInfo(info)
	end

	for index, item in ipairs(self.shopItemList_) do
		item:SetActive(index <= #ids)
	end

	self.itemGroup_:Reposition()
	self.scrollerView_:ResetPosition()
end

function GoldfishShopWindow:register()
	UIEventListener.Get(self.btnTips_).onClick = handler(self, self.onClickTips)

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.updateItemNum))
end

function GoldfishShopWindow:onClickTips()
	if not self.showTips_ then
		self.showTips_ = true
	else
		self.showTips_ = false
	end

	self.awardsGroup_:SetActive(self.showTips_)
end

function GoldfishShopWindow:onClickItem(id, canTimes, index)
	if not self.activityData:checkUnlock(self.select_) then
		local limitNum = xyd.tables.activityGoldfishShopTable:getLimitNumByIndex(self.select_)

		xyd.alertTips(__("ACTIVITY_GOLDFISH_SHOP_TIPS01", limitNum))

		return
	end

	local cost = xyd.tables.activityGoldfishShopTable:getCost(id)

	if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))
	else
		local max_num = math.min(canTimes, math.floor(xyd.models.backpack:getItemNumByID(cost[1]) / cost[2]))
		local award = xyd.tables.activityGoldfishShopTable:getAwards(id)

		xyd.WindowManager.get():openWindow("item_buy_window", {
			hide_min_max = false,
			item_no_click = false,
			cost = cost,
			max_num = max_num,
			itemParams = {
				itemID = award[1],
				num = award[2]
			},
			buyCallback = function (num)
				if self.activityData:getEndTime() <= xyd.getServerTime() then
					xyd.alertTips(__("ACTIVITY_END_YET"))

					return
				end

				local params = cjson.encode({
					type_id = 2,
					award_id = id,
					award_num = num
				})
				self.tempItem = {
					item_id = id,
					award_num = num,
					index = index
				}

				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_GOLDFISH, params)
			end,
			maxCallback = function ()
				xyd.showToast(__("FULL_BUY_SLOT_TIME"))
			end
		})
	end
end

function GoldfishShopWindow:onGetAward(event)
	local data = xyd.decodeProtoBuf(event.data)
	local detail = cjson.decode(data.detail)

	if data.activity_id == xyd.ActivityID.ACTIVITY_GOLDFISH then
		local type_id = detail.type_id

		if type_id == 2 and self.tempItem and self.tempItem.item_id then
			local id = self.tempItem.item_id
			local index = self.tempItem.index
			local award = xyd.tables.activityGoldfishShopTable:getAwards(id)

			if xyd.tables.itemTable:getType(award[1]) == xyd.ItemType.SKIN then
				xyd.onGetNewPartnersOrSkins({
					destory_res = false,
					skins = {
						award[1]
					}
				})
			else
				xyd.alertItems({
					{
						item_id = award[1],
						item_num = award[2] * self.tempItem.award_num
					}
				})
			end

			self.tempItem = nil
			local awards = self.activityData.detail.awarded or {}
			local info = {
				id = id,
				buy_times = awards[id],
				limit_times = xyd.tables.activityGoldfishShopTable:getLimit(id),
				awards = xyd.tables.activityGoldfishShopTable:getAwards(id),
				cost = xyd.tables.activityGoldfishShopTable:getCost(id),
				is_unlock = self.activityData:checkUnlock(self.select_)
			}

			dump(info, "info")
			print("index   ", index)

			if self.shopItemList_[index] then
				self.shopItemList_[index]:setInfo(info)
			end
		end
	end
end

return GoldfishShopWindow
