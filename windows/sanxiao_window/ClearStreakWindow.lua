local ClearStreakWindow = class("ClearStreakWindow", import(".BaseWindow"))
local MappingData = xyd.MappingData

function ClearStreakWindow:ctor(name, params)
	ClearStreakWindow.super.ctor(self, name, params)

	self.tws = {}
	self.bitmapViews = {}
	self.groupViews = {}
	self.from = "game"
	self.model = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITY)

	if params and params.from then
		self.from = params.from
	end

	if params and params.onComplete then
		self.callBack = params.onComplete
	end

	self.reward_items = {
		{
			1001
		},
		{
			1001,
			1006
		},
		{
			1001,
			1006,
			1010
		}
	}
	self.rewardLevel = #self.reward_items
end

function ClearStreakWindow:initWindow()
	self:getUIComponents()
	self:initUIComponent()
	self:initTimer()
	self:timerCallback()
end

function ClearStreakWindow:getUIComponents()
	local winTrans = self.window_.transform
	self.asyncData = {
		bg = "bg_zi_streak",
		cat = "other_cat_streak",
		clock_di = "bg_time_streak",
		btn_di = "bg_di_steak",
		star = "bg_streak_xingxing",
		title = "title_streak",
		hairball = "other_maoqiu_streak",
		banner = "bg_title_streak",
		clock = "shijian_icon_streak",
		cat_stack = "item_cat_tree_streak",
		cat_stack1 = "item_cat_tree1_streak",
		close_btn = "bg_guanbi_streak"
	}
	self.group_all = winTrans:NodeByName("e:Skin/group_all").gameObject
	self.pic_group = winTrans:NodeByName("e:Skin/group_all/pic_group").gameObject
	self.pattern_group = winTrans:NodeByName("e:Skin/group_all/pattern_group").gameObject
	self.ok_btn = winTrans:NodeByName("e:Skin/group_all/ok_btn").gameObject
	self.item_group = winTrans:NodeByName("e:Skin/group_all/item_group").gameObject
	self.time_group = winTrans:NodeByName("e:Skin/group_all/time_group").gameObject
	self.close_btn = winTrans:ComponentByName("e:Skin/group_all/close_btn", typeof(UISprite))
	self.banner = winTrans:ComponentByName("e:Skin/group_all/banner", typeof(UISprite))
	self.bg = winTrans:ComponentByName("e:Skin/group_all/bg", typeof(UISprite))
	self.title = winTrans:ComponentByName("e:Skin/group_all/title", typeof(UISprite))
	self.cat_stack = winTrans:ComponentByName("e:Skin/group_all/pic_group/cat_stack", typeof(UISprite))
	self.cat_stack1 = winTrans:ComponentByName("e:Skin/group_all/pic_group/cat_stack1", typeof(UISprite))
	self.cat = winTrans:ComponentByName("e:Skin/group_all/pic_group/cat", typeof(UISprite))
	self.hairball = winTrans:ComponentByName("e:Skin/group_all/pic_group/hairball", typeof(UISprite))
	self.star = winTrans:ComponentByName("e:Skin/group_all/pic_group/star", typeof(UISprite))
	self.btn_di = winTrans:ComponentByName("e:Skin/group_all/ok_btn/btn_di", typeof(UISprite))
	self.clock = winTrans:ComponentByName("e:Skin/group_all/time_group/clock", typeof(UISprite))
	self.clock_di = winTrans:ComponentByName("e:Skin/group_all/time_group/clock_di", typeof(UISprite))
	self.clock = winTrans:ComponentByName("e:Skin/group_all/time_group/clock", typeof(UISprite))
	self.time = winTrans:ComponentByName("e:Skin/group_all/time_group/time", typeof(UILabel))

	self:initAsyncData()
end

function ClearStreakWindow:initAsyncData()
	local winTrans = self.window_.transform

	for k, v in pairs(self.asyncData) do
		xyd.setUISpriteAsync(self[k], MappingData[v], v)
	end

	for i = 1, 5 do
		winTrans:ComponentByName("e:Skin/group_all/text_group/label_" .. tostring(i), typeof(UILabel)).text = __("CONTINUED_VITORY_TIPS" .. tostring(i))
	end

	winTrans:ComponentByName("e:Skin/group_all/ok_btn/start_btn_text", typeof(UILabel)).text = __("START_GAME")
	self.pattern = {}

	for i = 1, 4 do
		local pic = winTrans:ComponentByName("e:Skin/group_all/pattern_group/pattern" .. tostring(i), typeof(UISprite))

		xyd.setUISpriteAsync(pic, MappingData.bg_huawen_streak, "bg_huawen_streak")
	end

	self.bubble = {}

	for i = 1, 3 do
		self.bubble[i] = {}

		for j = 1, i do
			self.bubble[i][j] = winTrans:ComponentByName("e:Skin/group_all/item_group/item" .. tostring(i) .. "_" .. tostring(j), typeof(UISprite))

			xyd.setUISpriteAsync(self.bubble[i][j], MappingData.other_qipao_streak, "other_qipao_streak")
		end
	end
end

function ClearStreakWindow:initUIComponent()
	self:showReward()
	xyd.setNormalBtnBehavior(self.ok_btn, self, self.onOkBtnClick)
	xyd.setNormalBtnBehavior(self.close_btn.gameObject, self, self.onCloseBtn)
	self:setDefaultBgClick(function ()
		self:onCloseBtn()
	end)
end

function ClearStreakWindow:showReward()
	for i = 1, self.rewardLevel do
		for j = 1, #self.reward_items[i] do
			local group = self:createOne(i, j)
		end
	end
end

function ClearStreakWindow:createOne(level, count)
	local ViewFactory = xyd.ViewFactory.get()
	local itemView = ViewFactory:create(self.bubble[level][count].gameObject, -1)

	table.insert(self.bitmapViews, itemView)
	itemView:setProp(0, 0, xyd.DisplayConstants.ItemSourceMap[self.reward_items[level][count]], self.bubble[level][count].depth + 1)
end

function ClearStreakWindow:disableBtns()
	self.ok_btn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	self.close_btn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

	self:setDefaultBgClick(nil)
end

function ClearStreakWindow:onCloseBtn()
	self:disableBtns()

	if self.from == "game" then
		self:close(self.callBack)
	else
		self:close()
	end
end

function ClearStreakWindow:onOkBtnClick()
	self:disableBtns()
	self:close(self.callBack)
end

function ClearStreakWindow:timerCallback()
	local time_left = self.end_time - os.time()

	if time_left < 0 then
		self:onCloseBtn()
	end

	self.time.text = xyd.secondsNoDayToTimeString(time_left)
end

function ClearStreakWindow:initTimer()
	self.end_time = self.model:getData(xyd.ActivityConstants.CLEAR_STREAK_REWARD).close_time
	self.timer = Timer.New(handler(self, self.timerCallback), 1, -1, false)

	self.timer:Start()
end

function ClearStreakWindow:dispose()
	for _, sequence in ipairs(self.tws) do
		sequence:Kill()
	end

	self.tws = {}

	for _, obj in ipairs(self.bitmapViews) do
		obj:dispose()
	end

	self.bitmapViews = {}

	for _, group in ipairs(self.groupViews) do
		xyd.ViewResManager.get():pushView(group, "group")
	end

	self.groupViews = {}

	if self.timer then
		self.timer:Stop()

		self.timer = nil
	end

	ClearStreakWindow.super.dispose(self)
end

return ClearStreakWindow
