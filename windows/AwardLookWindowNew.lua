local AwardLookWindowNew = class("AwardLookWindowNew", import(".BaseWindow"))
local ActivityChristmasSaleShowTable = xyd.tables.activityChristmasSaleShowTable

function AwardLookWindowNew:ctor(name, params)
	AwardLookWindowNew.super.ctor(self, name, params)
end

function AwardLookWindowNew:initWindow()
	AwardLookWindowNew.super.initWindow(self)
	self:getComponent()
	self:layout()
end

function AwardLookWindowNew:getComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.title = groupAction:ComponentByName("title", typeof(UILabel))
	self.closeBtn_ = groupAction:NodeByName("closeBtn").gameObject
	local itemGroup = groupAction:NodeByName("itemGroup").gameObject
	self.label = itemGroup:ComponentByName("label", typeof(UILabel))
	self.iconGroup = itemGroup:NodeByName("iconGroup").gameObject
	self.icon_root = itemGroup:NodeByName("icon_root").gameObject
end

function AwardLookWindowNew:layout()
	self.title.text = __("AWARD_LOOK_WINDOW_NEW")
	self.label.text = __("ACTIVITY_CHRISTMAS_SALE_AWARD_PREVIEW")

	if xyd.Global.lang == "ja_jp" then
		self.label.fontSize = 20
	end

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	local ids = ActivityChristmasSaleShowTable:getIds()

	for i = 1, #ids do
		local item = NGUITools.AddChild(self.iconGroup, self.icon_root)
		local id = ids[i]
		local new = item:NodeByName("new").gameObject
		local award = ActivityChristmasSaleShowTable:getAwards(id)

		new:SetActive(ActivityChristmasSaleShowTable:getIsNew(id))
		xyd.getItemIcon({
			show_has_num = true,
			wndType = 5,
			scale = 0.75,
			itemID = tonumber(award[1]),
			num = tonumber(award[2]),
			uiRoot = item
		})
	end

	self.iconGroup:GetComponent(typeof(UIGrid)):Reposition()
end

return AwardLookWindowNew
