local BaseWindow = import(".BaseWindow")
local ActivityChimePreviewWindow = class("ActivityChimePreviewWindow", BaseWindow)
local ActivityChimePreviewWindowItem = class("ActivityChimePreviewWindowItem")

function ActivityChimePreviewWindow:ctor(parentGO, params)
	BaseWindow.ctor(self, parentGO, params)

	self.params = params
end

function ActivityChimePreviewWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function ActivityChimePreviewWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:ComponentByName("groupAction", typeof(UIWidget))
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.btnClose = self.groupAction:NodeByName("btnClose").gameObject
	self.labelSuperAward = self.groupAction:ComponentByName("labelSuperAward", typeof(UILabel))
	self.groupSuperAward = self.groupAction:NodeByName("groupSuperAward").gameObject
	self.scroller = self.groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.awardBoxGO = self.scroller:NodeByName("awardBox").gameObject
	self.awardBoxComp = self.awardBoxGO:GetComponent(typeof(UIWidget))
	self.commonAwardtitle1 = self.awardBoxGO:NodeByName("commonAwardtitle1").gameObject
	self.titleCon1 = self.commonAwardtitle1:NodeByName("titleCon").gameObject
	self.labelCommonAward1 = self.titleCon1:ComponentByName("labelCommonAward", typeof(UILabel))
	self.commonAwardtitle2 = self.awardBoxGO:NodeByName("commonAwardtitle2").gameObject
	self.titleCon2 = self.commonAwardtitle2:NodeByName("titleCon").gameObject
	self.labelCommonAward2 = self.titleCon2:ComponentByName("labelCommonAward", typeof(UILabel))
	self.awardBox1 = self.awardBoxGO:NodeByName("awardBox1").gameObject
	self.awardBox2 = self.awardBoxGO:NodeByName("awardBox2").gameObject
	self.awardBox1Comp = self.awardBox1:GetComponent(typeof(UIWidget))
	self.awardBox2Comp = self.awardBox2:GetComponent(typeof(UIWidget))
	self.groupCommonAward1 = self.awardBox1:NodeByName("groupCommonAward").gameObject
	self.groupCommonAward2 = self.awardBox2:NodeByName("groupCommonAward").gameObject
	self.itemCell = winTrans:NodeByName("awardItem").gameObject
end

function ActivityChimePreviewWindow:layout()
	self.labelTitle.text = __("ACTIVITY_AWARD_PREVIEW_TITLE")
	self.labelSuperAward.text = __("ACTIVITY_CHIME_TEXT04")
	self.labelCommonAward1.text = __("ACTIVITY_CHIME_TEXT05")
	self.labelCommonAward2.text = __("ACTIVITY_CHIME_TEXT06")
	local ids = xyd.tables.activityChimeDropboxTable:getIDs()

	dump(ids, "ids")

	local totalWeight = 0
	local type1IDsList = {}
	local type2IDsList = {}
	local type1Count = 0
	local type2Count = 0
	local totalWeight1 = 0
	local totalWeight2 = 0

	for _, id in ipairs(ids) do
		local weight = xyd.tables.activityChimeDropboxTable:getWeight(id)
		local type = xyd.tables.activityChimeDropboxTable:getType(id)
		local isBig = xyd.tables.activityChimeDropboxTable:getIsBig(id)

		if type == 1 then
			table.insert(type1IDsList, tonumber(id))

			type1Count = type1Count + 1
			totalWeight1 = totalWeight1 + weight
		else
			table.insert(type2IDsList, tonumber(id))

			type2Count = type2Count + 1
			totalWeight2 = totalWeight2 + weight
		end

		if isBig == 1 then
			local data = xyd.tables.activityChimeDropboxTable:getAward(id)
			local tmp1 = NGUITools.AddChild(self.groupSuperAward.gameObject, self.itemCell.gameObject)

			tmp1:ComponentByName("labelProbablility", typeof(UILabel)):SetActive(false)

			local superAward = ActivityChimePreviewWindowItem.new(tmp1)

			superAward:setInfo({
				award = data,
				scroller = self.scroller
			})
		end
	end

	local cellHeight = 140
	local columnLimit = 5
	local title1Height = self.commonAwardtitle1:GetComponent(typeof(UIWidget)).height
	local title2Height = self.commonAwardtitle2:GetComponent(typeof(UIWidget)).height
	self.awardBox1Comp.height = math.ceil(type1Count / columnLimit) * cellHeight
	self.awardBox2Comp.height = math.ceil(type2Count / columnLimit) * cellHeight
	self.awardBoxComp.height = self.awardBox1Comp.height + self.awardBox2Comp.height + title1Height + title2Height

	table.sort(type2IDsList)
	table.sort(type1IDsList)

	for _, id in ipairs(type2IDsList) do
		local data = xyd.tables.activityChimeDropboxTable:getAward(id)
		local weight = xyd.tables.activityChimeDropboxTable:getWeight(id)
		local tmp1 = NGUITools.AddChild(self.groupCommonAward1.gameObject, self.itemCell.gameObject)
		local commomAward = ActivityChimePreviewWindowItem.new(tmp1)

		commomAward:setInfo({
			award = data,
			scroller = self.scroller,
			probablility = math.ceil(weight * 1000000 / totalWeight1) / 10000 .. "%"
		})
	end

	self:waitForTime(0.5, function ()
		for _, id in ipairs(type1IDsList) do
			local data = xyd.tables.activityChimeDropboxTable:getAward(id)
			local weight = xyd.tables.activityChimeDropboxTable:getWeight(id)
			local tmp1 = NGUITools.AddChild(self.groupCommonAward2.gameObject, self.itemCell.gameObject)
			local commomAward = ActivityChimePreviewWindowItem.new(tmp1)

			commomAward:setInfo({
				award = data,
				scroller = self.scroller,
				probablility = math.ceil(weight * 1000000 / totalWeight2) / 10000 .. "%"
			})
			self.groupCommonAward1:GetComponent(typeof(UIGrid)):Reposition()
			self.groupCommonAward2:GetComponent(typeof(UIGrid)):Reposition()
			self.awardBoxGO:GetComponent(typeof(UITable)):Reposition()
			self.scroller:ResetPosition()
		end
	end)
	self.groupCommonAward1:GetComponent(typeof(UIGrid)):Reposition()
	self.groupCommonAward2:GetComponent(typeof(UIGrid)):Reposition()
	self.awardBoxGO:GetComponent(typeof(UITable)):Reposition()
	self.scroller:ResetPosition()
end

function ActivityChimePreviewWindow:register()
	UIEventListener.Get(self.btnClose).onClick = function ()
		self:close()
	end
end

function ActivityChimePreviewWindowItem:ctor(go)
	self.go = go

	self:getUIComponent()
end

function ActivityChimePreviewWindowItem:getUIComponent()
	self.icon = self.go:NodeByName("icon").gameObject
	self.labelProbablility = self.go:ComponentByName("labelProbablility", typeof(UILabel))
end

function ActivityChimePreviewWindowItem:setInfo(params)
	xyd.getItemIcon({
		show_has_num = true,
		showGetWays = false,
		notShowGetWayBtn = true,
		itemID = params.award[1],
		num = params.award[2],
		uiRoot = self.icon.gameObject,
		wndType = xyd.ItemTipsWndType.ACTIVITY,
		dragScrollView = params.scroller
	})

	self.labelProbablility.text = params.probablility
end

return ActivityChimePreviewWindow
