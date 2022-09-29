local ActivityContent = import(".ActivityContent")
local ActivityGoldfish = class("ActivityGoldfish", ActivityContent)
local ActivityGoldfishItem = class("ActivityGoldfishItem", import("app.components.CopyComponent"))
local cjson = require("cjson")

function ActivityGoldfishItem:ctor(go, parent, type, index)
	self.parent_ = parent
	self.type_ = type
	self.index_ = index

	ActivityGoldfishItem.super.ctor(self, go)
end

function ActivityGoldfishItem:initUI()
	self:getUIComponent()
	self:addParentDepth()
	self:updateUI()
end

function ActivityGoldfishItem:getUIComponent()
	local goTrans = self.go.transform
	self.bgImg_ = goTrans:ComponentByName("bgImg", typeof(UISprite))
	self.itemIcon_ = goTrans:ComponentByName("itemIcon", typeof(UISprite))
	self.itemLabel_ = goTrans:ComponentByName("itemNum", typeof(UILabel))
	self.effect1Root_ = goTrans:NodeByName("effect1").gameObject
	self.effect2Root_ = goTrans:NodeByName("effect2").gameObject
end

function ActivityGoldfishItem:updateUI()
	if not self.effect1_ then
		self.effect1_ = xyd.Spine.new(self.effect1Root_)

		self.effect1_:setInfo("activity_goldfish_award", function ()
			if self.type_ == "special" then
				self.effect1_:play("idle02", 0, 1)
			else
				self.effect1_:play("idle01", 0, 1)
			end
		end)
	end

	local function checkIconFun(id)
		self.itemIcon_.height = 64
		self.itemIcon_.width = 64
		local isSpread = xyd.tables.activityGoldfishTable:getIsSpread(id)

		if isSpread and isSpread == 1 then
			self.itemIcon_.height = 70
			self.itemIcon_.width = 70
			self.itemIcon_.transform.localPosition = Vector3(0, -0.7, 0)
		end
	end

	if self.type_ == "special" then
		xyd.setUISpriteAsync(self.bgImg_, nil, "goldfish_item_bg1")

		if self.index_ == 1 then
			local award = xyd.tables.activityGoldfishTable:getAwards(self.index_ + 8)
			self.itemIcon_.transform.localPosition = Vector3(0, 0, 0)
			local icon = xyd.tables.itemTable:getIcon(award[1])

			xyd.setUISpriteAsync(self.itemIcon_, nil, icon, function ()
				checkIconFun(self.index_ + 8)
			end)
			self.itemLabel_.gameObject:SetActive(true)

			self.itemLabel_.text = xyd.getRoughDisplayNumber(award[2])

			UIEventListener.Get(self.go).onClick = function ()
				xyd.WindowManager.get():openWindow("item_tips_window", {
					notShowGetWayBtn = true,
					show_has_num = true,
					itemID = award[1],
					wndType = xyd.ItemTipsWndType.ACTIVITY
				})
			end

			return
		end

		self.itemIcon_.transform.localPosition = Vector3(4, -2, 0)

		xyd.setUISpriteAsync(self.itemIcon_, nil, "goldfish_gold_icon" .. self.index_ - 1, function ()
			checkIconFun(self.index_ - 1)
		end)
		self.itemLabel_.gameObject:SetActive(false)

		self.itemLabel_.color = Color.New2(4294491903.0)
		self.itemLabel_.effectStyle = UILabel.Effect.None
	else
		xyd.setUISpriteAsync(self.bgImg_, nil, "goldfish_item_bg2")

		self.itemLabel_.color = Color.New2(4294967039.0)
		self.itemLabel_.effectStyle = UILabel.Effect.Outline8
		local award = xyd.tables.activityGoldfishTable:getAwards(self.index_)
		local icon = xyd.tables.itemTable:getIcon(award[1])
		self.itemIcon_.transform.localPosition = Vector3(0, 0, 0)

		xyd.setUISpriteAsync(self.itemIcon_, nil, icon, function ()
			checkIconFun(self.index_)
		end)
		self.itemLabel_.gameObject:SetActive(true)

		self.itemLabel_.text = xyd.getRoughDisplayNumber(award[2])

		UIEventListener.Get(self.go).onClick = function ()
			xyd.WindowManager.get():openWindow("item_tips_window", {
				notShowGetWayBtn = true,
				show_has_num = true,
				itemID = award[1],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})
		end
	end
end

function ActivityGoldfishItem:playAwardAni(callback)
	self.effect2Root_:SetActive(true)

	if not self.effect2_ then
		self.effect2_ = xyd.Spine.new(self.effect2Root_)

		self.effect2_:setInfo("activity_goldfish_award", function ()
			self.effect2_:play("get", 1, 1, function ()
				self.effect2Root_:SetActive(false)

				if callback then
					callback()
				end
			end)
		end)
	else
		self.effect2_:play("get", 1, 1, function ()
			self.effect2Root_:SetActive(false)

			if callback then
				callback()
			end
		end)
	end
end

function ActivityGoldfish:ctor(parentGO, params, parent)
	self.itemList_ = {}

	ActivityGoldfish.super.ctor(self, parentGO, params, parent)
	dump(self.activityData.detail)
end

function ActivityGoldfish:getPrefabPath()
	return "Prefabs/Windows/activity/activity_goldfish"
end

function ActivityGoldfish:initUI()
	self:getUIComponent()
	self:layout()
	self:updateItemNum()
	self:register()
end

function ActivityGoldfish:getUIComponent()
	local goTrans = self.go.transform
	self.logoImg_ = goTrans:ComponentByName("logoImg", typeof(UISprite))
	self.helpBtn_ = goTrans:NodeByName("helpBtn").gameObject
	self.shopBtn_ = goTrans:NodeByName("shopBtn").gameObject
	self.detailBtn_ = goTrans:NodeByName("detailBtn").gameObject
	self.resItem_ = goTrans:NodeByName("resItem").gameObject
	self.resItemNum_ = goTrans:ComponentByName("resItem/num", typeof(UILabel))
	self.goldResLable_ = goTrans:ComponentByName("goldRes/label", typeof(UILabel))
	self.summonBtn1_ = goTrans:NodeByName("summonBtn1").gameObject
	self.summonBtn1Label_ = goTrans:ComponentByName("summonBtn1/label", typeof(UILabel))
	self.summonBtn1Red_ = goTrans:NodeByName("summonBtn1/redPoint").gameObject
	self.summonBtn10_ = goTrans:NodeByName("summonBtn10").gameObject
	self.summonBtn10Label_ = goTrans:ComponentByName("summonBtn10/label", typeof(UILabel))
	self.summonBtn10Red_ = goTrans:NodeByName("summonBtn10/redPoint").gameObject
	self.lableTips2_ = goTrans:ComponentByName("lableTips2", typeof(UILabel))
	self.fishItem_ = goTrans:NodeByName("fishItem").gameObject
	self.content_ = goTrans:NodeByName("content")
	self.labelTips_ = self.content_:ComponentByName("tipsGroup/labelTips", typeof(UILabel))
	self.lableTips1_ = self.content_:ComponentByName("lableTips1", typeof(UILabel))
	self.goldNum_ = self.content_:ComponentByName("goldNum", typeof(UILabel))
	self.goldEffectRoot_ = self.content_:NodeByName("goldEffect").gameObject

	for i = 1, 8 do
		local itemRoot = self.content_:NodeByName("itemGroup/item" .. i).gameObject
		local newRoot = NGUITools.AddChild(itemRoot, self.fishItem_)
		self.itemList_[i] = ActivityGoldfishItem.new(newRoot, self, "normal", i)
	end

	for i = 1, 4 do
		local itemRoot = self.content_:NodeByName("itemGroup/specialItem" .. i).gameObject
		local newRoot = NGUITools.AddChild(itemRoot, self.fishItem_)
		self.itemList_[i + 8] = ActivityGoldfishItem.new(newRoot, self, "special", i)
	end

	self:resizePosY(self.logoImg_.transform, 45, 0)
	self:resizePosY(self.content_.transform, -495, -585)
	self:resizePosY(self.summonBtn1_.transform, -804, -940)
	self:resizePosY(self.summonBtn10_.transform, -804, -940)
	self:resizePosY(self.lableTips2_.transform, -847, -990)
end

function ActivityGoldfish:layout()
	xyd.setUISpriteAsync(self.logoImg_, nil, "goldfish_logo_" .. xyd.Global.lang)

	if not self.goldEffect_ then
		self.goldEffect_ = xyd.Spine.new(self.goldEffectRoot_)

		self.goldEffect_:setInfo("activity_goldfish_coin", function ()
			self.goldEffect_:play("idle", 0, 1)
		end)
	end

	self.summonBtn1Label_.text = __("ACTIVITY_GOLDFISH_BUTTON01")
	self.summonBtn10Label_.text = __("ACTIVITY_GOLDFISH_BUTTON02")
	self.lableTips1_.text = __("ACTIVITY_GOLDFISH_TEXT04")
	self.lableTips2_.text = __("ACTIVITY_GOLDFISH_TEXT03")
end

function ActivityGoldfish:updateItemNum()
	local itemNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.GOLDFISH_NET)
	self.resItemNum_.text = itemNum
	self.goldResLable_.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.GOLDFISH_ICON)

	self.summonBtn1Red_:SetActive(itemNum >= 1)
	self.summonBtn10Red_:SetActive(itemNum >= 10)

	self.goldNum_.text = self.activityData:getCoin()
	local expectNum = xyd.tables.miscTable:split2Cost("activity_goldfish_expectation", "value", "|")
	local point = self.activityData:getPoint()
	local expectPoint = math.floor((expectNum[1]^point - 1) * expectNum[2] + expectNum[3] * point)
	local hisCoin = self.activityData:getHisCoin()

	if point <= 0 then
		self.labelTips_.text = __("ACTIVITY_GOLDFISH_TEXT07")
	elseif hisCoin < expectPoint then
		self.labelTips_.text = __("ACTIVITY_GOLDFISH_TEXT01", point, expectPoint, hisCoin, expectPoint - hisCoin)
	else
		self.labelTips_.text = __("ACTIVITY_GOLDFISH_TEXT02", point, expectPoint, hisCoin)
	end

	if xyd.Global.lang == "fr_fr" then
		self.labelTips_.height = 112
	elseif xyd.Global.lang == "en_en" then
		self.labelTips_.fontSize = 19
	end
end

function ActivityGoldfish:register()
	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_GOLDFISH_HELP"
		})
	end

	UIEventListener.Get(self.detailBtn_).onClick = function ()
		local params = {
			windowTpye = 3
		}

		xyd.WindowManager:get():openWindow("activity_halloween_trick_preview_window", params)
	end

	UIEventListener.Get(self.shopBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_goldfish_shop_window", {})
	end

	UIEventListener.Get(self.summonBtn1_).onClick = function ()
		self:summon(1)
	end

	UIEventListener.Get(self.summonBtn10_).onClick = function ()
		self:summon(10)
	end

	UIEventListener.Get(self.resItem_).onClick = function ()
		xyd.WindowManager.get():openWindow("item_tips_window", {
			show_has_num = true,
			itemID = xyd.ItemID.GOLDFISH_NET,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.updateItemNum))
end

function ActivityGoldfish:summon(num)
	if self.isReqing_ then
		return
	end

	local end_time = self.activityData:getEndTime()

	if end_time - xyd.getServerTime() <= xyd.DAY_TIME then
		xyd.alertTips(__("ACTIVITY_GOLDFISH_TEXT06"))

		return
	end

	if xyd.models.backpack:getItemNumByID(xyd.ItemID.GOLDFISH_NET) < num then
		local name = xyd.tables.itemTable:getName(xyd.ItemID.GOLDFISH_NET)

		xyd.alertTips(__("NOT_ENOUGH", name))

		return
	end

	local info = {
		type_id = 1,
		times = num
	}
	local params = cjson.encode(info)
	self.isReqing_ = true

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_GOLDFISH, params)
end

function ActivityGoldfish:onGetAward(event)
	local data = xyd.decodeProtoBuf(event.data)
	local detail = cjson.decode(data.detail)

	if data.activity_id == xyd.ActivityID.ACTIVITY_GOLDFISH then
		local type_id = detail.type_id

		if type_id == 1 then
			local params = {
				btnLabelText = __("ACTIVITY_GOLDFISH_BUTTON01"),
				btnLabelText2 = __("ACTIVITY_GOLDFISH_BUTTON02"),
				cost = {
					xyd.ItemID.FISHING_NET,
					1
				},
				cost2 = {
					xyd.ItemID.FISHING_NET,
					10
				},
				wnd_type = 4,
				data = {},
				buyCallback = function (_, _, is_cost2)
					if is_cost2 then
						self:summon(10)
					else
						self:summon(1)
					end
				end
			}
			local itemInfo = detail.res
			local hasCoin = false

			for _, item in ipairs(itemInfo) do
				table.insert(params.data, {
					item_id = item.item_id,
					item_num = item.item_num,
					cool = xyd.checkCondition(item.id >= 9, 1, 0),
					changeItem = xyd.checkCondition(item.id > 9, 398 + item.id - 9, nil)
				})

				if item.id >= 10 then
					hasCoin = true
				end
			end

			local resInfo = detail.res
			local startItem = resInfo[1]
			local startIndex = startItem.id

			if self.itemList_[startIndex] then
				self.itemList_[startIndex]:playAwardAni(function ()
					if hasCoin then
						self.goldEffect_:play("reduce", 1, 1, function ()
							self.goldEffect_:play("idle", 0, 1)

							self.isReqing_ = false

							xyd.WindowManager.get():openWindow("gamble_rewards_window", params)
						end)
					else
						self.goldEffect_:play("add", 1, 1, function ()
							self.goldEffect_:play("idle", 0, 1)

							self.isReqing_ = false

							xyd.WindowManager.get():openWindow("gamble_rewards_window", params)
						end)
					end
				end)
			end
		end
	end

	self:updateItemNum()
end

return ActivityGoldfish
