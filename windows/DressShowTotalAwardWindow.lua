local BaseWindow = import(".BaseWindow")
local DressShowTotalAwardWindow = class("DressShowTotalAwardWindow", BaseWindow)
local CountDown = import("app.components.CountDown")
local AdvanceIcon = import("app.components.AdvanceIcon")

function DressShowTotalAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.dressShows
end

function DressShowTotalAwardWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.labeTotalPoint = self.groupAction:ComponentByName("labeTotalPoint", typeof(UILabel))
	self.content = self.groupAction:NodeByName("content").gameObject
	self.pointGroup = self.content:NodeByName("pointGroup").gameObject
	self.group1 = self.pointGroup:NodeByName("group1").gameObject
	self.group2 = self.pointGroup:NodeByName("group2").gameObject
	self.group3 = self.pointGroup:NodeByName("group3").gameObject
	self.group4 = self.pointGroup:NodeByName("group4").gameObject
	self.awardGroup = self.content:NodeByName("awardGroup").gameObject
	self.tipGoup = self.awardGroup:NodeByName("tipGoup").gameObject
	self.tipGoup_layout = self.awardGroup:ComponentByName("tipGoup", typeof(UILayout))
	self.labelTime = self.tipGoup:ComponentByName("labelTime", typeof(UILabel))
	self.labelDesc = self.tipGoup:ComponentByName("labelDesc", typeof(UILabel))
	self.itemGroup = self.awardGroup:NodeByName("itemGroup").gameObject
	self.itemGroup_layout = self.awardGroup:ComponentByName("itemGroup", typeof(UILayout))
end

function DressShowTotalAwardWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initFourGroup()

	if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "en_en" or xyd.Global.lang == "de_de" then
		self.labelDesc.transform:SetSiblingIndex(0)
	end

	self.labelTitle.text = __("SHOW_WINDOW_TEXT43")
	self.labelDesc.text = __("SHOW_WINDOW_TEXT44")
	self.countDownTime = CountDown.new(self.labelTime)

	self.countDownTime:setInfo({
		duration = xyd.getTomorrowTime() - xyd.getServerTime()
	})
	self.tipGoup_layout:Reposition()

	local totalPoint = 0
	local itemsData = {}

	for i = 1, 4 do
		local score = xyd.models.dressShow:getScore(i)
		totalPoint = totalPoint + score
		local award = xyd.models.dressShow:getAwardsByShowID(i)

		if award and award[1] then
			for i = 1, #award do
				table.insert(itemsData, {
					item_id = award[i][1],
					item_num = award[i][2]
				})
			end
		end
	end

	local merge = {}
	local ifHide = {}
	local items = {}

	for i = 1, #itemsData do
		if itemsData[i].item_id ~= xyd.ItemID.VIP_EXP then
			merge[itemsData[i].item_id] = tonumber(itemsData[i].item_num) + (merge[itemsData[i].item_id] or 0)
			ifHide[itemsData[i].item_id] = itemsData[i].hideText or false
		end
	end

	for i, v in pairs(merge) do
		table.insert(items, {
			itemID = tonumber(i),
			num = v,
			hideText = ifHide[i]
		})
	end

	self.labeTotalPoint.text = totalPoint

	for i = #items, 1, -1 do
		xyd.getItemIcon({
			showNum = true,
			hideText = true,
			scale = 0.7222222222222222,
			uiRoot = self.itemGroup,
			itemID = items[i].itemID,
			num = items[i].num
		})
	end

	self.itemGroup_layout:Reposition()
end

function DressShowTotalAwardWindow:initFourGroup()
	for i = 1, 4 do
		local group = self["group" .. i]
		local labelGroup = group:ComponentByName("labelGroup", typeof(UILabel))
		local curPointGroup = group:NodeByName("curPointGroup").gameObject
		local curPointGroup_layout = group:ComponentByName("curPointGroup", typeof(UILayout))
		local labelRank = curPointGroup:ComponentByName("labelRank", typeof(UILabel))
		local labelCurPoint = curPointGroup:ComponentByName("labelCurPoint", typeof(UILabel))
		local labelNo = curPointGroup:ComponentByName("labelNo", typeof(UILabel))
		labelNo.text = __("SHOW_WINDOW_TEXT03")
		labelGroup.text = __("SHOW_WINDOW_TEXT02", i)
		local score = xyd.models.dressShow:getScore(i)
		local level = xyd.models.dressShow:getLevelByScore(score)

		if not score or score < 0 then
			labelNo:SetActive(true)
			labelRank:SetActive(false)
			labelCurPoint:SetActive(false)
		else
			labelNo:SetActive(false)
			labelRank:SetActive(true)
			labelCurPoint:SetActive(true)

			local rankColor = {
				1549556991,
				1549556991,
				1944887551,
				1820916223,
				4268112895.0,
				2874471423.0
			}

			if level == 6 then
				labelRank.text = "S"
				labelRank.color = Color.New2(2874471423.0)
			elseif level == 5 then
				labelRank.text = "A"
				labelRank.color = Color.New2(4268112895.0)
			elseif level == 4 then
				labelRank.text = "B"
				labelRank.color = Color.New2(1820916223)
			elseif level == 3 then
				labelRank.text = "C"
				labelRank.color = Color.New2(1944887551)
			elseif level == 2 then
				labelRank.text = "D"
				labelRank.color = Color.New2(1549556991)
			elseif level == 1 then
				labelRank.text = "E"
				labelRank.color = Color.New2(1549556991)
			end

			labelCurPoint.text = "(" .. score .. ")"
		end

		curPointGroup_layout:Reposition()
	end
end

return DressShowTotalAwardWindow
