local BaseWindow = import(".BaseWindow")
local CommonPreviewWithChangeWindow = class("CommonPreviewWithChangeWindow", BaseWindow)
local ProbabilityRender = class("ProbabilityRender", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local DropboxShowTable = xyd.tables.dropboxShowTable

function CommonPreviewWithChangeWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.params = params
	self.collect_ = {}
	self.box_id = params.box_id
	self.title = params.title
end

function CommonPreviewWithChangeWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.labelTitle = winTrans:ComponentByName("groupAction/labelTitle", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("groupAction/closeBtn").gameObject
	self.dropItem = winTrans:NodeByName("dropItem").gameObject
	self.scroller = winTrans:ComponentByName("groupAction/scroller", typeof(UIScrollView))
	self.itemGroup = winTrans:NodeByName("groupAction/scroller/itemGroup").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scroller, wrapContent, self.dropItem, ProbabilityRender, self)
end

function CommonPreviewWithChangeWindow:initWindow()
	CommonPreviewWithChangeWindow.super.initWindow(self)
	self:getUIComponent()
	self:initLayOut()
	self:register()
end

function CommonPreviewWithChangeWindow:initLayOut()
	self.labelTitle.text = self.title

	self:updateLayout()
end

function CommonPreviewWithChangeWindow:updateLayout()
	local info = DropboxShowTable:getIdsByBoxId(self.box_id)
	local all_proba = info.all_weight
	local list = info.list
	local sort_func = nil

	if self.params then
		sort_func = self.params.sort_func
	end

	DropboxShowTable:sort(list, sort_func)

	local collect = {}

	for i = 1, #list do
		local table_id = list[i]
		local weight = DropboxShowTable:getWeight(table_id)

		if weight then
			table.insert(collect, {
				table_id = table_id,
				all_proba = all_proba
			})
		end
	end

	self.collect_ = collect

	self.wrapContent:setInfos(self.collect_, {})
end

function ProbabilityRender:ctor(go, parent)
	ProbabilityRender.super.ctor(self, go, parent)
end

function ProbabilityRender:initUI()
	local go = self.go
	self.imgBg = go:ComponentByName("imgBg", typeof(UISprite))
	self.groupIcon = go:NodeByName("groupIcon").gameObject
	self.label = go:ComponentByName("label", typeof(UILabel))
end

function ProbabilityRender:updateInfo()
	self.table_id_ = self.data.table_id
	self.all_proba_ = self.data.all_proba
	local data = DropboxShowTable:getItem(self.table_id_)
	self.itemID = data[1]
	self.num = data[2]
	local proba = DropboxShowTable:getWeight(self.table_id_)
	local show_proba = math.ceil(proba * 1000000 / self.all_proba_)
	show_proba = show_proba / 10000
	self.label.text = tostring(show_proba) .. "%"
	local params = {
		noWays = true,
		scale = 1.1,
		uiRoot = self.groupIcon,
		itemID = self.itemID,
		num = self.num,
		dragScrollView = self.parent.scroller
	}

	if not self.icon then
		self.icon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
	end

	self.icon:setInfo(params)
end

return CommonPreviewWithChangeWindow
