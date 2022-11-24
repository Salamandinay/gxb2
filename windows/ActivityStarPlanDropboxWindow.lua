local ActivityStarPlanDropboxWindow = class("ActivityStarPlanDropboxWindow", import(".BaseWindow"))
local CommonTabBar = import("app.common.ui.CommonTabBar")

function ActivityStarPlanDropboxWindow:ctor(name, params)
	ActivityStarPlanDropboxWindow.super.ctor(self, name, params)
end

function ActivityStarPlanDropboxWindow:initWindow()
	ActivityStarPlanDropboxWindow.super.initWindow(self)
	self:getUIComponent()
	self:updateLayout()
end

function ActivityStarPlanDropboxWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.scrollView_ = winTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.labelTips1_ = winTrans:ComponentByName("scrollView/labelTips1", typeof(UILabel))
	self.labelTips2_ = winTrans:ComponentByName("scrollView/labelTips2", typeof(UILabel))
	self.itemGrid1_ = winTrans:ComponentByName("scrollView/itemGrid1", typeof(UIGrid))
	self.itemGrid2_ = winTrans:ComponentByName("scrollView/itemGrid2", typeof(UIGrid))
	self.itemRoot_ = winTrans:NodeByName("itemRoot").gameObject
	self.labelTips1_.text = __("ACTIVITY_STAR_PLAN_PREVIEW_TEXT01")

	if xyd.Global.lang == "ja_jp" then
		self.labelTips1_.width = 300
	end

	if xyd.Global.lang == "de_de" then
		self.labelTips2_.fontSize = 22
	end

	if xyd.Global.lang == "fr_fr" then
		self.labelTips1_.width = 300
		self.labelTips2_.height = 40
	end

	self.labelTips2_.text = __("ACTIVITY_STAR_PLAN_PREVIEW_TEXT02")
	self.titleLabel_.text = __("ACTIVITY_STAR_PLAN_PREVIEW_TEXT03")

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end
end

function ActivityStarPlanDropboxWindow:updateLayout()
	local dropboxID = tonumber(xyd.split(xyd.tables.miscTable:getVal("activity_star_plan_dropbox"), "|")[2])

	NGUITools.DestroyChildren(self.itemGrid1_.transform)
	NGUITools.DestroyChildren(self.itemGrid2_.transform)

	local boxInfo = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_STAR_PLAN):getBoxInfo()
	local awards = {}
	local totalNum = 0

	for id, num in pairs(boxInfo) do
		local itemID = xyd.tables.activityStarPlanGambleTable:getAwards(tonumber(id))[1]

		table.insert(awards, {
			itemID,
			num
		})

		totalNum = totalNum + num
	end

	for index, award in ipairs(awards) do
		local newRoot = NGUITools.AddChild(self.itemGrid1_.gameObject, self.itemRoot_)
		local labelRate = newRoot:ComponentByName("labelRate", typeof(UILabel))

		labelRate.gameObject:SetActive(true)
		xyd.getItemIcon({
			scale = 1,
			uiRoot = newRoot,
			itemID = award[1],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			dragScrollView = self.scrollView_
		})

		labelRate.text = math.floor(award[2] / totalNum * 10000) / 100 .. "%"
	end

	self:waitForFrame(1, function ()
		self.itemGrid1_:Reposition()
	end)

	local info = xyd.tables.dropboxShowTable:getIdsByBoxId(dropboxID)
	local all_proba = info.all_weight
	local list = info.list
	local sort_func = nil

	if self.params then
		sort_func = self.params.sort_func
	end

	xyd.tables.dropboxShowTable:sort(list, sort_func)

	local collect = {}

	for i = 1, #list do
		local table_id = list[i]
		local weight = xyd.tables.dropboxShowTable:getWeight(table_id)

		if weight then
			table.insert(collect, {
				table_id = table_id,
				all_proba = all_proba
			})
		end
	end

	for index, item in ipairs(collect) do
		local newRoot = NGUITools.AddChild(self.itemGrid2_.gameObject, self.itemRoot_)

		newRoot:SetActive(true)

		local data = xyd.tables.dropboxShowTable:getItem(item.table_id)

		xyd.getItemIcon({
			scale = 0.7962962962962963,
			uiRoot = newRoot,
			itemID = data[1],
			num = data[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			dragScrollView = self.scrollView_
		})
	end

	self:waitForFrame(1, function ()
		self.itemGrid2_:Reposition()
		self.scrollView_:ResetPosition()
	end)
end

return ActivityStarPlanDropboxWindow
