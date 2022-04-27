local DressBuffsShowWindow = class("DressBuffsShowWindow", import(".BaseWindow"))
local BuffItem = class("BuffItem", import("app.components.CopyComponent"))

function DressBuffsShowWindow:ctor(name, params)
	DressBuffsShowWindow.super.ctor(self, name, params)

	self.showBuffsSumArr = params.showBuffsSumArr or {}
	self.dealArr = self:dealInfos()
end

function DressBuffsShowWindow:initWindow()
	self:getUIComponent()
	DressBuffsShowWindow.super.initWindow(self)
	self:layout()
	self:registerEvent()
end

function DressBuffsShowWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.scrollerCon = self.groupAction:NodeByName("scrollerCon").gameObject
	self.award_item = self.scrollerCon:NodeByName("award_item").gameObject
	local itemScoreLabel = self.award_item:ComponentByName("scoreLabel_", typeof(UILabel))
	local itemBg = self.award_item:ComponentByName("bg", typeof(UISprite))
	self.scroller1 = self.scrollerCon:NodeByName("scroller1").gameObject
	self.scroller1UIScrollView = self.scrollerCon:ComponentByName("scroller1", typeof(UIScrollView))
	self.itemGroup1 = self.scroller1:NodeByName("itemGroup1").gameObject
	self.itemGroup1UIWrapContent = self.scroller1:ComponentByName("itemGroup1", typeof(UIWrapContent))

	if xyd.Global.lang == "de_de" or xyd.Global.lang == "fr_fr" then
		itemBg.height = 140
		itemScoreLabel.height = 125
		itemScoreLabel.spacingY = 2
		self.itemGroup1UIWrapContent.itemSize = 150
	end

	if xyd.Global.lang == "en_en" then
		itemBg.height = 110
		itemScoreLabel.height = 100
		self.itemGroup1UIWrapContent.itemSize = 122
	end

	self.wrapContent1 = import("app.common.ui.FixedWrapContent").new(self.scroller1UIScrollView, self.itemGroup1UIWrapContent, self.award_item, BuffItem, self)
	self.btnCircles = self.groupAction:NodeByName("btnCircles").gameObject
	self.btnQualityChosen = self.btnCircles:NodeByName("btnQualityChosen").gameObject

	for i = 0, 7 do
		self["btnCircle" .. i] = self.btnCircles:NodeByName("btnCircle" .. i).gameObject
	end

	self.groupNone = self.groupAction:NodeByName("groupNone").gameObject
	self.imgNoneShow = self.groupNone:ComponentByName("imgNoneShow", typeof(UISprite))
	self.labelNoneTips = self.groupNone:ComponentByName("labelNoneTips", typeof(UILabel))
end

function DressBuffsShowWindow:layout()
	self.labelTitle.text = __("DRESS_BUFFS_SHOW_WINDOW")
	self.showQuality = 0

	self:onQualityBtn(-1)
end

function DressBuffsShowWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)

	for k = 0, 7 do
		UIEventListener.Get(self["btnCircle" .. k]).onClick = function ()
			self:onQualityBtn(k)
		end
	end
end

function DressBuffsShowWindow:onQualityBtn(index)
	local isPlaySoundId = true

	if self.showQuality ~= index or index == -1 then
		if index == -1 then
			index = 0
		end

		isPlaySoundId = false
		local pos = self["btnCircle" .. index].transform.localPosition

		self.btnQualityChosen:SetLocalPosition(pos.x, pos.y, pos.z)

		self.showQuality = index
	elseif self.showQuality == index then
		if self.showQuality == 0 then
			return
		else
			self:onQualityBtn(0)

			return
		end
	end

	if isPlaySoundId then
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
	end

	if #self:getInfos(index) == 0 then
		if index == 0 then
			self.labelNoneTips.text = __("PERSON_DRESS_MAIN_13")
		else
			self.labelNoneTips.text = __("PERSON_DRESS_BUFFS_TIPS_" .. index)
		end

		self.groupNone:SetActive(true)
		self.wrapContent1:setInfos({}, {})

		return
	else
		self.groupNone:SetActive(false)
	end

	local infos = self:getInfos(index)

	self:waitForFrame(1, function ()
		self.wrapContent1:setInfos(infos, {})
		self.scroller1UIScrollView:ResetPosition()
	end)
end

function DressBuffsShowWindow:getInfos(index)
	return self.dealArr[index] or {}
end

function DressBuffsShowWindow:dealInfos()
	local arr = {
		[0] = {}
	}

	for i, info in pairs(self.showBuffsSumArr) do
		local qlt = xyd.tables.senpaiDressSkillBuffTable:getQlt(info.style_id)

		if qlt and qlt ~= 0 then
			table.insert(arr[0], info)

			if not arr[qlt] then
				arr[qlt] = {}
			end

			table.insert(arr[qlt], info)
		end
	end

	return arr
end

function BuffItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	BuffItem.super.ctor(self, go)
end

function BuffItem:initUI()
	self.award_item = self.go
	self.scoreLabel = self.award_item:ComponentByName("scoreLabel_", typeof(UILabel))
	self.bg = self.award_item:ComponentByName("bg", typeof(UISprite))
	self.icon = self.award_item:ComponentByName("icon", typeof(UISprite))
	UIEventListener.Get(self.bg.gameObject).onClick = handler(self, self.onTouchTip)
end

function BuffItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.scoreLabel.fontSize = 20

	if xyd.Global.lang == "de_de" or xyd.Global.lang == "fr_fr" then
		self.bg.height = 140
		self.scoreLabel.height = 125
		self.scoreLabel.spacingY = 2
	end

	if xyd.Global.lang == "en_en" then
		self.bg.height = 110
		self.scoreLabel.height = 100
	end

	self.style_id = info.style_id
	self.nums = info.nums

	if info.first_id and info.first_id > 0 then
		local count_arr = xyd.models.dress:getActiveBuffDynamics()

		if count_arr[tostring(info.first_id)] then
			table.insert(self.nums, count_arr[tostring(info.first_id)])
		else
			table.insert(self.nums, 0)
		end
	end

	local str = xyd.tables.senpaiDressSkillBuffTextTable:getDesc(self.style_id, unpack(self.nums))
	self.scoreLabel.text = str

	while true do
		if self.scoreLabel.spacingY ~= 0 and self.scoreLabel.height > self.bg.height - 15 then
			self.scoreLabel.spacingY = 0
		elseif self.scoreLabel.spacingY == 0 and self.scoreLabel.height > self.bg.height - 15 then
			self.scoreLabel.fontSize = self.scoreLabel.fontSize - 1
		else
			break
		end
	end

	self.scoreLabel.gameObject:Y(0)

	local iconName = xyd.tables.senpaiDressSkillBuffTable:getIcon(self.style_id)
	local scale = xyd.tables.senpaiDressSkillBuffTable:getScale(self.style_id)

	if not scale or scale == 0 then
		scale = 1
	end

	xyd.setUISpriteAsync(self.icon, nil, iconName, function ()
		self.icon:SetLocalScale(scale, scale, scale)
	end, nil, true)
end

function BuffItem:onTouchTip()
	xyd.WindowManager.get():openWindow("dress_buffs_related_window", {
		buffId = self.style_id
	})
end

return DressBuffsShowWindow
