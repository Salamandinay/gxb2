local SkinBuffDetailWindow = class("SkinBuffDetailWindow", import(".BaseWindow"))
local ThemeItem = class("ThemeItem", import("app.components.CopyComponent"))

function SkinBuffDetailWindow:ctor(name, params)
	SkinBuffDetailWindow.super.ctor(self, name, params)
end

function SkinBuffDetailWindow:initWindow()
	self:getUIComponent()
	SkinBuffDetailWindow.super.initWindow(self)
	self:registerEvent()
	self:initData()
	self:layout()
end

function SkinBuffDetailWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.labelWinTitle = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.content = self.groupAction:NodeByName("content").gameObject
	self.topGroup = self.content:NodeByName("topGroup").gameObject
	self.labeBuffEffect = self.topGroup:ComponentByName("labeBuffEffect", typeof(UILabel))
	self.labelLevel = self.topGroup:ComponentByName("labelLevel", typeof(UILabel))
	self.icon = self.labelLevel:ComponentByName("icon", typeof(UISprite))
	self.labelTitle = self.topGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.progressGroup = self.topGroup:NodeByName("progressGroup").gameObject
	self.progressBg = self.progressGroup:ComponentByName("progressBg", typeof(UISprite))
	self.progressBar = self.progressGroup:ComponentByName("", typeof(UISlider))
	self.progressLabel_ = self.progressGroup:ComponentByName("progressLabel_", typeof(UILabel))
	self.rankContent = self.content:NodeByName("rankContent").gameObject
	self.rankTitleGroup = self.rankContent:NodeByName("titleGroup").gameObject
	self.labelRankTitle = self.rankTitleGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.rankScroller = self.rankContent:NodeByName("scroller").gameObject
	self.rankScrollView = self.rankContent:ComponentByName("scroller", typeof(UIScrollView))
	self.rankGroup = self.rankScroller:NodeByName("rankGroup").gameObject
	self.rankitemGroup = self.rankGroup:NodeByName("rankitemGroup").gameObject
	local arr = {}

	for i = 1, 4 do
		self["rank_item" .. i] = self.rankitemGroup:NodeByName("rank_item" .. i).gameObject
		self["labelRankDesc" .. i] = self["rank_item" .. i]:ComponentByName("labelDesc", typeof(UILabel))
		self["labelRankPoint" .. i] = self["rank_item" .. i]:ComponentByName("labelHasNum", typeof(UILabel))
		arr[self["rank_item" .. i]] = i
	end

	self.themeContent = self.content:NodeByName("themeContent").gameObject
	self.themeTitleGroup = self.themeContent:NodeByName("titleGroup").gameObject
	self.labelThemeTitle = self.themeTitleGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.themeScroller = self.themeContent:NodeByName("scroller").gameObject
	self.themeScrollView = self.themeContent:ComponentByName("scroller", typeof(UIScrollView))
	self.theme_item = self.themeScroller:NodeByName("theme_item").gameObject
	self.themeGroup = self.themeScroller:NodeByName("themeGroup").gameObject
	self.themeItemGroup = self.themeGroup:NodeByName("themeItemGroup").gameObject
	self.themeItemGroup_layout = self.themeGroup:ComponentByName("themeItemGroup", typeof(UILayout))
end

function SkinBuffDetailWindow:initData()
	self.themeDatas = {}
	local themeIDs = xyd.tables.collectionSkinGroupTable:getIDs()
	self.point = xyd.models.backpack:getItemNumByID(377)

	for i = 1, #themeIDs do
		local themeID = themeIDs[i]
		local skinIDs = xyd.tables.collectionSkinGroupTable:getSkins(themeID)
		local hasNum = 0
		local limitNum = #skinIDs

		for j = 1, limitNum do
			local skin_id = skinIDs[j]
			local collectionID = xyd.tables.itemTable:getCollectionId(skin_id)

			if xyd.models.collection:isGot(collectionID) then
				hasNum = hasNum + 1
			end
		end

		if hasNum > 0 then
			local point = xyd.models.collection:getPointsByThemeID(themeIDs[i])

			table.insert(self.themeDatas, {
				themeID = themeIDs[i],
				limitNum = limitNum,
				hasNum = hasNum,
				point = point
			})
		end
	end

	self.totalSkinNumByQlt = {
		0,
		0,
		0,
		0
	}
	local skinCollectionIDs = xyd.tables.collectionTable:getIdsListByType(xyd.CollectionTableType.SKIN)

	for i = 1, #skinCollectionIDs do
		local qlt = xyd.tables.collectionTable:getQlt(skinCollectionIDs[i])
		self.totalSkinNumByQlt[qlt] = self.totalSkinNumByQlt[qlt] + 1
	end

	self.lev = xyd.models.collection:getSkinCollectionLevel()
	self.curLevPoint = 0

	if self.lev > 0 then
		self.curLevPoint = xyd.tables.collectionSkinEffectTable:getPoint(self.lev)
	end

	local maxLev = #xyd.tables.collectionSkinEffectTable:getIDs()
	self.nextLevPoint = xyd.tables.collectionSkinEffectTable:getPoint(math.min(self.lev + 1, maxLev))
	self.pointByRank, self.haveSkinNumByQlt = xyd.models.collection:getPointsByQlt()
end

function SkinBuffDetailWindow:addTitle()
	self.labelWinTitle.text = __("COLLECTION_SKIN_TEXT01")
end

function SkinBuffDetailWindow:layout()
	self.labelTitle.text = __("COLLECTION_SKIN_TEXT01")
	self.labelRankTitle.text = __("COLLECTION_SKIN_TEXT18")
	local descTexts = {
		__("COLLECTION_SKIN_TEXT19"),
		__("COLLECTION_SKIN_TEXT20"),
		__("COLLECTION_SKIN_TEXT21"),
		__("COLLECTION_SKIN_TEXT22")
	}

	for i = 1, 4 do
		self["labelRankDesc" .. i].text = descTexts[i] .. "[c][394046]" .. " (" .. self.haveSkinNumByQlt[i] .. "/" .. self.totalSkinNumByQlt[i] .. ")" .. "[-][/c]"
		self["labelRankPoint" .. i].text = self.pointByRank[i]
	end

	self.labelThemeTitle.text = __("COLLECTION_SKIN_TEXT23")

	if self.themeItems == nil then
		self.themeItems = {}

		for i = 1, #self.themeDatas do
			local itemObj = NGUITools.AddChild(self.themeItemGroup, self.theme_item)
			local item = ThemeItem.new(itemObj)

			item:setInfo(self.themeDatas[i])
			table.insert(self.themeItems, item)
		end
	else
		for i = 1, #self.themeDatas do
			self.themeItems[i]:setInfo(self.themeDatas[i])
		end
	end

	self.themeItemGroup_layout:Reposition()
	self.themeScrollView:ResetPosition()

	self.progressLabel_.text = self.point .. "/" .. self.nextLevPoint
	self.progressBar.value = math.min((self.point - self.curLevPoint) / math.max(1, self.nextLevPoint - self.curLevPoint), 1)
	self.labelLevel.text = self.lev

	if self.lev >= 0 then
		local effects = xyd.tables.collectionSkinEffectTable:getEffect(math.max(1, self.lev))
		local attrText = ""

		for i = 1, #effects do
			local text = xyd.tables.dBuffTable:getDesc(effects[i][1])
			local factor = xyd.tables.dBuffTable:getFactor(effects[i][1])

			if self.lev == 0 then
				effects[i][2] = 0
			end

			if xyd.tables.dBuffTable:isPercent(effects[i][1]) then
				text = text .. " +" .. string.format("%.1f", effects[i][2] * 100) .. "%"
			elseif factor and factor > 0 then
				text = text .. " +" .. string.format("%.1f", effects[i][2] * 100 / factor) .. "%"
			else
				text = text .. " +" .. effects[i][2]
			end

			attrText = attrText .. text

			if i ~= #effects then
				attrText = attrText .. ", "
			end
		end

		self.labeBuffEffect.text = "[c][5e6996]" .. __("COLLECTION_SKIN_TEXT03") .. " " .. "[-][/c]" .. "[c][369900]" .. attrText .. "[-][/c]"
	end
end

function SkinBuffDetailWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function ThemeItem:ctor(go)
	self.go = go

	self:getUIComponent()
end

function ThemeItem:getUIComponent()
	self.labelDesc = self.go:ComponentByName("labelDesc", typeof(UILabel))
	self.labelHasNum = self.go:ComponentByName("labelHasNum", typeof(UILabel))
	self.icon = self.labelHasNum:ComponentByName("icon", typeof(UISprite))
end

function ThemeItem:setInfo(params)
	if not params then
		self.go:SetActive(false)
	else
		self.go:SetActive(true)
	end

	self.themeID = params.themeID
	self.limitNum = params.limitNum
	self.hasNum = params.hasNum
	self.point = params.point
	self.name = xyd.tables.collectionSkinGroupTextTable:getName(self.themeID)
	self.labelDesc.text = self.name .. " (" .. self.hasNum .. "/" .. self.limitNum .. ")"
	self.labelHasNum.text = self.point
end

return SkinBuffDetailWindow
