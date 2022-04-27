local ActivityContent = import(".ActivityContent")
local NewSummonSpecialHeroGift = class("NewSummonSpecialHeroGift", ActivityContent)
local NewSummonSpecialHeroGiftItem = class("NewSummonSpecialHeroGiftItem", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local ActivityGachaPartnerAwardTable = xyd.tables.activityGachaPartnerAwardTable

function NewSummonSpecialHeroGift:ctor(parentGO, params, parent)
	ActivityContent.ctor(self, parentGO, params, parent)
end

function NewSummonSpecialHeroGift:getPrefabPath()
	return "Prefabs/Windows/activity/new_summon_special_hero_gift"
end

function NewSummonSpecialHeroGift:getUIComponent()
	local go = self.go
	self.imgText = go:ComponentByName("imgText", typeof(UISprite))
	local textGroup = go:NodeByName("textGroup").gameObject
	self.textGroup_ = textGroup
	self.labelTime = textGroup:ComponentByName("labelTime", typeof(UILabel))
	self.labelText01 = textGroup:ComponentByName("labelText01", typeof(UILabel))
	self.labelText02 = textGroup:ComponentByName("labelText02", typeof(UILabel))
	self.labelText03 = textGroup:ComponentByName("labelText03", typeof(UILabel))

	self.labelText03.transform:X(0)

	self.labelText04 = textGroup:ComponentByName("labelText04", typeof(UILabel))
	self.contentGroup = go:NodeByName("contentGroup").gameObject
	self.partnerInfoBtn = self.contentGroup:NodeByName("partnerInfoBtn").gameObject
	self.scrollView = self.contentGroup:ComponentByName("scroller_", typeof(UIScrollView))
	self.giftItem = self.contentGroup:NodeByName("scroller_/new_summon_special_hero_gift_item").gameObject
	self.itemGroup = self.contentGroup:NodeByName("scroller_/itemGroup").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scrollView, wrapContent, self.giftItem, NewSummonSpecialHeroGiftItem, self)
end

function NewSummonSpecialHeroGift:initUIComponent()
	self:setText()
	self:setItem()
end

function NewSummonSpecialHeroGift:resizeToParent()
	NewSummonSpecialHeroGift.super.resizeToParent(self)
	self.go:Y(-520)

	local parentHeight = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	if parentHeight < 1000 then
		self.imgText.gameObject:Y(425)
		self.contentGroup:Y(196)

		if xyd.Global.lang == "en_en" or xyd.Global.lang == "fr_fr" then
			self.labelText03.fontSize = 17
			self.labelText04.fontSize = 17
		end

		if xyd.Global.lang == "ja_jp" then
			self.labelText03.fontSize = 18
			self.labelText04.fontSize = 18
		end

		if xyd.Global.lang == "de_de" then
			self.labelText03.fontSize = 18
			self.labelText04.fontSize = 18
		end
	end

	local moveY = (parentHeight - 869) * 40 / 75

	if moveY > 80 then
		moveY = 80
	end

	self.textGroup_:Y(315 - moveY)
end

function NewSummonSpecialHeroGift:onRegister()
	ActivityContent:onRegister()

	UIEventListener.Get(self.partnerInfoBtn).onClick = function ()
		xyd.openWindow("partner_info", {
			grade = 6,
			lev = 100,
			table_id = xyd.tables.miscTable:getVal("activity_gacha_partners")
		})
	end
end

function NewSummonSpecialHeroGift:initUI()
	self:getUIComponent()
	ActivityContent.initUI(self)
	self:initUIComponent()
	self:onRegister()
end

function NewSummonSpecialHeroGift:setText()
	self.labelText01.text = __("END_TEXT")
	self.labelText03.text = __("NEW_SUMMON_SPECIAL_HERO_GIFT_TEXT02")
	self.labelText04.text = __("NEW_SUMMON_SPECIAL_HERO_GIFT_TEXT03")
	self.partnerInfoBtn:ComponentByName("button_label", typeof(UILabel)).text = __("NEW_SUMMON_SPECIAL_HERO_GIFT_TEXT04")
	local leftTime = self.activityData:getUpdateTime() - xyd.getServerTime()

	if leftTime > 0 then
		local CountDown = import("app.components.CountDown")

		CountDown.new(self.labelTime, {
			duration = leftTime
		})
	else
		self.labelTime:SetActive(false)
		self.labelText01:SetActive(false)
	end

	xyd.setUISpriteAsync(self.imgText, nil, "new_summon_special_hero_gift_text01_" .. xyd.Global.lang, function ()
		self.imgText:MakePixelPerfect()
	end)
end

function NewSummonSpecialHeroGift:setItem()
	local function sort_func(a, b)
		if a.isCompleted == b.isCompleted then
			return a.id < b.id
		elseif a.isCompleted then
			return false
		else
			return true
		end
	end

	self.items = {}
	local ids = ActivityGachaPartnerAwardTable:getIDs()

	for i = 1, #ids do
		local id = ids[i]
		local isCompleted = ActivityGachaPartnerAwardTable:getLevel(id) <= self.activityData.detail.point
		local item = {
			id = id,
			isCompleted = isCompleted,
			point = self.activityData.detail.point
		}

		table.insert(self.items, item)
	end

	table.sort(self.items, sort_func)
	self.wrapContent:setInfos(self.items, {})
end

function NewSummonSpecialHeroGiftItem:ctor(go, parent)
	self.items = {}

	NewSummonSpecialHeroGiftItem.super.ctor(self, go, parent)
end

function NewSummonSpecialHeroGiftItem:initUI()
	local go = self.go
	self.itemGroup = go:NodeByName("itemGroup").gameObject
	self.labelText = go:ComponentByName("labelText", typeof(UILabel))
	self.progress = go:ComponentByName("progress", typeof(UISlider))
	self.progressLabel = go:ComponentByName("progress/labelDisplay", typeof(UILabel))
end

function NewSummonSpecialHeroGiftItem:updateInfo()
	self.id = self.data.id
	self.level = self.data.point
	self.isCompleted = self.data.isCompleted

	self:setText()
	self:setIcon()
	self:setProgress()
end

function NewSummonSpecialHeroGiftItem:setText()
	local target = ActivityGachaPartnerAwardTable:getLevel(self.id)
	self.labelText.text = __("NEW_SUMMON_SPECIAL_HERO_GIFT_TEXT05", target)
end

function NewSummonSpecialHeroGiftItem:setIcon()
	local awards = ActivityGachaPartnerAwardTable:getAwards(self.id)

	for i = 1, #awards do
		local data = awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			if #self.items < #awards then
				local item = xyd.getItemIcon({
					show_has_num = true,
					labelNumScale = 1.2,
					scale = 0.7,
					uiRoot = self.itemGroup,
					itemID = data[1],
					num = data[2],
					wndType = xyd.ItemTipsWndType.ACTIVITY
				})

				xyd.setDragScrollView(item.go, self.scrollView)
				table.insert(self.items, item)

				if self.isCompleted then
					item:setChoose(true)
				end
			else
				self.items[i]:setInfo({
					itemID = data[1],
					num = data[2]
				})
			end
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

function NewSummonSpecialHeroGiftItem:setProgress()
	local target = ActivityGachaPartnerAwardTable:getLevel(self.id)
	local gotten = math.min(self.level, target)
	self.progress.value = gotten / target
	self.progressLabel.text = tostring(gotten) .. "/" .. tostring(target)
end

return NewSummonSpecialHeroGift
