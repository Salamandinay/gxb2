local BaseWindow = import(".BaseWindow")
local NewPartnerWarmupPreviewWindow = class("NewPartnerWarmupPreviewWindow", BaseWindow)
local activityID = xyd.ActivityID.NEW_PARTNER_WARMUP

function NewPartnerWarmupPreviewWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(activityID)
end

function NewPartnerWarmupPreviewWindow:initWindow()
	self:getUIComponent()
	NewPartnerWarmupPreviewWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function NewPartnerWarmupPreviewWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	local groupMain = groupAction:NodeByName("groupMain").gameObject
	self.groupItem = groupMain:NodeByName("groupItem").gameObject
	self.item = groupMain:NodeByName("item").gameObject
end

function NewPartnerWarmupPreviewWindow:initUIComponent()
	self.labelTitle.text = __("PARTNER_WARMUP_TEXT01")

	for i = 1, 3 do
		local go = NGUITools.AddChild(self.groupItem, self.item)
		local labelDesc = go:ComponentByName("labelDesc", typeof(UILabel))
		local groupIcon = go:NodeByName("groupIcon").gameObject
		labelDesc.text = __("PARTNER_WARMUP_TEXT02", i)
		local awards = xyd.tables.newPartnerWarmUpStageTable:getReward(i)

		for _, award in ipairs(awards) do
			local icon = xyd.getItemIcon({
				show_has_num = true,
				showGetWays = false,
				scale = 0.7037037037037037,
				notShowGetWayBtn = true,
				itemID = award[1],
				num = award[2],
				uiRoot = groupIcon.gameObject,
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})

			if i < self.activityData.detail.current_stage or self.activityData.detail.current_stage == -1 then
				icon:setChoose(true)
			end
		end

		groupIcon:GetComponent(typeof(UILayout)):Reposition()
	end
end

return NewPartnerWarmupPreviewWindow
