local ActivityContent = import(".ActivityContent")
local NewSummonGiftBag = class("NewSummonGiftBag", ActivityContent)
local NewSummonGiftbagItem = class("NewSummonGiftbagItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CountDown = import("app.components.CountDown")

function NewSummonGiftBag:ctor(name, params)
	ActivityContent.ctor(self, name, params)
end

function NewSummonGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/new_summon_giftbag"
end

function NewSummonGiftBag:initUI()
	self:getUIComponent()
	ActivityContent.initUI(self)
	self:initUIComponent()
	self:initData()

	local index = xyd.db.misc:getValue("new_summon_giftbag_index")
	index = index or 1

	self:updateContent(tonumber(index))
end

function NewSummonGiftBag:getUIComponent()
	local go = self.go
	self.imgText_ = go:ComponentByName("imgText_", typeof(UITexture))
	self.textScroller = go:ComponentByName("textScroller", typeof(UIScrollView))
	self.desLabel_ = go:ComponentByName("textScroller/desLabel_", typeof(UILabel))
	self.timeLabel_ = go:ComponentByName("timeGroup/timeLabel_", typeof(UILabel))
	self.endLabel_ = go:ComponentByName("timeGroup/endLabel_", typeof(UILabel))
	self.navGroup = go:NodeByName("navGroup").gameObject
	self.nav_1 = self.navGroup:NodeByName("nav_1").gameObject
	self.navButton1 = self.nav_1:GetComponent(typeof(UIButton))
	self.navLabel1 = self.nav_1:ComponentByName("label_", typeof(UILabel))
	self.nav_2 = self.navGroup:NodeByName("nav_2").gameObject
	self.navLabel2 = self.nav_2:ComponentByName("label_", typeof(UILabel))
	self.navButton2 = self.nav_2:GetComponent(typeof(UIButton))
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	local contentGroup = go:NodeByName("contentGroup").gameObject
	self.bg_ = contentGroup:ComponentByName("bg_", typeof(UISprite))
	self.scrollView = contentGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = contentGroup:NodeByName("scroller/itemGroup").gameObject
	self.scrollerItem = contentGroup:NodeByName("scroller/new_summon_giftbag_item").gameObject
end

function NewSummonGiftBag:initUIComponent()
	xyd.setUITextureByNameAsync(self.imgText_, "new_summon_giftbag_text01_" .. tostring(xyd.Global.lang), true)

	self.endLabel_.text = __("TEXT_END")

	CountDown.new(self.timeLabel_, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.navLabel1.text = __("SUMMON_GIFTBAG_MENU01", self.activityData.detail.circle_times, xyd.tables.activityTable:getRound(self.id)[2])
	self.navLabel2.text = __("SUMMON_GIFTBAG_MENU02")
end

function NewSummonGiftBag:initData()
	self.data1 = {}
	local ids = xyd.tables.activityGachaTable:getIDs()

	for i = 1, #ids do
		local id = ids[i]
		local limit = xyd.tables.activityGachaTable:getPoint(id)
		local point = self.activityData.detail.point
		local isCompleted = limit <= point

		table.insert(self.data1, {
			type = 1,
			id = tonumber(id),
			limit = limit,
			point = point,
			awards = xyd.tables.activityGachaTable:getAwards(id),
			isCompleted = isCompleted
		})
	end

	self.data2 = {}
	local ids = xyd.tables.activityGachaPartnerAwardTable:getIDs()

	for i = 1, #ids do
		local id = ids[i]
		local limit = xyd.tables.activityGachaPartnerAwardTable:getLevel(id)
		local point = self.activityData.detail.relate_act_info.point
		local isCompleted = limit <= point

		table.insert(self.data2, {
			type = 2,
			id = tonumber(id),
			limit = limit,
			point = point,
			awards = xyd.tables.activityGachaPartnerAwardTable:getAwards(id),
			isCompleted = isCompleted
		})
	end

	local function sort_func(a, b)
		if a.isCompleted == b.isCompleted then
			return a.id < b.id
		elseif a.isCompleted then
			return false
		else
			return true
		end
	end

	table.sort(self.data1, sort_func)
	table.sort(self.data2, sort_func)

	local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.scrollerItem, NewSummonGiftbagItem, self)
end

function NewSummonGiftBag:updateContent(index)
	if index == 1 then
		self.navLabel1.color = Color.New2(47244640255.0)
		self.navLabel1.effectColor = Color.New2(1012112383)
		self.navLabel2.color = Color.New2(960513791)
		self.navLabel2.effectColor = Color.New2(4294967295.0)

		self.navButton1:SetEnabled(false)
		self.navButton2:SetEnabled(true)

		self.desLabel_.text = __("SUMMON_GIFTBAG_TEXT02")
	else
		self.navLabel1.color = Color.New2(960513791)
		self.navLabel1.effectColor = Color.New2(4294967295.0)
		self.navLabel2.color = Color.New2(47244640255.0)
		self.navLabel2.effectColor = Color.New2(1012112383)

		self.navButton1:SetEnabled(true)
		self.navButton2:SetEnabled(false)

		local partnerID = xyd.split(xyd.tables.miscTable:getVal("activity_gacha_partners"), "|", true)
		local partnerName = #partnerID == 1 and xyd.tables.partnerTable:getName(partnerID[1]) or __("A_AND_B", xyd.tables.partnerTable:getName(partnerID[1]), xyd.tables.partnerTable:getName(partnerID[2]))
		self.desLabel_.text = __("NEW_SUMMON_SPECIAL_HERO_GIFT_TEXT02", partnerName)
	end

	xyd.db.misc:setValue({
		key = "new_summon_giftbag_index",
		value = index
	})
	self.textScroller:ResetPosition()
	self.wrapContent:setInfos(self["data" .. index], {})
end

function NewSummonGiftBag:onRegister()
	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "SUMMON_GIFTBAG_HELP"
		})
	end

	for i = 1, 2 do
		UIEventListener.Get(self["nav_" .. i]).onClick = function ()
			self:updateContent(i)
		end
	end
end

function NewSummonGiftbagItem:ctor(go, parent)
	NewSummonGiftbagItem.super.ctor(self, go, parent)
end

function NewSummonGiftbagItem:initUI()
	local go = self.go
	self.progress = go:ComponentByName("progress", typeof(UISlider))
	self.progressBar = go:ComponentByName("progress/progressBar", typeof(UISprite))
	self.progressLabel = go:ComponentByName("progress/progressLabel", typeof(UILabel))
	self.labelText01 = go:ComponentByName("labelText01", typeof(UILabel))
	self.itemGroup = go:NodeByName("itemGroup").gameObject
end

function NewSummonGiftbagItem:updateInfo()
	self.id = self.data.id
	self.limit = self.data.limit
	self.point = math.min(self.data.point, self.limit)
	self.awards = self.data.awards
	self.isCompleted = self.data.isCompleted
	self.type = self.data.type

	if self.type == 1 then
		self.labelText01.text = __("SUMMON_GIFTBAG_TEXT03", self.limit)
	else
		local partnerID = xyd.split(xyd.tables.miscTable:getVal("activity_gacha_partners"), "|", true)
		local partnerName = #partnerID == 1 and xyd.tables.partnerTable:getName(partnerID[1]) or __("A_OR_B", xyd.tables.partnerTable:getName(partnerID[1]), xyd.tables.partnerTable:getName(partnerID[2]))
		self.labelText01.text = __("NEW_SUMMON_SPECIAL_HERO_GIFT_TEXT05", partnerName, self.limit)
	end

	local value = self.point / self.limit
	self.progress.value = value
	self.progressLabel.text = self.point .. " / " .. self.limit

	if value == 1 then
		xyd.setUISpriteAsync(self.progressBar, nil, "activity_bar_thumb_2")
	else
		xyd.setUISpriteAsync(self.progressBar, nil, "activity_bar_thumb")
	end

	NGUITools.DestroyChildren(self.itemGroup.transform)

	for i = 1, #self.awards do
		local data = self.awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			local icon = xyd.getItemIcon({
				show_has_num = true,
				hideText = true,
				scale = 0.6296296296296297,
				uiRoot = self.itemGroup,
				itemID = data[1],
				num = data[2],
				dragScrollView = self.parent.scrollView
			})

			if self.isCompleted then
				icon:setChoose(true)
			end
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

return NewSummonGiftBag
