local BaseWindow = import("app.windows.BaseWindow")
local IceSummerAwardWindow = class("IceSummerAwardWindow", BaseWindow)

function IceSummerAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function IceSummerAwardWindow:initWindow()
	IceSummerAwardWindow.super:initWindow()

	local winTrans = self.window_.transform
	self.iconGroup1 = winTrans:NodeByName("groupAction/itemGroup1/iconGroup").gameObject
	self.iconGroup2 = winTrans:NodeByName("groupAction/itemGroup2/iconGroup").gameObject
	self.layout1 = self.iconGroup1:GetComponent(typeof(UILayout))
	self.layout2 = self.iconGroup2:GetComponent(typeof(UILayout))
	self.label1 = winTrans:ComponentByName("groupAction/itemGroup1/label", typeof(UILabel))
	self.label2 = winTrans:ComponentByName("groupAction/itemGroup2/label", typeof(UILabel))
	self.btn = winTrans:NodeByName("groupAction/closeBtn").gameObject
	self.title = winTrans:ComponentByName("groupAction/title", typeof(UILabel))

	self:layout()
	self:RegisterEvent()
end

function IceSummerAwardWindow:RegisterEvent()
	UIEventListener.Get(self.btn).onClick = function ()
		xyd.WindowManager:get():closeWindow(self.name_)
	end
end

function IceSummerAwardWindow:layout()
	self.title.text = __("ACTIVITY_AWARD_PREVIEW_TITLE")
	self.label1.text = __("ACTIVITY_ICE_SUMMER_AWARD1")
	self.label2.text = __("ACTIVITY_ICE_SUMMER_AWARD2")
	local ids = xyd.tables.activityIceSummerCostTable:getIDs()

	for id in ipairs(ids) do
		local data = xyd.tables.activityIceSummerCostTable:getAward(id)
		local item = {
			show_has_num = true,
			itemID = data[1],
			num = data[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			uiRoot = self.iconGroup1,
			scale = Vector3(0.6, 0.6, 1)
		}
		local icon = xyd.getItemIcon(item)
	end

	ids = xyd.tables.activityIceSummerStoryTable:getIDs()

	for id = #ids, 1, -1 do
		local data = xyd.tables.activityIceSummerStoryTable:getAward(id)

		for i = 1, #data do
			local item = {
				show_has_num = true,
				itemID = data[i][1],
				num = data[i][2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				uiRoot = self.iconGroup2,
				scale = Vector3(0.6, 0.6, 1)
			}
			local icon = xyd.getItemIcon(item)
		end
	end

	XYDCo.WaitForFrame(1, function ()
		self.layout1:Reposition()
		self.layout2:Reposition()
	end, nil)
end

return IceSummerAwardWindow
