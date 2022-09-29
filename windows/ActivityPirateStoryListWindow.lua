local BaseWindow = import(".BaseWindow")
local ActivityPirateStoryListWindow = class("ActivityPirateStoryListWindow", BaseWindow)
local cjson = require("cjson")

function ActivityPirateStoryListWindow:ctor(name, params)
	ActivityPirateStoryListWindow.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_PIRATE)
	self.itemList_ = {}
end

function ActivityPirateStoryListWindow:initWindow()
	self:getUIComponent()
end

function ActivityPirateStoryListWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	local itemGroup = winTrans:NodeByName("itemGroup")

	for i = 1, 11 do
		local itemRoot = itemGroup:NodeByName("storyItem" .. i).gameObject
		local img = itemRoot:GetComponent(typeof(UISprite))
		local story_id = xyd.tables.activityPiratePlotListTable:getIdByPlace(i)
		local showGroup = itemRoot:NodeByName("showGroup").gameObject

		if self:checkFinish(story_id) then
			local type = xyd.tables.activityPiratePlotListTable:getMapType(story_id)

			if type == 0 then
				type = 1
			end

			xyd.setUISpriteAsync(img, nil, "activity_pirate_story_item_bg" .. type, nil, , true)
			showGroup:SetActive(true)

			local titleLabel = showGroup:ComponentByName("titleLabel", typeof(UILabel))
			local placeLabel = showGroup:ComponentByName("placeLabel", typeof(UILabel))
			titleLabel.text = xyd.tables.activityPiratePlotListTextTable:getTitle(story_id)
			placeLabel.text = __("ACTIVITY_PIRATE_PLACE" .. type)
		else
			xyd.setUISpriteAsync(img, nil, "activity_pirate_story_item_bg0", nil, , true)
			showGroup:SetActive(false)
		end

		local text_type = xyd.tables.activityPiratePlotListTable:getTextType(story_id)

		UIEventListener.Get(itemRoot).onClick = function ()
			self:onClickStory(story_id, text_type)
		end
	end

	self.titleLabel_.text = __("ACTIVITY_PIRATE_TEXT07")

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end
end

function ActivityPirateStoryListWindow:checkFinish(story_id)
	if story_id <= 0 then
		return true
	end

	return xyd.arrayIndexOf(self.activityData.detail.story_ids, story_id) > 0
end

function ActivityPirateStoryListWindow:onClickStory(id, text_type)
	if not self:checkFinish(id) then
		return
	end

	if text_type == 1 then
		local start_id = xyd.tables.activityPiratePlotListTable:getPlotIdById(id)

		xyd.WindowManager.get():openWindow("story_window", {
			story_type = xyd.StoryType.ACTIVITY_PIRATE,
			story_id = start_id,
			callback = function ()
				local params = cjson.encode({
					type = 0,
					story_id = tonumber(id)
				})

				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_PIRATE, params)
			end
		})
	else
		xyd.WindowManager.get():openWindow("activity_pirate_story_window", {
			story_id = id
		})
	end
end

return ActivityPirateStoryListWindow
