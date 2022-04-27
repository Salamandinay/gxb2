local ActivitySpaceExploreTeam = class("ActivitySpaceExploreTeam", import(".ActivityContent"))
local myTable = xyd.tables.activitySpaceExplorePartnerTable
local cjson = require("cjson")

function ActivitySpaceExploreTeam:ctor(parentGo, params, parent)
	ActivitySpaceExploreTeam.super.ctor(self, parentGo, params, parent)
end

function ActivitySpaceExploreTeam:getPrefabPath()
	return "Prefabs/Windows/activity/activity_space_explore_team"
end

function ActivitySpaceExploreTeam:initUI()
	self:getUIComponent()
	ActivitySpaceExploreTeam.super.initUI(self)
	self:layout()
	self:register()
end

function ActivitySpaceExploreTeam:getUIComponent()
	local go = self.go
	self.textLogo = go:ComponentByName("textLogo", typeof(UISprite))
	self.labelDesc = go:ComponentByName("labelDesc", typeof(UILabel))
	self.labelTime = go:ComponentByName("timeGroup/labelTime", typeof(UILabel))
	self.labelEnd = go:ComponentByName("timeGroup/labelEnd", typeof(UILabel))
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	self.groupMain = go:NodeByName("groupMain").gameObject
	self.labelGet = self.groupMain:ComponentByName("labelGet", typeof(UILabel))
	self.labelNum = self.groupMain:ComponentByName("resGroup/labelNum", typeof(UILabel))
	self.addBtn = self.groupMain:NodeByName("resGroup/addBtn").gameObject
	self.scroller = self.groupMain:ComponentByName("scroller", typeof(UIScrollView))
	self.groupContent = self.scroller:NodeByName("groupContent").gameObject
	self.SSRlist = self.groupContent:NodeByName("groupSSR/SSRlist").gameObject
	self.SRlist = self.groupContent:NodeByName("groupSR/SRlist").gameObject
	self.Rlist = self.groupContent:NodeByName("groupR/Rlist").gameObject
	self.jumpBtn = self.groupMain:NodeByName("jumpBtn").gameObject
	self.summonOne = self.groupMain:NodeByName("summon_one").gameObject
	self.labelItemDisplayOne = self.summonOne:ComponentByName("labelItemDisplay", typeof(UILabel))
	self.labelItemCostOne = self.summonOne:ComponentByName("labelItemCost", typeof(UILabel))
	self.summonTen = self.groupMain:NodeByName("summon_ten").gameObject
	self.labelItemDisplayTen = self.summonTen:ComponentByName("labelItemDisplay", typeof(UILabel))
	self.labelItemCostTen = self.summonTen:ComponentByName("labelItemCost", typeof(UILabel))

	self.jumpBtn:SetActive(false)
end

function ActivitySpaceExploreTeam:layout()
	xyd.setUISpriteAsync(self.textLogo, nil, "activity_space_explore_team_" .. xyd.Global.lang)

	self.labelDesc.text = __("SPACE_EXPLORE_TEAM_TEXT01")

	if xyd.Global.lang == "fr_fr" then
		self.labelDesc.width = 345
		self.labelDesc.spacingY = 5

		self.labelDesc:Y(-220)
	elseif xyd.Global.lang == "de_de" then
		self.labelDesc.width = 390

		self.labelDesc:X(160)

		self.labelDesc.fontSize = 20
		self.labelItemDisplayOne.fontSize = 18
		self.labelItemDisplayTen.fontSize = 18
	end

	self.labelEnd.text = __("END")
	local duration = self.activityData:getEndTime() - xyd.getServerTime()

	if duration < 0 then
		self.labelTime:SetActive(false)
		self.labelEnd:SetActive(false)
	else
		local timeCount = import("app.components.CountDown").new(self.labelTime)

		timeCount:setInfo({
			function ()
				xyd.WindowManager.get():closeWindow("activity_window")
			end,
			duration = duration
		})
	end

	self.guaranteeTimes = tonumber(xyd.tables.miscTable:getVal("space_explore_gacha_guarantee"))

	self:setGetLabel()
	self:setCoinsResNum()

	self.labelItemDisplayOne.text = __("SUMMON_X_TIME2", 1)
	self.labelItemDisplayTen.text = __("SUMMON_X_TIME2", 10)
	self.labelItemCostOne.text = "1"
	self.labelItemCostTen.text = "10"
	self.itemList = {}

	self:initContent()
	self:waitForFrame(1, function ()
		self.groupContent:GetComponent(typeof(UILayout)):Reposition()
		self.scroller:ResetPosition()
	end)
	self:initGotPartners()
end

function ActivitySpaceExploreTeam:setGetLabel()
	self.labelGet.text = __("SPACE_EXPLORE_TEAM_TEXT02", self.guaranteeTimes - self.activityData.detail_.times)
end

function ActivitySpaceExploreTeam:initContent()
	local ids = myTable:getIDs()
	local uiRoots = {
		self.Rlist,
		self.SRlist,
		self.SSRlist
	}

	for _, id in ipairs(ids) do
		if myTable:notShow(id) ~= 1 then
			local grade = myTable:getGrade(id)
			local item = xyd.getItemIcon({
				scale = 0.9259259259259259,
				isLevMax = true,
				showLev = false,
				uiRoot = uiRoots[grade],
				itemID = id,
				dragScrollView = self.scroller
			}, xyd.ItemIconType.ACTIVITY_SPACE_EXPLORE_ICON)
			self.itemList[id] = item
		end
	end
end

function ActivitySpaceExploreTeam:initGotPartners()
	local partners = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPACE_EXPLORE).detail_.partners
	local ids = myTable:getIDs()
	local hasList = {}
	self.hasPartners = {}

	for i = 1, #partners do
		if partners[i] ~= 0 then
			table.insert(hasList, ids[i])

			self.hasPartners[ids[i]] = true
		end
	end

	self:updateItemList(hasList)
end

function ActivitySpaceExploreTeam:updateItemList(ids)
	for _, id in ipairs(ids) do
		if self.itemList[id] then
			self.itemList[id]:setChoose(true)
		end
	end
end

function ActivitySpaceExploreTeam:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "SPACE_EXPLORE_HELP_03"
		})
	end

	UIEventListener.Get(self.addBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.ACTIVITY_SPACE_EXPLORE_SUMMON_SCROLL
		})
	end

	UIEventListener.Get(self.summonOne).onClick = function ()
		self:onSummon(1)
	end

	UIEventListener.Get(self.summonTen).onClick = function ()
		self:onSummon(10)
	end
end

function ActivitySpaceExploreTeam:setCoinsResNum()
	self.labelNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_SPACE_EXPLORE_SUMMON_SCROLL)
end

function ActivitySpaceExploreTeam:onSummon(num)
	if xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_SPACE_EXPLORE_SUMMON_SCROLL) < num then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.ACTIVITY_SPACE_EXPLORE_SUMMON_SCROLL)))
	else
		local params = cjson.encode({
			num = num
		})

		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SPACE_EXPLORE_TEAM, params)
	end
end

function ActivitySpaceExploreTeam:onAward(event)
	local data = event.data

	if data.activity_id ~= xyd.ActivityID.ACTIVITY_SPACE_EXPLORE_TEAM then
		return
	end

	local ids = cjson.decode(data.detail).ids

	local function addCirAnimation(item)
		local sequence = self:getSequence()

		local function alphaSetter(value)
			item.imgDebris_.alpha = 1 - value
			item.labelNum_.alpha = 1 - value
			item.debrisBorder.alpha = 1 - value
			item.imgIcon_.alpha = value
			item.imgBorder_.alpha = value
		end

		sequence:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(alphaSetter), 1, 0.01, 1.5):SetEase(DG.Tweening.Ease.Linear))
		sequence:SetLoops(-1, DG.Tweening.LoopType.Yoyo)
	end

	local function effectCallBack()
		local items = {}

		for _, id in ipairs(ids) do
			local grade = myTable:getGrade(id)

			table.insert(items, {
				showLev = false,
				item_id = id,
				iconType = xyd.ItemIconType.ACTIVITY_SPACE_EXPLORE_ICON,
				cool = grade == 3 and 1 or 0
			})
		end

		xyd.WindowManager.get():openWindow("gamble_rewards_window", {
			wnd_type = 4,
			data = items,
			cost = {
				xyd.ItemID.ACTIVITY_SPACE_EXPLORE_SUMMON_SCROLL,
				#ids
			},
			buyCallback = function (cost)
				self:onSummon(cost[2])
			end,
			afterAnimationCallback = function (win)
				local curHas = {}

				for _, entry in ipairs(win.items_) do
					local itemData = entry.itemData
					local item = entry.item

					if (self.hasPartners[itemData.item_id] or curHas[itemData.item_id]) and not item.hasAnimation then
						item.hasAnimation = true

						item:setImgDebris_("icon_239")

						item.imgDebris_.alpha = 0

						item:setLabelNum(myTable:getDecompose(itemData.item_id)[1][2])

						item.labelNum_.alpha = 0
						local debrisBorder = NGUITools.AddChild(item.go, item.imgBorder_.gameObject):GetComponent(typeof(UISprite))

						xyd.setUISpriteAsync(debrisBorder, nil, "item_bg")

						debrisBorder.alpha = 0
						item.debrisBorder = debrisBorder

						addCirAnimation(item)
					end

					curHas[itemData.item_id] = true
				end
			end,
			callback = function ()
				for _, id in ipairs(ids) do
					self.hasPartners[id] = true
				end
			end
		})
	end

	effectCallBack()
	self:updateItemList(ids)
	self:setGetLabel()
end

function ActivitySpaceExploreTeam:onItemChange(event)
	local data = event.data.items

	for i = 1, #data do
		local item = data[i]

		if item.item_id == xyd.ItemID.ACTIVITY_SPACE_EXPLORE_SUMMON_SCROLL then
			self:setCoinsResNum()
		end
	end
end

return ActivitySpaceExploreTeam
