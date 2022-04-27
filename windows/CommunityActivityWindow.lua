local BaseWindow = import(".BaseWindow")
local CommunityActivityWindow = class("CommunityActivityWindow", BaseWindow)
local CommunityActivityItem = class("CommunityActivityItem")
local CommunityIconItem = class("CommunityIconItem")
local CommunityTable = xyd.tables.communityTable

function CommunityActivityWindow:ctor(name, params)
	CommunityActivityWindow.super.ctor(self, name, params)

	self.actInfo = xyd.models.community:getActInfo()
end

function CommunityActivityWindow:initWindow()
	self:getUIComponent()
	CommunityActivityWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function CommunityActivityWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:ComponentByName("groupAction", typeof(UIWidget))
	self.bg = self.groupAction:NodeByName("bg").gameObject
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	local contentGroup = self.groupAction:NodeByName("contentGroup").gameObject
	self.scroller = contentGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.groupItem = self.scroller:NodeByName("groupItem").gameObject
	local bottomGroup = self.groupAction:NodeByName("bottomGroup").gameObject
	self.labelJump = bottomGroup:ComponentByName("labelJump", typeof(UILabel))
	self.groupIcon = bottomGroup:NodeByName("groupIcon").gameObject
	self.activityItem = winTrans:NodeByName("activityItem").gameObject
	self.iconItem = winTrans:NodeByName("iconItem").gameObject
end

function CommunityActivityWindow:initUIComponent()
	self.labelTitle.text = __("SETTING_UP_TAP_4")
	self.labelJump.text = __("SNS_ACTIVITY_TEXT01")

	for i = 1, #self.actInfo do
		if xyd.models.community:checkDataLegal(self.actInfo[i]) then
			local tempGo = NGUITools.AddChild(self.groupItem, self.activityItem)
			local item = CommunityActivityItem.new(tempGo, self)

			item:setInfo(self.actInfo[i])
		end
	end

	if #self.actInfo == 1 then
		self.groupAction.height = 407
		self.bg:GetComponent(typeof(UnityEngine.BoxCollider)).size = Vector3(680, 407, 0)
	else
		self.scroller:ResetPosition()
	end

	local ids = CommunityTable:getIds()

	for i = 1, #ids do
		local tempGo = NGUITools.AddChild(self.groupIcon, self.iconItem)
		local item = CommunityIconItem.new(tempGo)

		item:setInfo(ids[i])
	end
end

function CommunityActivityWindow:register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end
end

function CommunityActivityItem:ctor(go, parent)
	self.go = go
	self.bg = go:ComponentByName("bg", typeof(UITexture))
	self.redMark = go:NodeByName("redMark").gameObject
	self.labelTime = go:ComponentByName("labelTime", typeof(UILabel))
	self.labelName = go:ComponentByName("labelName", typeof(UILabel))

	xyd.setDragScrollView(go, parent.scroller)
end

function CommunityActivityItem:setInfo(data)
	self.data = data

	xyd.setTextureByURL(self.data.banner_url, self.bg)

	self.labelTime.text = xyd.getDisplayTime(self.data.start_time, xyd.TimestampStrType.DATE) .. " - " .. xyd.getDisplayTime(self.data.end_time, xyd.TimestampStrType.DATE) .. __("SNS_ACTIVITY_TEXT03")
	self.labelName.text = self.data.title
	local timeStamp = xyd.db.misc:getValue("community_act_time_stamp" .. tostring(self.data.title) .. tostring(self.data.start_time) .. tostring(self.data.end_time) .. tostring(self.data.id))

	if not timeStamp then
		self.redMark:SetActive(true)
	else
		self.redMark:SetActive(false)
	end

	UIEventListener.Get(self.go).onClick = function ()
		xyd.db.misc:setValue({
			value = 1,
			key = "community_act_time_stamp" .. tostring(self.data.title) .. tostring(self.data.start_time) .. tostring(self.data.end_time) .. tostring(self.data.id)
		})
		xyd.models.community:checkRedMark()
		self.redMark:SetActive(false)

		local params = {
			content = self.data.content,
			link = self.data.url
		}

		xyd.WindowManager:get():openWindow("community_activity_detail_window", params)

		local msg = messages_pb.log_partner_data_touch_req()
		msg.touch_id = xyd.DaDian.COMMUNITY_ACTIVITY

		xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
	end
end

function CommunityIconItem:ctor(go)
	self.go = go
	self.icon = go:ComponentByName("icon", typeof(UISprite))
end

function CommunityIconItem:setInfo(id)
	local img = CommunityTable:getIcon(id)
	local link = CommunityTable:getLink(id)

	xyd.setUISpriteAsync(self.icon, nil, img)

	UIEventListener.Get(self.go).onClick = function ()
		UnityEngine.Application.OpenURL(link)
	end
end

return CommunityActivityWindow
