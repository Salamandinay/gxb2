local ActivityFairyTaleSelectionWindow = class("ActivityFairyTaleSelectionWindow", import(".BaseWindow"))
local ActivityFairyTaleSelectionItem = class("ActivityFairyTaleSelectionItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local json = require("cjson")

function ActivityFairyTaleSelectionWindow:ctor(name, params)
	ActivityFairyTaleSelectionWindow.super.ctor(self, name, params)

	self.id = params.id
	self.eventId = params.eventId
	self.cell_id = params.cell_id
	self.selectIndex_ = -1
	self.selectId = -1
end

function ActivityFairyTaleSelectionWindow:initWindow()
	ActivityFairyTaleSelectionWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function ActivityFairyTaleSelectionWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction")
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	local contentGroup = groupAction:NodeByName("contentGroup").gameObject
	self.problemLable = contentGroup:ComponentByName("problemLable", typeof(UILabel))
	self.scrollView = contentGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = contentGroup:NodeByName("scroller/itemGroup").gameObject
	self.selectItem = contentGroup:NodeByName("scroller/activity_fairy_tale_selection_item").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.selectItem, ActivityFairyTaleSelectionItem, self)
	self.nextBtn = contentGroup:NodeByName("nextBtn").gameObject
end

function ActivityFairyTaleSelectionWindow:register()
	ActivityFairyTaleSelectionWindow.super.register(self)

	UIEventListener.Get(self.nextBtn).onClick = function ()
		if self.selectIndex_ < 0 then
			xyd.showToast(__("QUESTIONNAIRE_NO_SELECT"))
		else
			local msg = messages_pb.fairy_challenge_req()
			msg.activity_id = xyd.ActivityID.FAIRY_TALE
			msg.cell_id = self.cell_id
			local params = {
				select_index = self.selectIndex_
			}
			msg.params = json.encode(params)

			xyd.Backend.get():request(xyd.mid.FAIRY_CHALLENGE, msg)
		end
	end

	self.eventProxy_:addEventListener(xyd.event.ERROR_MESSAGE, handler(self, self.onError))
	self.eventProxy_:addEventListener(xyd.event.FAIRY_CHALLENGE, handler(self, self.onAward))
end

function ActivityFairyTaleSelectionWindow:initUIComponent()
	self.nextBtn:ComponentByName("button_label", typeof(UILabel)).text = __("SURE")
	self.labelTitle.text = __("FAIRY_TALE_SELECT_TITLE")
	local list = {}
	local temp_list = xyd.tables.activityFairyTaleOptionTable:getDecisionId(self.id)[self.eventId]
	self.problemLable.text = xyd.tables.activityFairyTaleOptionTextTable:getDes(math.floor(temp_list[1] / 1000))

	for i = 1, #temp_list do
		local params = {
			id = temp_list[i],
			index = i
		}

		table.insert(list, params)
	end

	self.wrapContent:setInfos(list, {})
	self:waitForFrame(1, function ()
		self.scrollView:ResetPosition()
	end)
end

function ActivityFairyTaleSelectionWindow:onError(event)
	local errorCode = event.data.error_code

	if tonumber(errorCode) == 6047 then
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function ActivityFairyTaleSelectionWindow:onAward(event)
	if event.data.is_video then
		return
	end

	local cellType = xyd.tables.activityFairyTaleCellTable:getCellType(event.data.info.table_id)

	if cellType ~= 4 then
		return
	end

	local items = event.data.items
	local des = xyd.tables.activityFairyTaleAward3TextTable:getResult(self.selectId)

	xyd.alertItems(items, nil, , des)
	xyd.WindowManager.get():closeWindow(self.name_)
end

function ActivityFairyTaleSelectionItem:ctor(go, parent)
	ActivityFairyTaleSelectionItem.super.ctor(self, go, parent)
end

function ActivityFairyTaleSelectionItem:initUI()
	local cotentGroup = self.go:NodeByName("cotentGroup").gameObject
	self.descLabel = cotentGroup:ComponentByName("descLabel", typeof(UILabel))
	self.defaultNode = cotentGroup:NodeByName("selectGroup/default").gameObject
	self.selectNode = cotentGroup:NodeByName("selectGroup/select").gameObject
	self.touchGroup = cotentGroup:NodeByName("touchGroup").gameObject
	UIEventListener.Get(self.touchGroup).onClick = handler(self, self.onSelect)
end

function ActivityFairyTaleSelectionItem:updateInfo()
	self.id = self.data.id
	self.index = self.data.index
	self.descLabel.text = xyd.tables.activityFairyTaleAward3TextTable:getDes(self.id)

	if self.parent.selectIndex_ > 0 and self.parent.selectIndex_ == self.index then
		self.selectNode:SetActive(true)
	else
		self.selectNode:SetActive(false)
	end
end

function ActivityFairyTaleSelectionItem:onSelect()
	if self.parent.selectIndex_ > 0 and self.parent.selectIndex_ == self.index then
		self.selectNode:SetActive(false)

		self.parent.selectIndex_ = -1
		self.parent.selectId = -1
		self.parent.selectedItem = nil
	else
		self.selectNode:SetActive(true)

		if self.parent.selectedItem then
			self.parent.selectedItem:SetActive(false)
		end

		self.parent.selectIndex_ = self.index
		self.parent.selectId = self.id
		self.parent.selectedItem = self.selectNode
	end
end

return ActivityFairyTaleSelectionWindow
