local ActivityContent = import(".ActivityContent")
local QiXiGiftBag = class("QiXiGiftBag", ActivityContent)
local QiXiGiftBagItem = class("QiXiGiftBagItem", import("app.components.BaseComponent"))
local json = require("cjson")

function QiXiGiftBag:ctor(go, params)
	self.itemList = {}
	self.choose_queue = {}

	ActivityContent.ctor(self, go, params)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
end

function QiXiGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/qi_xi_gift_bag"
end

function QiXiGiftBag:initUI()
	QiXiGiftBag.super.initUI(self)
	self:getUIComponent()
	self:setText()
	self:setItem()

	local duration = self.activityData:getUpdateTime() - xyd.getServerTime()

	if duration > 0 then
		self.timeLabel.gameObject:SetActive(true)
		self.endLabel.gameObject:SetActive(true)

		self.timeCount_ = import("app.components.CountDown").new(self.timeLabel)

		self.timeCount_:setInfo({
			duration = duration
		})
	else
		self.timeLabel.gameObject:SetActive(false)
		self.endLabel.gameObject:SetActive(false)
	end

	xyd.setUITextureAsync(self.textImg, "Textures/activity_text_web/qixi_gift_bag_text01_" .. xyd.Global.lang)

	if xyd.Global.lang == "en_en" then
		self.timeLabel:Y(-200)
		self.endLabel:Y(-200)
	elseif xyd.Global.lang == "de_de" then
		self.timeLabel:SetLocalPosition(60, -200, 0)
		self.endLabel:SetLocalPosition(175, -200, 0)

		self.timeLabel.fontSize = 20
		self.endLabel.fontSize = 20
	elseif xyd.Global.lang == "ko_kr" then
		self.labelText.height = 90

		self.labelText:Y(-237)
	end
end

function QiXiGiftBag:getUIComponent()
	local activityGroup = self.go:NodeByName("activityGroup").gameObject
	self.textImg = activityGroup:ComponentByName("textImg", typeof(UITexture))
	self.imgBg1 = activityGroup:ComponentByName("imgBg1", typeof(UISprite))
	self.labelText = activityGroup:ComponentByName("labelText", typeof(UILabel))
	self.timeLabel = activityGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = activityGroup:ComponentByName("endLabel", typeof(UILabel))
	self.scroller = activityGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.groupItems = activityGroup:ComponentByName("scroller/groupItems", typeof(UIGrid))
end

function QiXiGiftBag:setText()
	self.endLabel.text = __("END_TEXT")
	self.labelText.text = __("QIXI_TEXT01")
end

function QiXiGiftBag:setItem()
	local gTable = xyd.tables.activityGiftBoxTable
	local ids = xyd.tables.activityGiftBoxTable:getIDs()

	for i = 1, #ids do
		local id = ids[i]
		local cost = gTable:getCost(id)
		local params = {
			id = id,
			cur_cnt = self.activityData.detail.buy_times[tonumber(id)],
			limit = gTable:getLimit(id),
			cost_type = cost[1],
			cost_cnt = cost[2],
			awards = gTable:getAwards(id),
			win = self
		}
		local item = QiXiGiftBagItem.new(self.groupItems.gameObject, params)

		item:setDragScrollView(self.scroller)
		table.insert(self.itemList, item)
	end
end

function QiXiGiftBag:setItemCnt(id, val)
	self.itemList[tonumber(id)]:setBuyCount(val)
end

function QiXiGiftBag:onAward(event)
	while #self.choose_queue > 0 do
		local id = self.choose_queue[1]

		table.remove(self.choose_queue, 1)
		self:setItemCnt(id, self.activityData.detail.buy_times[tonumber(id)])

		local items = xyd.tables.activityGiftBoxTable:getAwards(id)
		local item_data = {}
		local skins = {}

		for i = 1, #items do
			local data = items[i]

			table.insert(item_data, {
				item_id = data[1],
				item_num = data[2]
			})

			if xyd.tables.itemTable:getType(data[1]) == xyd.ItemType.SKIN then
				table.insert(skins, data[1])
			end
		end

		if #skins > 0 then
			xyd.onGetNewPartnersOrSkins({
				destory_res = false,
				skins = skins,
				callback = function ()
					self:itemFloat(item_data)
				end
			})
		else
			self:itemFloat(item_data)
		end
	end
end

function QiXiGiftBag:setCurChoose(id)
	table.insert(self.choose_queue, id)
	self.activityData:setChoose(tonumber(id))
end

function QiXiGiftBagItem:ctor(parentGo, params)
	self.id = params.id
	self.cur_cnt = params.cur_cnt
	self.limit = params.limit
	self.cost_type = params.cost_type
	self.cost_cnt = params.cost_cnt
	self.awards = params.awards
	self.imgSource = params.imgSource
	self.noTouch = params.noTouch
	self.callback = params.callback
	self.win = params.win

	QiXiGiftBagItem.super.ctor(self, parentGo)
end

function QiXiGiftBagItem:getPrefabPath()
	return "Prefabs/Components/qi_xi_gift_bag_item"
end

function QiXiGiftBagItem:initUI()
	QiXiGiftBagItem.super.initUI(self)
	self:getUIComponent()
	self:setBuyCount(self.cur_cnt)

	self.nameLabel.text = xyd.tables.activityGiftBoxTextTable:getName(self.id)
	self.button_label.text = tostring(self.cost_cnt)

	xyd.setUISpriteAsync(self.imgBag, nil, "chunyou_gift_bag_icon_" .. tostring(self.id))
	self:initItems()
end

function QiXiGiftBagItem:getUIComponent()
	local go = self.go.transform
	self.nameLabel = go:ComponentByName("nameLabel", typeof(UILabel))
	self.limitLabel = go:ComponentByName("limitLabel", typeof(UILabel))
	self.purchaseBtn = go:NodeByName("purchaseBtn").gameObject
	self.button_label = self.purchaseBtn:ComponentByName("button_label", typeof(UILabel))
	self.btnBg = self.purchaseBtn:ComponentByName("img", typeof(UISprite))
	self.itemIcon = go:NodeByName("itemIcon").gameObject
	self.imgBag = self.itemIcon:ComponentByName("imgBag", typeof(UISprite))
	self.itemCon = go:NodeByName("itemCon").gameObject
	self.itemCon_UILayout = go:ComponentByName("itemCon", typeof(UILayout))
end

function QiXiGiftBagItem:onRegister()
	UIEventListener.Get(self.itemIcon).onClick = function ()
		self:onClickIcon()
	end

	UIEventListener.Get(self.purchaseBtn).onClick = function ()
		self:onClickBtn()
	end
end

function QiXiGiftBagItem:setBuyCount(buy_times)
	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", self.limit - buy_times)
	self.cur_cnt = buy_times

	self:checkStatus()
end

function QiXiGiftBagItem:checkStatus()
	if self.cur_cnt >= self.limit then
		xyd.applyGrey(self.purchaseBtn:GetComponent(typeof(UISprite)))
		self.button_label:ApplyGrey()
		xyd.applyGrey(self.btnBg)
		xyd.setTouchEnable(self.purchaseBtn, false)
	end
end

function QiXiGiftBagItem:onClickBtn()
	local cur_cnt = xyd.models.backpack:getItemNumByID(self.cost_type)

	if self.cost_cnt <= cur_cnt then
		xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_BUY"), function (yes)
			if yes then
				local data = json.encode({
					award_id = tonumber(self.id)
				})

				self.win:setCurChoose(self.id)
				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.QIXI_GIFTBAG, data)
			end
		end)
	else
		xyd.alert(xyd.AlertType.YES_NO, __("CRYSTAL_NOT_ENOUGH"), function (yes)
			if yes then
				xyd.WindowManager.get():openWindow("vip_window")
			end
		end)
	end
end

function QiXiGiftBagItem:onClickIcon()
	if self.callback then
		self.callback()

		return
	end

	xyd.WindowManager:get():openWindow("activity_award_preview_window", {
		awards = self.awards
	})
end

function QiXiGiftBagItem:initItems()
	for i = 1, #self.awards do
		local data = self.awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			local item = {
				show_has_num = true,
				notShowGetWayBtn = true,
				isShowSelected = false,
				itemID = data[1],
				num = data[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				uiRoot = self.itemCon,
				isNew = xyd.checkCondition(data[1] == 7203, true, false)
			}
			local icon = xyd.getItemIcon(item)

			icon:setScale(76 / xyd.DEFAULT_ITEM_SIZE)
			icon:AddUIDragScrollView()
		end
	end

	self.itemCon:GetComponent(typeof(UILayout)):Reposition()
end

return QiXiGiftBag
