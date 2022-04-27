local BaseWindow = import(".BaseWindow")
local SproutsPointAwardWindow = class("SproutsPointAwardWindow", BaseWindow)
local SproutsAwardItem = class("SproutsAwardItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CommonTabBar = import("app.common.ui.CommonTabBar")
local AwardTable = {
	xyd.tables.activitySproutsHeightAwardTable,
	xyd.tables.activitySproutsPartnerAwardTable
}

function SproutsPointAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.cur_select_ = 1
end

function SproutsPointAwardWindow:initWindow()
	SproutsPointAwardWindow.super:initWindow()
	self:getUIComponent()
	self:initUIComponent()
	self:updateLayout()
	self:initNav()
	self:register()
end

function SproutsPointAwardWindow:getUIComponent()
	SproutsPointAwardWindow.super:initWindow()

	local winTrans = self.window_:NodeByName("groupAction")
	self.titleLabel = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("closeBtn").gameObject
	self.navGroup_ = winTrans:NodeByName("navGroup").gameObject
	self.scrollView = winTrans:ComponentByName("scroller_", typeof(UIScrollView))
	self.itemGroup = winTrans:NodeByName("scroller_/itemGroup").gameObject
	self.itemCell = winTrans:NodeByName("scroller_/itemRoot").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.itemCell, SproutsAwardItem, self)
end

function SproutsPointAwardWindow:initUIComponent()
	self.titleLabel.text = __("ACTIVITY_SPROUTS_BTN_AWARD")
end

function SproutsPointAwardWindow:initNav()
	local chosen = {
		color = Color.New2(4294967295.0),
		effectColor = Color.New2(1012112383)
	}
	local unchosen = {
		color = Color.New2(960513791),
		effectColor = Color.New2(4294967295.0)
	}
	local colorParams = {
		chosen = chosen,
		unchosen = unchosen
	}
	self.tab_ = CommonTabBar.new(self.navGroup_, 2, function (index)
		xyd.SoundManager.get():playSound(xyd.SoundID.TAB)

		self.cur_select_ = index

		self:updateLayout()
	end, nil, colorParams)
	local tableLabels = {
		__("ACTIVITY_SPROUTS_NEW_TEXT03"),
		__("ACTIVITY_SPROUTS_NEW_TEXT04")
	}

	self.tab_:setTexts(tableLabels)
	self.tab_:setTabActive(1, true)
	self:updateNavRed()
end

function SproutsPointAwardWindow:updateLayout()
	self.collection_ = {}
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.SPROUTS)

	if self.cur_select_ == 1 then
		local ids = AwardTable[1]:getIDs()

		for i = 1, #ids do
			table.insert(self.collection_, {
				type = 1,
				id = ids[i],
				point = self.activityData.detail_.height,
				hasGotten = self.activityData.detail_.awards[i] == 1
			})
		end
	else
		local ids = AwardTable[2]:getIDs()

		for i = 1, #ids do
			table.insert(self.collection_, {
				type = 2,
				id = ids[i],
				point = self.activityData.detail_.pr_times,
				hasGotten = self.activityData.detail_.pr_awards[i] == 1
			})
		end
	end

	table.sort(self.collection_, function (a, b)
		if xyd.bool2Num(a.hasGotten) ~= xyd.bool2Num(b.hasGotten) then
			return xyd.bool2Num(a.hasGotten) < xyd.bool2Num(b.hasGotten)
		else
			return a.id < b.id
		end
	end)
	self.wrapContent:setInfos(self.collection_, {})
end

function SproutsPointAwardWindow:register()
	SproutsPointAwardWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.ACTIVITY_SPROUTS_SELECT_AWARD, handler(self, self.onAward1))
	self.eventProxy_:addEventListener(xyd.event.ACTIVITY_SPROUTS_PERSON_AWARD, handler(self, self.onAward2))
end

function SproutsPointAwardWindow:onAward1(event)
	local table_id = event.data.table_id
	local awards = AwardTable[1]:getAward(table_id)
	local items = {}

	for i = 1, #awards do
		local item = {
			item_id = awards[i][1],
			item_num = awards[i][2]
		}

		table.insert(items, item)
	end

	xyd.models.itemFloatModel:pushNewItems(items)

	self.activityData.detail_.awards[table_id] = 1
	local index = 0

	for i, v in ipairs(self.collection_) do
		if v.id == table_id then
			index = i

			break
		end
	end

	if self.cur_select_ == 1 then
		local items = self.wrapContent:getItems()
		local len = xyd.getLength(items)

		for i = -1, -len, -1 do
			if table_id == items[tostring(i)].id then
				local info = {
					hasGotten = true,
					type = 1,
					id = table_id,
					point = self.activityData.detail_.height
				}

				items[tostring(i)]:update(nil, info)

				if index > 0 then
					self.wrapContent.infos_[index] = info
				end

				break
			end
		end
	end

	self:updateNavRed()
end

function SproutsPointAwardWindow:onAward2(event)
	local table_id = event.data.table_id
	local awards = AwardTable[2]:getAward(table_id)
	local items = {}

	for i = 1, #awards do
		local item = {
			item_id = awards[i][1],
			item_num = awards[i][2]
		}

		table.insert(items, item)
	end

	xyd.models.itemFloatModel:pushNewItems(items)

	self.activityData.detail_.pr_awards[table_id] = 1

	if self.cur_select_ == 2 then
		local items = self.wrapContent:getItems()
		local len = xyd.getLength(items)

		for i = -1, -len, -1 do
			if table_id == items[tostring(i)].id then
				local info = {
					hasGotten = true,
					type = 2,
					id = table_id,
					point = self.activityData.detail_.pr_times
				}

				items[tostring(i)]:update(nil, info)

				self.wrapContent.infos_[-i] = info

				break
			end
		end
	end

	self:updateNavRed()
end

function SproutsPointAwardWindow:updateNavRed()
	self.tab_:getRedMark(1):SetActive(self.activityData:getRedMarkState2())
	self.tab_:getRedMark(2):SetActive(self.activityData:getRedMarkState3())
	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_SPROUTS, self.activityData:getRedMarkState())
end

function SproutsAwardItem:ctor(go, parentGo)
	SproutsAwardItem.super.ctor(self, go, parentGo)
end

function SproutsAwardItem:initUI()
	local go = self.go.transform
	self.awardGroup = go:NodeByName("awardGroup").gameObject
	self.tipsLabel = go:ComponentByName("tipsLabel", typeof(UILabel))
	self.valueLabel = go:ComponentByName("valueLabel", typeof(UILabel))
	self.awardBtn = go:NodeByName("awardBtn").gameObject
	self.awardBtnLabel = self.awardBtn:ComponentByName("label", typeof(UILabel))
	self.awardImg = go:ComponentByName("awardImg", typeof(UISprite))

	xyd.setUISpriteAsync(self.awardImg, nil, "mission_awarded_" .. xyd.Global.lang)

	self.awardBtnLabel.text = __("GET2")
end

function SproutsAwardItem:registerEvent()
	UIEventListener.Get(self.awardBtn).onClick = handler(self, self.reqAward)
end

function SproutsAwardItem:reqAward()
	if self.type == 1 then
		local msg = messages_pb.activity_sprouts_select_award_req()
		msg.activity_id = xyd.ActivityID.SPROUTS
		msg.table_id = self.id
		msg.select_index = 1

		xyd.Backend.get():request(xyd.mid.ACTIVITY_SPROUTS_SELECT_AWARD, msg)
	else
		local msg = messages_pb.activity_sprouts_person_award_req()
		msg.activity_id = xyd.ActivityID.SPROUTS
		msg.table_id = self.id

		xyd.Backend.get():request(xyd.mid.ACTIVITY_SPROUTS_PERSON_AWARD, msg)
	end
end

function SproutsAwardItem:updateInfo()
	self.id = self.data.id
	self.type = self.data.type
	self.point = self.data.point
	self.hasGotten = self.data.hasGotten
	local awards = AwardTable[self.type]:getAward(self.id)
	self.items = {}

	NGUITools.DestroyChildren(self.awardGroup.transform)

	for i = 1, #awards do
		local itemID = awards[i][1]
		local wndType = xyd.ItemTipsWndType.NORMAL

		if xyd.tables.itemTable:checkPuppetDebris(itemID) then
			wndType = xyd.ItemTipsWndType.ACTIVITY
		end

		local item = xyd.getItemIcon({
			show_has_num = true,
			scale = 0.5555555555555556,
			isShowSelected = false,
			uiRoot = self.awardGroup,
			itemID = awards[i][1],
			num = awards[i][2],
			dragScrollView = self.parent.scrollView,
			wndType = wndType
		})

		table.insert(self.items, item)
	end

	self.awardGroup:GetComponent(typeof(UILayout)):Reposition()
	self:refresh()
end

function SproutsAwardItem:refresh()
	if self.type == 1 then
		self.limit = AwardTable[1]:getHeight(self.id)
		self.canReqAward = self.limit <= self.point
		self.tipsLabel.text = __("ACTIVITY_SPROUTS_AWARDS_TITLE_COLORED", self.point, self.limit, self.canReqAward and "5e6996" or "cc0011")

		self.valueLabel:SetActive(false)
	else
		self.limit = AwardTable[2]:getPoint(self.id)
		self.canReqAward = self.limit <= self.point
		self.tipsLabel.text = __("ACTIVITY_SPROUTS_NEW_TEXT05", self.limit)
		self.valueLabel.text = "(" .. self.point .. "/" .. self.limit .. ")"

		self.valueLabel:SetActive(true)
	end

	if self.hasGotten then
		self.awardBtn:SetActive(false)
		self.awardImg:SetActive(true)
	else
		self.awardBtn:SetActive(true)
		self.awardImg:SetActive(false)

		if self.canReqAward then
			xyd.setEnabled(self.awardBtn, true)
		else
			xyd.setEnabled(self.awardBtn, false)
		end
	end

	for i = 1, #self.items do
		self.items[i]:setChoose(self.hasGotten)
	end
end

return SproutsPointAwardWindow
