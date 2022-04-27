local Input = UnityEngine.Input
local ItemConstants = xyd.ItemConstants
local ElementTypeConstants = xyd.ElementTypeConstants
local AddChild = NGUITools.AddChild
local RocketConstants = xyd.RocketConstants
local GameWindowConstants = xyd.GameWindowConstants
local EffectConstants = xyd.EffectConstants
local SelfInfo = xyd.SelfInfo
local Point = import("app.common.Point")
local SwapInfo = import("app.game.board.swaps.SwapInfo")
local IngameItemManager = import("app.game.item.ingameitem.IngameItemManager")
local MappingData = xyd.MappingData
local GuideHelper = xyd.GuideHelper
local Sticker = import("app.game.item.ingameitem.Sticker")
local Guide = import("app.components.Guide")
local DBResManager = xyd.DBResManager
local SpineManager = xyd.SpineManager
local Destroy = UnityEngine.Object.Destroy
local GameWindow = class("GameWindow", import(".BaseWindow"))
GameWindow.INGAME_ITEM_NUM = 4

function GameWindow:ctor(name, params)
	GameWindow.super.ctor(self, name, params)

	self.params = params
	self._board = params.board
	self._gameView = params.view
	self._isDirectly = params.isDirectly
end

function GameWindow:initMembers()
	self.BOARD_MAX_WIDTH = 1062
	self.BOARD_MAX_HEIGHT = 1116
	self.BOARD_ELE_WIDTH = 118
	self.BOARD_ELE_HEIGHT = 124
	self.INGAME_ITEM_NUM = 4
	self.TOP_UI_HEIGHT = 270
	self.BOTTOM_UI_HEIGHT = 220
	self.MAX_BOARD_HEIGHT = 1160
	self.ITEM_GROUP_SCALE = 0.9
	self.ITEM_UNLOCK_STAGE = {
		[ItemConstants.HAMMER] = 8,
		[ItemConstants.SWAPPER] = 12,
		[ItemConstants.STICKER] = 14,
		[ItemConstants.WAND] = 9
	}
	self.ITEM_ICON_SOURCES = {
		"icon_chuizi",
		"icon_weizhijiaohuan",
		"icon_mobang",
		"icon_tiezhi"
	}
	self.canTouch = true
	self.itemCanTouch = true
	self._gameOver = false
	self.labelItemNum = {}
	self.item_reach_limit = {}
	self.time_limited_img = {}
	self.item_reach_limit_img = {}
	self.timer_group = {}
	self.expired_time_cache = {}
	self.timer_label = {}
	self._status = ItemConstants.NORMAL
	self._settingState = 0
	self._settingCanTouch = true
	self._boardScale = 1
	self.stick_choosed = 0
	self.stick_show = false
	self.bottomItemListMap = {}
	self._showItemHint = false
	self._showWandHint = false
	self._guangXiaoEffectGroup = {}
	self._isRequestingGameBuyItem = false
	self._isDirectly = false
	self._h5InGameWindows = {}
	self.hasTimerOnItem_1 = false
	self.hasTimerOnItem_2 = false
	self.hasTimerOnItem_3 = false
	self.hasTimerOnItem_4 = false
end

function GameWindow:initWindow()
	GameWindow.super.initWindow(self)

	if self.params.engineCallback then
		self.params.engineCallback()

		self.params.engineCallback = nil
	end

	self:initMembers()
	self:getUIComponent()
	self:initUIComponent()
	self:childrenCreated()
end

function GameWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.group_item0 = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item0").gameObject
	self.group_item1 = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item1").gameObject
	self.group_item2 = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item2").gameObject
	self.group_item3 = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item3").gameObject
	self.group_item3_col = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item3/group_item3_col").gameObject
	self.label_item3_col = self.group_item3_col.transform:ComponentByName("label_item3_col", typeof(UILabel))
	self.group_item3_row = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item3/group_item3_row").gameObject
	self.label_item3_row = self.group_item3_row.transform:ComponentByName("label_item3_row", typeof(UILabel))
	self.group_item3_col_bg = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item3/group_item3_col/group_item3_col_bg", typeof(UISprite))
	self.group_item3_row_bg = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item3/group_item3_row/group_item3_row_bg", typeof(UISprite))
	self.timer0_group = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item0/timer0_group").gameObject
	self.timer1_group = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item1/timer1_group").gameObject
	self.timer2_group = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item2/timer2_group").gameObject
	self.timer3_group = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item3/group_item3_normal/timer3_group").gameObject
	self.item0_reach_limit_img = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item0/item0_reach_limit_img").gameObject
	self.item1_reach_limit_img = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item1/item1_reach_limit_img").gameObject
	self.item2_reach_limit_img = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item2/item2_reach_limit_img").gameObject
	self.item3_reach_limit_img = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item3/group_item3_normal/item3_reach_limit_img").gameObject
	self.item_num_0 = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item0/item_num_group0/item_num_0", typeof(UILabel))
	self.item_num_1 = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item1/item_num_group1/item_num_1", typeof(UILabel))
	self.item_num_2 = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item2/item_num_group2/item_num_2", typeof(UILabel))
	self.item_num_3 = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item3/group_item3_normal/item_num_group3/item_num_3", typeof(UILabel))
	self.item_num_timer_0 = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item0/item_num_group0/item_num_timer_0", typeof(UILabel))
	self.item_num_timer_1 = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item1/item_num_group1/item_num_timer_1", typeof(UILabel))
	self.item_num_timer_2 = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item2/item_num_group2/item_num_timer_2", typeof(UILabel))
	self.item_num_timer_3 = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item3/group_item3_normal/item_num_group3/item_num_timer_3", typeof(UILabel))
	self.timer0_label = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item0/timer0_group/timer0_label", typeof(UILabel))
	self.timer1_label = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item1/timer1_group/timer1_label", typeof(UILabel))
	self.timer2_label = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item2/timer2_group/timer2_label", typeof(UILabel))
	self.timer3_label = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item3/group_item3_normal/timer3_group/timer3_label", typeof(UILabel))
	self.time_limited_img0 = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item0/item_num_group0/time_limited_img0", typeof(UISprite))
	self.time_limited_img1 = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item1/item_num_group1/time_limited_img1", typeof(UISprite))
	self.time_limited_img2 = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item2/item_num_group2/time_limited_img2", typeof(UISprite))
	self.time_limited_img3 = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item3/group_item3_normal/item_num_group3/time_limited_img3", typeof(UISprite))
	self.img_item0 = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item0/img_item0", typeof(UISprite))
	self.img_item1 = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item1/img_item1", typeof(UISprite))
	self.img_item2 = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item2/img_item2", typeof(UISprite))
	self.img_item3 = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item3/group_item3_normal/img_item3", typeof(UISprite))
	self.item_num_group0 = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item0/item_num_group0").gameObject
	self.item_num_group1 = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item1/item_num_group1").gameObject
	self.item_num_group2 = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item2/item_num_group2").gameObject
	self.item_num_group3 = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom/group_item3/group_item3_normal/item_num_group3").gameObject
	self.group_top = winTrans:NodeByName("e:Skin/group_top").gameObject
	self.group_bottom = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_bottom_fixed/group_bottom").gameObject
	self._settingBgGroup = winTrans:NodeByName("e:Skin/group_mask/group_fixed/_settingBgGroup").gameObject
	self.setting_btn = winTrans:NodeByName("e:Skin/group_mask/group_fixed/setting_group_fixed/setting_group/setting_btn").gameObject
	self.setting_btn_collider = self.setting_btn:GetComponent(typeof(UnityEngine.BoxCollider))
	self.group_sound_bg = winTrans:NodeByName("e:Skin/group_mask/group_fixed/setting_group_fixed/setting_group/group_sound_bg").gameObject
	self.group_sound_effect = winTrans:NodeByName("e:Skin/group_mask/group_fixed/setting_group_fixed/setting_group/group_sound_effect").gameObject
	self.group_question = winTrans:NodeByName("e:Skin/group_mask/group_fixed/setting_group_fixed/setting_group/group_question").gameObject
	self.group_exit = winTrans:NodeByName("e:Skin/group_mask/group_fixed/setting_group_fixed/setting_group/group_exit").gameObject
	self.setting_group = winTrans:NodeByName("e:Skin/group_mask/group_fixed/setting_group_fixed/setting_group").gameObject
	self.bg_shezhi = winTrans:NodeByName("e:Skin/group_mask/group_fixed/setting_group_fixed/setting_group/bg_shezhi").gameObject
	self.sound_eff_disable = winTrans:NodeByName("e:Skin/group_mask/group_fixed/setting_group_fixed/setting_group/group_sound_effect/sound_eff_disable").gameObject
	self.sound_bg_disable = winTrans:NodeByName("e:Skin/group_mask/group_fixed/setting_group_fixed/setting_group/group_sound_bg/sound_bg_disable").gameObject
	self.target_panel = winTrans:NodeByName("e:Skin/group_top/target_group_fixed/target_panel").gameObject
	self.group_target = winTrans:NodeByName("e:Skin/group_top/target_group_fixed/target_panel/group_target").gameObject
	self.stage_ = winTrans:ComponentByName("e:Skin/group_top/group_stage/stage_", typeof(UILabel))
	self.group_board = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_board").gameObject
	self.group_item_tip = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_item_tip_fixed/group_item_tip").gameObject
	self.item_img = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_item_tip_fixed/group_item_tip/item_img", typeof(UISprite))
	self.item_tip = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_item_tip_fixed/group_item_tip/e:Group/item_tip", typeof(UILabel))
	self.bg_bottom = winTrans:NodeByName("e:Skin/bg_bottom").gameObject
	self.group_skip = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_skip").gameObject
	self.label_skip = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_skip/label_skip", typeof(UILabel))
	self.group_step = winTrans:NodeByName("e:Skin/group_top/group_step").gameObject
	self.step_ = winTrans:ComponentByName("e:Skin/group_top/group_step/step_", typeof(UILabel))
	self._itemMask = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/_itemMask", typeof(UISprite))
	self.score_ = winTrans:ComponentByName("e:Skin/group_top/group_score/score_", typeof(UILabel))
	self.text_score_ = winTrans:ComponentByName("e:Skin/group_top/group_score/text_score_", typeof(UILabel))
	self.star_1 = winTrans:ComponentByName("e:Skin/group_top/group_star/star_group/star_1", typeof(UISprite))
	self.star_2 = winTrans:ComponentByName("e:Skin/group_top/group_star/star_group/star_2", typeof(UISprite))
	self.star_3 = winTrans:ComponentByName("e:Skin/group_top/group_star/star_group/star_3", typeof(UISprite))
	self.bar_ = winTrans:ComponentByName("e:Skin/group_top/group_star/score_bar_/GameObject", typeof(UISprite))
	self.score_bar_ = winTrans:ComponentByName("e:Skin/group_top/group_star/score_bar_", typeof(UIPanel))
	self.group_bg = winTrans:NodeByName("e:Skin/group_bg").gameObject
	self._bgImg = winTrans:ComponentByName("e:Skin/group_bg/_bgImg", typeof(UITexture))
	self.superMask = winTrans:NodeByName("e:Skin/group_mask/group_fixed/superMask").gameObject
	self.sound_bg_disable = self.group_sound_bg:NodeByName("sound_bg_disable").gameObject
	self.sound_eff_disable = self.group_sound_effect:NodeByName("sound_eff_disable").gameObject
	local musicOn = xyd.SoundManager.get():getIsMusicOn()

	if musicOn then
		self.sound_bg_disable:SetActive(false)
	else
		self.sound_bg_disable:SetActive(true)
	end

	local effOn = xyd.SoundManager.get():getIsSoundOn()

	if effOn then
		self.sound_eff_disable:SetActive(false)
	else
		self.sound_eff_disable:SetActive(true)
	end

	self.boardLayer = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_board/boardLayer").gameObject
	self.blockerLayer = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_board/boardLayer/blockerLayer").gameObject
	self.blockerTarget = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_board/boardLayer/blockerLayer/blockerLayerTarget", typeof(UITexture))
	self.elementLayer = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_board/boardLayer/elementPanel/elementLayer").gameObject
	self.elementTarget = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_board/boardLayer/elementPanel/elementLayer/elementLayerTarget", typeof(UITexture))
	self.leafLayer = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_board/boardLayer/leafLayer").gameObject
	self.maskLayer = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_board/boardLayer/maskLayer").gameObject
	self.effectLayer = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_board/boardLayer/effectPanel/effectLayer").gameObject
	self.effectTarget = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_board/boardLayer/effectPanel/effectLayer/effectLayerTarget", typeof(UITexture))
	self.lockLayer = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_board/boardLayer/lockLayer").gameObject
	self.lockTarget = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_board/boardLayer/lockLayer/lockLayerTarget", typeof(UITexture))
	self.beltLayer = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_board/boardLayer/beltLayer").gameObject
	self.beltTarget = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/group_board/boardLayer/beltLayer/beltLayerTarget", typeof(UITexture))
	self.bottomLayer = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_board/boardLayer/bottomLayer").gameObject
	self.debugLayer = winTrans:NodeByName("e:Skin/group_mask/group_fixed/group_board/boardLayer/debugLayer").gameObject
	self.guide_area = winTrans:NodeByName("e:Skin/group_mask/group_fixed/guide_area").gameObject
	self.group_gm = winTrans:NodeByName("e:Skin/group_top/group_gm").gameObject
	self.btn_confirm = winTrans:NodeByName("e:Skin/group_top/group_gm/btn_confirm").gameObject
	self.text_input = winTrans:ComponentByName("e:Skin/group_top/group_gm/text_input", typeof(UIInput))
	self.group_shuffle = winTrans:NodeByName("e:Skin/group_mask/group_fixed/top_panel/group_shuffle").gameObject
	self.group_mode1 = winTrans:NodeByName("e:Skin/group_mask/group_fixed/top_panel/group_mode1").gameObject
	self.group_mode2 = winTrans:NodeByName("e:Skin/group_mask/group_fixed/top_panel/group_mode2").gameObject
	self.group_mode3 = winTrans:NodeByName("e:Skin/group_mask/group_fixed/top_panel/group_mode3").gameObject
	self.group_mode4 = winTrans:NodeByName("e:Skin/group_mask/group_fixed/top_panel/group_mode4").gameObject
	self.charEffHolder1 = winTrans:NodeByName("e:Skin/group_mask/group_fixed/top_panel/group_mode1/charEffHolder1").gameObject
	self.charEffHolder2 = winTrans:NodeByName("e:Skin/group_mask/group_fixed/top_panel/group_mode2/charEffHolder2").gameObject
	self.charEffHolder3 = winTrans:NodeByName("e:Skin/group_mask/group_fixed/top_panel/group_mode3/charEffHolder3").gameObject
	self.charEffHolder4 = winTrans:NodeByName("e:Skin/group_mask/group_fixed/top_panel/group_mode4/charEffHolder4").gameObject
	self.mode1_bg = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/top_panel/group_mode1/mode1_bg", typeof(UISprite))
	self.mode2_bg = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/top_panel/group_mode2/mode2_bg", typeof(UISprite))
	self.mode3_bg = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/top_panel/group_mode3/mode3_bg", typeof(UISprite))
	self.mode4_bg = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/top_panel/group_mode4/mode4_bg", typeof(UISprite))
	self.group_start_target = winTrans:NodeByName("e:Skin/group_mask/group_fixed/top_panel/group_mode4/group_start_target").gameObject
	self.group_start_target_grid = self.group_start_target:GetComponent(typeof(UIGrid))
	self.swap_num_label = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/top_panel/group_mode1/swap_num_label", typeof(UILabel))
	self.score_num_label = winTrans:ComponentByName("e:Skin/group_mask/group_fixed/top_panel/group_mode1/score_num_label", typeof(UILabel))
	self.mode1_score1 = self.group_mode1.transform:ComponentByName("mode1_score1", typeof(UILabel))
	self.mode1_score2 = self.group_mode1.transform:ComponentByName("mode1_score2", typeof(UILabel))
	self.mode1_score3 = self.group_mode1.transform:ComponentByName("mode1_score3", typeof(UILabel))
	self.label_shuffle = self.group_shuffle.transform:ComponentByName("label", typeof(UILabel))
	self.label_mode2_tips1 = self.group_mode2.transform:ComponentByName("mode2_label1", typeof(UILabel))
	self.label_mode2_tips2 = self.group_mode2.transform:ComponentByName("mode2_label2", typeof(UILabel))
	self.label_mode3_tips1 = self.group_mode3.transform:ComponentByName("mode3_label1", typeof(UILabel))
	self.label_mode3_tips2 = self.group_mode3.transform:ComponentByName("mode3_label2", typeof(UILabel))
	self.label_mode4_tips = self.group_mode4.transform:ComponentByName("mode4_label1", typeof(UILabel))
	self.elementView = winTrans:NodeByName("elementview").gameObject
	self.elementMask = winTrans:NodeByName("elementmask").gameObject
	self.debugLabel = winTrans:NodeByName("debuglabel").gameObject
	self.game_target_display = winTrans:NodeByName("game_target_display").gameObject
	self.score_target_display = winTrans:NodeByName("score_target_display").gameObject
	self.group_tips = winTrans:NodeByName("e:Skin/group_tips").gameObject
	self.tips_mask = winTrans:NodeByName("e:Skin/group_tips/tips_mask").gameObject
	self.baseBitmap = winTrans:NodeByName("basebitmap").gameObject
	self.baseGroup = winTrans:NodeByName("basegroup").gameObject
	self.head = winTrans:ComponentByName("e:Skin/group_top/group_head/head", typeof(UISprite))
	self.bg_head = winTrans:ComponentByName("e:Skin/group_top/group_head/bg_head", typeof(UISprite))
	self.group_head = winTrans:NodeByName("e:Skin/group_top/group_head").gameObject
	self.headmask = winTrans:ComponentByName("e:Skin/group_top/group_head/headmask", typeof(UITexture))
end

function GameWindow:childrenCreated()
	UpdateBeat:Add(self.updateTouchHandle, self)
	self:initSetting()

	self.score_x = self.score_bar_.transform.localPosition.x

	self._gameView:setWindow(self)
	self:_initEvents()
	self._gameView:init()
	self:setStage(self._board:getGameConf().totalLevel)
	self._board:init()

	self._bottomItemList = self._board:getIngameItemList()
	self._ingameItemManager = IngameItemManager.new()

	self._ingameItemManager:init(self._bottomItemList, self._board, self, self._gameView)
	self._gameView:checkGuide()

	self.selfInfo_ = xyd.SelfInfo.get()

	self:timerCallback()

	local i = 0

	while i < GameWindow.INGAME_ITEM_NUM do
		self:initItemNumByIndex(i, self["item_num_" .. tostring(tostring(i))])

		self.bottomItemListMap[self._bottomItemList[i + 1]] = i

		self:setItemIconByIndex(i)

		i = i + 1
	end

	self:initTimer()

	if xyd.SelfInfo.get():getCurrentLevel() == 1 then
		self.setting_group:SetActive(false)
		self.group_bottom:SetActive(false)
	end

	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.GAME_VIEW_SET_STAGE,
		params = {
			stage = self._board:getGameConf().totalLevel
		}
	})
end

function GameWindow:initSetting()
	self.superMask:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	self._settingBgGroup:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
end

function GameWindow:_initEvents()
	self.eventProxy_:addEventListener(xyd.event.BOARD_RELEASE_ITEM_HINT_ANIMATION, handler(self, self._realseItemHintAnimation))
	self.eventProxy_:addEventListener(xyd.event.BOARD_RELEASE_ITEM_GRID_HINT_ANIMATION, handler(self, self._releaseItemGirdHintAnimation))
	self.eventProxy_:addEventListener(xyd.event.BOARD_USE_HAMMER_HINT, handler(self, self._useHammerHint))
	self.eventProxy_:addEventListener(xyd.event.ROCKET_CHECK_TARGET_FINISH, handler(self, self.releaseRocketMask))
	self.eventProxy_:addEventListener(xyd.event.WINDOW_WILL_OPEN, handler(self, self.onWindowOpen))
	self.eventProxy_:addEventListener(xyd.event.BUY_ITEM_BY_ID, handler(self, self.onBuyItemByID))
	self.eventProxy_:addEventListener(xyd.event.ANNA_HEAD_STATE, handler(self, self.annaHeadState))
	self.eventProxy_:addEventListener(xyd.event.GAME_ITEM_UI_UPDATE, handler(self, self.updateAllItem))
end

function GameWindow:initUIComponent()
	if UNITY_EDITOR or UNITY_STANDALONE then
		self:initGmComponent()
	elseif self.group_gm.transform.parent then
		self.group_gm.transform.parent = nil
	end

	self:setCanTouch(false)

	self.label_item3_col.text = __("COL_USE")
	self.label_item3_row.text = __("ROW_USE")
	self.item_tip.text = __("ROCKET_TIPS")
	self.label_shuffle.text = __("SHUFFLE_TIPS")
	self.mode1_score1.text = __("GAME_MODE1_TIPS1")
	self.mode1_score2.text = __("GAME_MODE1_TIPS2")
	self.mode1_score3.text = __("GAME_MODE1_TIPS3")
	self.label_mode2_tips1.text = __("GAME_MODE2_TIPS1")
	self.label_mode2_tips2.text = __("GAME_MODE2_TIPS2")
	self.label_mode3_tips1.text = __("GAME_MODE3_TIPS1")
	self.label_mode3_tips2.text = __("GAME_MODE3_TIPS2")
	self.label_mode4_tips.text = __("GAME_MODE4_TIPS")
	self.label_skip.text = __("GAME_SKIP_TIPS")
	self.text_score_.text = __("TEXT_SCORE")
	UIEventListener.Get(self.group_item0).onClick = handler(self, self.onItem0)
	UIEventListener.Get(self.group_item1).onClick = handler(self, self.onItem1)
	UIEventListener.Get(self.group_item2).onClick = handler(self, self.onItem2)
	UIEventListener.Get(self.group_item3).onClick = handler(self, self.onItem3)
	UIEventListener.Get(self.group_item3_col).onClick = handler(self, self.choose_sticker_col)
	UIEventListener.Get(self.group_item3_row).onClick = handler(self, self.choose_sticker_row)
	UIEventListener.Get(self._settingBgGroup).onPress = handler(self, self.onSetting)

	xyd.setDarkenBtnBehavior(self.group_sound_bg, self, self.onSoundBg)
	xyd.setDarkenBtnBehavior(self.group_sound_effect, self, self.onSoundEffect)
	xyd.setDarkenBtnBehavior(self.group_question, self, self.onBtnQuestion)
	xyd.setDarkenBtnBehavior(self.group_exit, self, self.onBtnExit)
	xyd.setDarkenBtnBehavior(self.setting_btn, self, self.onSetting)

	self.group_items = {
		self.group_item0,
		self.group_item1,
		self.group_item2,
		self.group_item3
	}
	self.item_reach_limit_img = {
		self.item0_reach_limit_img,
		self.item1_reach_limit_img,
		self.item2_reach_limit_img,
		self.item3_reach_limit_img
	}
	self.timer_group = {
		self.timer0_group,
		self.timer1_group,
		self.timer2_group,
		self.timer3_group
	}
	self.timer_label = {
		self.timer0_label,
		self.timer1_label,
		self.timer2_label,
		self.timer3_label
	}
	self.time_limited_img = {
		self.time_limited_img0,
		self.time_limited_img1,
		self.time_limited_img2,
		self.time_limited_img3
	}
	self.labelItemNum = {
		self.item_num_0,
		self.item_num_1,
		self.item_num_2,
		self.item_num_3
	}
	self.labelItemNumTimer = {
		self.item_num_timer_0,
		self.item_num_timer_1,
		self.item_num_timer_2,
		self.item_num_timer_3
	}
	self.hasTimerOnItem = {
		self.hasTimerOnItem_1,
		self.hasTimerOnItem_2,
		self.hasTimerOnItem_3,
		self.hasTimerOnItem_4
	}
	self.lastElementChoose = nil
	local texture = self._bgImg
	local random = math.random(1, 3)

	xyd.setUITexture(texture, "Textures/Game_bg/game_bg" .. random .. "_small")
	xyd.setUITextureAsync(texture, "Textures/Game_web/game_bg" .. random)
	self:setAnnaHead()
	self.bg_shezhi:SetActive(false)
end

function GameWindow:iPhoneXBottom()
	self.bg_bottom.source = "bg_xiashipei_png"
	local changeVal = 38
	self.start_bottom = self.start_bottom - changeVal
	local ____TS_obj = self.setting_btn
	local ____TS_index = "y"
	____TS_obj[____TS_index] = ____TS_obj[____TS_index] - changeVal
	local ____TS_obj = self.group_sound_bg
	local ____TS_index = "y"
	____TS_obj[____TS_index] = ____TS_obj[____TS_index] - changeVal
	local ____TS_obj = self.group_sound_effect
	local ____TS_index = "y"
	____TS_obj[____TS_index] = ____TS_obj[____TS_index] - changeVal
	local ____TS_obj = self.group_question
	local ____TS_index = "y"
	____TS_obj[____TS_index] = ____TS_obj[____TS_index] - changeVal
	local ____TS_obj = self.group_exit
	local ____TS_index = "y"
	____TS_obj[____TS_index] = ____TS_obj[____TS_index] - changeVal
	local ____TS_obj = self.bg_shezhi
	local ____TS_index = "y"
	____TS_obj[____TS_index] = ____TS_obj[____TS_index] - changeVal
	local ____TS_obj = self.group_bottom
	local ____TS_index = "bottom"
	____TS_obj[____TS_index] = ____TS_obj[____TS_index] + changeVal
end

function GameWindow:confirmBtnClick()
	if not self._board:isStable() then
		return
	end

	if self.text_input.value ~= "" then
		local input = string.split(self.text_input.value, " ")
		local ____TS_switch26 = #input

		if ____TS_switch26 == 1 then
			if input[1] == "debug" then
				self.debugLayer:SetActive(true)

				return
			end

			if tonumber(input[1]) == 1 then
				self._board:setAutoWin()
				print("win game")
			end

			if tonumber(input[1]) == 0 then
				self._board:setMovesLeft(0)
				print("lose game")
			end

			if tonumber(input[1]) == 2 then
				platform:switchAutoMode()
				self._gameView:setTestMove()
				self._board:switchMoveTime()
			end
		end

		if ____TS_switch26 == 2 then
			local cmd = tostring(input[1])
			local val = tonumber(input[2])

			if cmd == "ss" then
				self._board:setMovesLeft(val)
			end
		end

		if ____TS_switch26 == 4 then
			local ele = nil
			ele = self._board:getElementFactory():create(tonumber(input[1]), tonumber(input[2]), tonumber(input[3]), tonumber(input[4]))

			self._board:replaceTo(ele)
		end

		if ____TS_switch26 == 5 then
			local ele = nil
			ele = self._board:getElementFactory():create(tonumber(input[1]), tonumber(input[2]), tonumber(input[3]), tonumber(input[4]), nil, tonumber(input[5]))

			self._board:replaceTo(ele)
		end
	end

	self.text_input.value = ""
end

function GameWindow:initGmComponent()
	self.group_gm:SetActive(true)
	xyd.setDarkenBtnBehavior(self.btn_confirm, self, self.confirmBtnClick)
end

function GameWindow:initTimer()
	self.timer = Timer.New(handler(self, self.timerCallback), 1, -1, false)

	self.timer:Start()
end

function GameWindow:initItemNumByIndex(index, group)
	local selfInfo = self.selfInfo_
	local itemId = self._bottomItemList[index + 1]
	local limitedTimeId = itemId + ItemConstants.LIMITED_TIME_OFFSET
	local item = self._ingameItemManager:getItemById(itemId)

	if item == nil or limitedTimeId == nil then
		print("Can't fint item: " .. tostring(itemId) .. ", " .. tostring(limitedTimeId))
	end

	local count = selfInfo:getItemNumByID(tostring(itemId))
	local limitedTimeCount = selfInfo:getItemNumByID(tostring(limitedTimeId))
	local num = count + limitedTimeCount

	if limitedTimeCount > 0 and self:checkItemIsUnlocked(index) then
		self.timer_group[index + 1]:SetActive(true)
		self.labelItemNumTimer[index + 1]:SetActive(true)
		self.labelItemNum[index + 1]:SetActive(false)

		self.labelItemNumTimer[index + 1].text = tostring(num)
	end

	self.labelItemNum[index + 1].text = tostring(num)

	if item.count - self._board:getItemUsedCount()[index + 1] <= 0 then
		self.item_reach_limit[index + 1] = true

		self.item_reach_limit_img[index + 1]:SetActive(true)
	end
end

function GameWindow:setItemNumByIndex(index, num)
	self.labelItemNumTimer[index + 1].text = tostring(num)
	self.labelItemNum[index + 1].text = tostring(num)
end

function GameWindow:gameEnd()
	self:setCanTouch(false)
end

function GameWindow:gameResume()
	self.group_skip:SetActive(false)
	self:_showAllIcons()
	self:setCanTouch(true)

	self.superMask:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
end

function GameWindow:setScore(val, percent, create)
	self.score_.text = tostring(val)

	if self.scoreTimeline_ ~= nil then
		self.scoreTimeline_:Pause()
		self.scoreTimeline_:Kill()

		self.scoreTimeline_ = nil
	end

	self.scoreTimeline_ = DG.Tweening.DOTween.Sequence()
	local moveTime = 10 * xyd.TweenDeltaTime
	local mask = self.score_bar_
	local maskNewWidth = self.score_bar_.width * percent

	if self.score_bar_ ~= nil then
		local sequence1 = DG.Tweening.DOTween.Sequence()

		sequence1:Insert(0, self.score_bar_.transform:DOLocalMoveX(self.score_x + maskNewWidth, moveTime))
		sequence1:Insert(0, self.bar_.transform:DOLocalMoveX(self.score_bar_.width - maskNewWidth, moveTime))

		self.scoreTimeline_ = sequence1
	end
end

function GameWindow:setStep(val, create)
	if val == 0 then
		self._gameOver = true
	elseif val > 0 then
		self._gameOver = false
	end

	self.step_.text = tostring(val)
end

function GameWindow:setStage(val)
	self.stage_.text = val
	self.stageLevel_ = val
end

function GameWindow:moveElement(fromPoint, toPoint)
	if self.lastLogicPoint then
		self._gameView:unselectElement(self.lastLogicPoint.x, self.lastLogicPoint.y)
	end

	if self._gameView:isStableElement(toPoint.x, toPoint.y) then
		self.lastLogicPoint = nil

		return
	end

	self:setCanTouch(false)

	local swap = SwapInfo.new(fromPoint, toPoint)

	if self._guide ~= nil and self._guide.isActive then
		local guideID = self._guide:getGuideID()

		if GuideHelper.isValidMoveInGuide(guideID, fromPoint, toPoint) and self._board:isValidSwap(swap) then
			self._gameView:doSwap(swap)
			xyd.SoundManager.get():playEffect("level/se_switch")
		else
			self:setCanTouch(true)
		end
	elseif self._board:isValidSwap(swap) then
		self._gameView:doSwap(swap)
		xyd.SoundManager.get():playEffect("level/se_switch")
	else
		self._gameView:doInValidSwap(swap)
		xyd.SoundManager.get():playEffect("level/se_switch_2")
	end

	self.lastLogicPoint = nil
end

function GameWindow:setBoardPos(maxwidth, minwidth, maxheight, minheight)
	self._maxWidth = maxwidth
	self._minWidth = minwidth
	self._maxHeight = maxheight
	self._minHeight = minheight
	self._originBoardX = self.group_board.transform.localPosition.x
	self._originBoardY = self.group_board.transform.localPosition.y

	self:_updateBoardPos()
end

function GameWindow:_updateBoardPos()
	local width = self._maxWidth - self._minWidth + 1
	local deltaX = -self._minWidth
	deltaX = deltaX + 8 - self._maxWidth
	deltaX = deltaX * xyd.TILE_WIDTH_HALF

	if width % 2 == 0 then
		self.group_board.transform.localPosition = Vector3(deltaX + self._originBoardX, 0, 0)
	else
		self.group_board.transform.localPosition = Vector3(deltaX + self._originBoardX, 0, 0)
	end

	local availHeight = xyd.getFixedHeight() - self.TOP_UI_HEIGHT - self.BOTTOM_UI_HEIGHT
	local scale = 1
	local board_widget = self.group_board:GetComponent(typeof(UIWidget))

	if availHeight < board_widget.height then
		scale = availHeight / self.MAX_BOARD_HEIGHT
	end

	local maxTileWidth = 9
	local leftTileSize = 0
	local maxScale = (maxTileWidth - leftTileSize) / maxTileWidth

	if scale > maxScale then
		scale = maxScale
	end

	self._boardScale = scale
	self.group_board.transform.localScale = Vector3(scale, scale, 1)
	self.group_board.transform.localPosition = Vector3(deltaX + self._originBoardX + board_widget.width * (1 - scale) / 2, xyd.getFixedHeight() / 2 - (availHeight - board_widget.height * scale) / 2 - self.TOP_UI_HEIGHT, 0)
	self.GROUP_BOARD_X = self.group_board.transform.localPosition.x
	self.GROUP_BOARD_Y = self.group_board.transform.localPosition.y
end

function GameWindow:touchMoved(cellX, cellY)
end

function GameWindow:onOutside(e)
	if self._status == nil then
		return
	end

	if self._status == ItemConstants.NORMAL then
		self:onOpUpNormal(e)

		self.lastLogicPoint = nil

		return
	end

	if self._status == ItemConstants.ROCKET then
		self.lastLogicPoint = nil

		return
	end

	local item = self._ingameItemManager:getItemById(self._status)

	item:onOpUp(e)

	self.lastLogicPoint = nil
end

function GameWindow:onOpUp(e)
	if self._status == nil then
		return
	end

	if self._status == ItemConstants.NORMAL then
		self:onOpUpNormal(e)

		self.lastLogicPoint = nil

		return
	end

	if self._status == ItemConstants.ROCKET then
		self.lastLogicPoint = nil

		return
	end

	local item = self._ingameItemManager:getItemById(self._status)

	item:onOpUp(e)

	self.lastLogicPoint = nil
end

function GameWindow:onOpDown(e)
	if self._status == nil then
		return
	end

	if self._status == ItemConstants.NORMAL then
		self:onOpDownNormal(e)

		return
	end

	if self._status == ItemConstants.ROCKET then
		self:onOpDownRocket(e)

		return
	end

	local item = self._ingameItemManager:getItemById(self._status)

	item:onOpDown(e)
end

function GameWindow:onDragOnMainField(e)
	if self._status == nil then
		return
	end

	if self._status == ItemConstants.NORMAL then
		self:onDragOnMainFieldNormal(e)

		return
	end

	if self._status == ItemConstants.ROCKET then
		return
	end

	local item = self._ingameItemManager:getItemById(self._status)

	item:onDragOnMainField(e)
end

function GameWindow:setCanTouch(b)
	self.canTouch = b
end

function GameWindow:setStatus(status)
	self._status = status

	if self._status ~= ItemConstants.NORMAL then
		self._gameView:clearLeafLight()
	end
end

function GameWindow:onOpUpNormal(e)
	if self.lastLogicPoint then
		self._gameView:unselectElement(self.lastLogicPoint.x, self.lastLogicPoint.y)
	end

	if self.canTouch == false then
		return
	end

	local toPoint = self._gameView:viewToLogicTouch(Point.new(e.localX, e.localY))

	if self._guide ~= nil and self._guide.isActive then
		local guideID = self._guide:getGuideID()

		if not GuideHelper.isValidSelectionInGuide(guideID, toPoint) then
			return
		end
	end

	if self.lastElementChoose then
		if self.lastElementChoose.x == toPoint.x and math.abs(self.lastElementChoose.y - toPoint.y) == 1 or self.lastElementChoose.y == toPoint.y and math.abs(self.lastElementChoose.x - toPoint.x) == 1 then
			self._gameView:unselectElement(self.lastElementChoose.x, self.lastElementChoose.y)
			self._gameView:unselectElement(toPoint.x, toPoint.y)
			self:moveElement(self.lastElementChoose, toPoint)

			self.lastMousePos = nil
			self.curMousePos = nil
			self.lastLogicPoint = nil
			self.lastElementChoose = nil

			return
		elseif toPoint.x == self.lastElementChoose.x and toPoint.y == self.lastElementChoose.y then
			self._gameView:unselectElement(self.lastElementChoose.x, self.lastElementChoose.y)

			self.lastElementChoose = nil
		else
			self._gameView:unselectElement(self.lastElementChoose.x, self.lastElementChoose.y)
			self._gameView:selectElement(toPoint.x, toPoint.y)

			self.lastElementChoose = toPoint
		end
	end

	if self.lastLogicPoint and toPoint.x == self.lastLogicPoint.x and toPoint.y == self.lastLogicPoint.y then
		self.lastElementChoose = toPoint

		self._gameView:selectElement(toPoint.x, toPoint.y)

		local ele = self._board:getElementAtGrid(self.lastElementChoose.x, self.lastElementChoose.y)

		if ele and ele.type == ElementTypeConstants.ROCKET then
			local rocketEle = ele

			if rocketEle.rocketState == RocketConstants.STATE_READY then
				self:useItemMask(ItemConstants.ROCKET)
				self:_setItemMaskExcludeIndex(-1)

				if self._guide then
					self._guide.gameObject:SetActive(false)
				end

				if rocketEle.rocketType == RocketConstants.SPECIAL_COLOR_BOMBED then
					-- Nothing
				end
			end
		end
	end

	self.lastLogicPoint = toPoint

	if self._gameOver then
		return
	end

	if self.lastLogicPoint == nil then
		return
	end

	if toPoint.x == self.lastLogicPoint.x and (toPoint.y == self.lastLogicPoint.y + 1 or toPoint.y == self.lastLogicPoint.y - 1) then
		self:moveElement(self.lastLogicPoint, toPoint)
	end

	if toPoint.y == self.lastLogicPoint.y and (toPoint.x == self.lastLogicPoint.x + 1 or toPoint.x == self.lastLogicPoint.x - 1) then
		self:moveElement(self.lastLogicPoint, toPoint)
	end

	self:clearMouseData()
end

function GameWindow:onOpDownNormal(e)
	if self._gameOver then
		return
	end

	if self.canTouch == false then
		return
	end

	if self.BOARD_MAX_WIDTH < e.localX then
		return
	end

	if self.BOARD_MAX_HEIGHT < e.localY then
		return
	end

	local toPoint = self._gameView:viewToLogicTouch(Point.new(e.localX, e.localY))
	self.lastLogicPoint = self._gameView:viewToLogicTouch(Point.new(e.localX, e.localY))

	if self._gameView:isStableElement(self.lastLogicPoint.x, self.lastLogicPoint.y) then
		self.lastLogicPoint = nil

		return
	end

	self._gameView:selectElement(self.lastLogicPoint.x, self.lastLogicPoint.y)

	if e.stageX ~= 0 or e.stageY ~= 0 then
		self.lastMousePos = Point.new(e.stageX, e.stageY)
		self.curMousePos = Point.new(e.stageX, e.stageY)
	else
		self.lastMousePos = Point.new(-1000, -1000)
		self.curMousePos = Point.new(-1000, -1000)
	end
end

function GameWindow:onOpDownRocket(e)
	if self._gameOver then
		return
	end

	if self.canTouch == false then
		return
	end

	if self.BOARD_MAX_WIDTH < e.localX then
		return
	end

	if self.BOARD_MAX_HEIGHT < e.localY then
		return
	end

	if not self.lastElementChoose then
		return
	end

	local point = self._gameView:viewToLogicTouch(Point.new(e.localX, e.localY))

	if point:equals(self.lastElementChoose) then
		self:unuseItemMask()
		self._gameView:checkPossibleMove()

		if self._guide then
			self._guide.gameObject:SetActive(true)
		end
	else
		xyd.EventDispatcher:inner():dispatchEvent({
			name = xyd.event.ROCKET_CHECK_TARGET,
			params = {
				to = point,
				from = self.lastElementChoose
			}
		})
	end
end

function GameWindow:onDragOnMainFieldNormal(e)
	if self.canTouch == false then
		return
	end

	if self._gameOver then
		return
	end

	if self.lastLogicPoint == nil then
		return
	end

	if self.curMousePos == nil then
		self.curMousePos = Point.new(e.stageX, e.stageY)
	else
		self.curMousePos.x = e.stageX
		self.curMousePos.y = e.stageY
	end

	local toPoint = Point.new()
	toPoint.x = self.lastLogicPoint.x
	toPoint.y = self.lastLogicPoint.y

	if math.abs(self.curMousePos.x - self.lastMousePos.x) > self.BOARD_ELE_WIDTH / 4 then
		if self.curMousePos.x - self.lastMousePos.x > 0 then
			toPoint.x = toPoint.x + 1
		else
			toPoint.x = toPoint.x - 1
		end

		toPoint.y = self.lastLogicPoint.y

		if self.lastElementChoose then
			self._gameView:unselectElement(self.lastElementChoose.x, self.lastElementChoose.y)

			self.lastElementChoose = nil
		end

		self:moveElement(self.lastLogicPoint, toPoint)

		self.lastLogicPoint = nil

		return
	end

	if math.abs(self.curMousePos.y - self.lastMousePos.y) > self.BOARD_ELE_WIDTH / 4 then
		if self.curMousePos.y - self.lastMousePos.y > 0 then
			toPoint.y = toPoint.y + 1
		else
			toPoint.y = toPoint.y - 1
		end

		toPoint.x = self.lastLogicPoint.x

		if self.lastElementChoose then
			self._gameView:unselectElement(self.lastElementChoose.x, self.lastElementChoose.y)

			self.lastElementChoose = nil
		end

		self:moveElement(self.lastLogicPoint, toPoint)

		self.lastLogicPoint = nil

		return
	end
end

function GameWindow:onItem0(e)
	if not self.canTouch then
		return
	end

	if not self:checkItemIsUnlocked(0) then
		xyd.WindowManager:get():openWindow("item_lock_window")

		return
	end

	self:listenOnItemByIndex(0)
end

function GameWindow:onItem1(e)
	if not self.canTouch then
		return
	end

	if not self:checkItemIsUnlocked(1) then
		xyd.WindowManager:get():openWindow("item_lock_window")

		return
	end

	self:listenOnItemByIndex(1)
end

function GameWindow:onItem2(e)
	if not self.canTouch then
		return
	end

	if not self:checkItemIsUnlocked(2) then
		xyd.WindowManager:get():openWindow("item_lock_window")

		return
	end

	self:listenOnWand(2)
end

function GameWindow:onItem3(e)
	if not self.canTouch then
		return
	end

	if not self:checkItemIsUnlocked(3) then
		xyd.WindowManager:get():openWindow("item_lock_window")

		return
	end

	self:listenOnItemByIndex(3)
end

function GameWindow:setItemIconByIndex(index)
	local img = self["img_item" .. tostring(index)]

	if not self:checkItemIsUnlocked(index) then
		xyd.setUISprite(img, "GameLater", "icon_lock")
		self["item_num_group" .. tostring(index)]:SetActive(false)

		local oldPos = self["img_item" .. tostring(index)].transform.localPosition
		self["img_item" .. tostring(index)].transform.localPosition = Vector3(oldPos.x + 5, oldPos.y, oldPos.z)

		img:MakePixelPerfect()
	else
		xyd.setUISprite(img, "Item", self.ITEM_ICON_SOURCES[index + 1])
		self["item_num_group" .. tostring(index)]:SetActive(true)
	end
end

function GameWindow:checkItemIsUnlocked(index)
	local itemId = self._bottomItemList[index + 1]
	local stage = self.ITEM_UNLOCK_STAGE[itemId]

	if stage == nil or self.stageLevel_ == nil then
		return false
	end

	if xyd.SelfInfo.get():getCurrentLevel() == stage then
		return GuideHelper.hasGuideForLevel(self.stageLevel_)
	end

	return stage < xyd.SelfInfo.get():getCurrentLevel()
end

function GameWindow:listenOnItemByIndex(index)
	self.cur_item_click_index = index

	if self.lastElementChoose then
		self._gameView:unselectElement(self.lastElementChoose.x, self.lastElementChoose.y)

		self.lastElementChoose = nil
	end

	if not self.canTouch then
		return
	elseif not self.itemCanTouch then
		return
	end

	if self._item_lisenter_index ~= nil and self._item_lisenter_index ~= index then
		return
	end

	local itemId = self._bottomItemList[index + 1]
	local item = self._ingameItemManager:getItemById(itemId)

	if not self.item_reach_limit[index + 1] then
		if self._status == ItemConstants.NORMAL then
			local num = item:getTotalNum()

			if num <= 0 then
				if self._isRequestingGameBuyItem then
					return
				end

				self._isRequestingGameBuyItem = true
				local timer = Timer.New(function ()
					self._isRequestingGameBuyItem = false
				end, 0.6, 1, true)

				timer:Start()

				if not xyd.MapController.get().isInNewUserGuide then
					xyd.WindowManager.get():openWindow("buy_item_window", {
						id = itemId
					})
				end

				return
			end

			self.group_item_tip:SetActive(true)

			local picName = ItemConstants.ITEM_IMGS[index + 1]

			xyd.setUISprite(self.item_img, MappingData[picName], picName)

			self.item_tip.text = __(ItemConstants.ITEM_TIPS[index + 1])

			self:useItemMask(itemId)

			if not self._guide then
				self:_setItemMaskExcludeIndex(index)
			end

			self._item_lisenter_index = index

			if itemId == ItemConstants.STICKER then
				if self.stick_choosed ~= Sticker.CHOOSE_NONE then
					self.stick_choosed = Sticker.CHOOSE_NONE

					return
				end

				self.itemCanTouch = false

				self:show_sticker_effect()
			end
		else
			self._status = ItemConstants.NORMAL

			self:unuseItemMask()
			self._gameView:checkPossibleMove()

			if itemId == ItemConstants.STICKER then
				if self.stick_choosed ~= Sticker.CHOOSE_NONE then
					self.stick_choosed = Sticker.CHOOSE_NONE

					return
				elseif self.stick_show then
					self:unshow_sticker_effect()
				end
			end
		end
	end
end

function GameWindow:onBuyItemByID(event)
	local data = event.data

	if data.success then
		local index = self.cur_item_click_index

		if index == nil then
			return
		end

		local itemId = self._bottomItemList[index + 1]
		local item = self._ingameItemManager:getItemById(itemId)

		self:setItemNumByIndex(index, item:getTotalNum())

		local picName = ItemConstants.ITEM_IMGS[index + 1]

		xyd.setUISprite(self.item_img, MappingData[picName], picName)

		self.item_tip.text = __(ItemConstants.ITEM_TIPS[index + 1])

		if itemId ~= ItemConstants.WAND then
			self.group_item_tip:SetActive(true)
			self:useItemMask(itemId)
			self:_setItemMaskExcludeIndex(index)

			self._item_lisenter_index = index
		end

		if itemId == ItemConstants.STICKER then
			if self.stick_choosed ~= Sticker.CHOOSE_NONE then
				self.stick_choosed = Sticker.CHOOSE_NONE

				return
			end

			self.itemCanTouch = false

			self:show_sticker_effect()
		end
	else
		self.label_shuffle.text = __("NO_DIAMOND")

		self._gameView:_disposeComboEffect()
		self._gameView:showShuffleTips(self._gameView.group_shuffle)
		self:setCanTouch(true)
	end
end

function GameWindow:listenOnWand(index)
	self.cur_item_click_index = index

	if self.lastElementChoose then
		self._gameView:unselectElement(self.lastElementChoose.x, self.lastElementChoose.y)

		self.lastElementChoose = nil
	end

	if not self.canTouch then
		return
	elseif not self.itemCanTouch then
		return
	end

	if self._item_lisenter_index ~= nil and self._item_lisenter_index ~= 2 then
		return
	end

	if self._board:getNormalElementLength() < 3 then
		return
	end

	local wand = self._ingameItemManager:getItemById(ItemConstants.WAND)

	if not self.item_reach_limit[3] and self._status == ItemConstants.NORMAL then
		local itemId = self._bottomItemList[3]
		local num = wand:getTotalNum()

		if num <= 0 then
			if self._isRequestingGameBuyItem then
				return
			end

			self._isRequestingGameBuyItem = true

			XYDCo.WaitForTime(0.6, function ()
				self._isRequestingGameBuyItem = false
			end, "")

			if not xyd.MapController.get().isInNewUserGuide then
				xyd.WindowManager.get():openWindow("buy_item_window", {
					id = itemId
				})
			end

			self._gameView:clearPossibleMove()

			return
		end

		self._item_lisenter_index = 2

		self._gameView:clearPossibleMove()
		self:setCanTouch(false)
		wand:inUse()
		self:removeGuide()
		wand:activate()

		self._item_lisenter_index = nil
	end
end

function GameWindow:choose_sticker_col(e)
	if not self.itemCanTouch then
		return
	end

	self.stick_choosed = Sticker.CHOOSE_COL

	self:unshow_sticker_effect()
end

function GameWindow:choose_sticker_row(e)
	if not self.itemCanTouch then
		return
	end

	self.stick_choosed = Sticker.CHOOSE_ROW

	self:unshow_sticker_effect()

	if self._guide ~= nil and self._guide.isActive then
		self._guide:canHighlightELements(true)
	end
end

function GameWindow:show_sticker_effect()
	self.group_item3_col:SetActive(true)
	self.group_item3_row:SetActive(true)

	local sequence = DG.Tweening.DOTween.Sequence()
	local rowTrans = self.group_item3_row.transform
	local colTrans = self.group_item3_col.transform
	self.stick_show = true

	sequence:Insert(0, rowTrans:DOLocalMoveX(-254, 6 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.OutQuad))
	sequence:Insert(6 * xyd.TweenDeltaTime, rowTrans:DOLocalMoveX(-218, 12 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.OutQuad))
	sequence:Insert(0, colTrans:DOLocalMoveY(246, 6 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.OutQuad))
	sequence:Insert(6 * xyd.TweenDeltaTime, colTrans:DOLocalMoveY(216, 12 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.OutQuad))
	sequence:AppendCallback(function ()
		self.itemCanTouch = true
	end)
end

function GameWindow:unshow_sticker_effect()
	if self._guide ~= nil and self._guide.isActive then
		self._guide:canHighlightELements(false)
		self._guide:showGuideUI(false)
	end

	self.itemCanTouch = false
	local sequence = DG.Tweening.DOTween.Sequence()

	sequence:Insert(0, self.group_item3_row.transform:DOLocalMoveX(0, 10 * xyd.TweenDeltaTime))
	sequence:Insert(0, self.group_item3_col.transform:DOLocalMoveY(0, 10 * xyd.TweenDeltaTime))
	sequence:AppendCallback(function ()
		self.group_item3_row:SetActive(false)
		self.group_item3_col:SetActive(false)

		self.itemCanTouch = true
	end)

	self.stick_show = false
end

function GameWindow:_setItemMaskExcludeIndex(index)
	local i = 0

	while i < #self.group_items do
		if i ~= index then
			xyd.useFilter(self.group_items[i + 1], xyd.FILTER.useItemFilter)

			self.labelItemNum[i + 1].color = xyd.FILTER.useItemFilter
		end

		i = i + 1
	end

	xyd.useFilter(self.setting_btn, xyd.FILTER.useItemFilter)
end

function GameWindow:_clearItemMask()
	local i = 0

	while i < #self.group_items do
		xyd.removeFilter(self.group_items[i + 1])

		self.labelItemNum[i + 1].color = Color.New2(4278054911.0)
		i = i + 1
	end

	xyd.removeFilter(self.setting_btn)
end

function GameWindow:dispose()
	self:removeGuide()
	self:setCanTouch(false)

	if self.shakeTween then
		self.shakeTween:Kill(false)

		self.shakeTween = nil
	end

	if not tolua.isnull(self._headEff) then
		self.headTimer:Stop()
		Destroy(self._headEff)

		self._headEff = nil
	end

	self.timer:Stop()
	self:_realseItemHintAnimation(true)
	self:_releaseItemGirdHintAnimation(true)
	UpdateBeat:Remove(self.updateTouchHandle, self)
	GameWindow.super.dispose(self)
end

function GameWindow:useItemMask(status)
	self.setting_btn_collider.enabled = false

	self._gameView:useItemMask(true)
	self._gameView:clearPossibleMove()
	self:setStatus(status)

	if status == GameWindowConstants.HAMMER and self._showItemHint == true then
		self:_showHammerGridHintEffect()
	end

	if self._guide ~= nil and self._guide.isActive and status ~= ItemConstants.ROCKET then
		if self._guide:isItemGuide() and self._guide:getItemID() ~= ItemConstants.STICKER then
			self._guide:canHighlightELements(true)
		end

		self._guide:showGuideUI(false)
		self._gameView:useItemMask(false)
	end
end

function GameWindow:_showHammerGridHintEffect()
	if not self._itemGridHintPos then
		return
	end

	local tmp = self._gameView:logicToView(self._itemGridHintPos)

	DBResManager.get():newEffect(self.beltLayer, EffectConstants.ITEM_GRID_HINT, function (success, eff)
		if success then
			eff.transform.localPosition = Vector3(tmp.x, tmp.y + 15, 0)
			eff.transform.localScale = Vector3(100, 100, 100)
			self._itemGridHintEff = eff
			local animComponent = eff:GetComponent(typeof(DragonBones.UnityArmatureComponent))
			animComponent.renderTarget = self.beltTarget
			local effAnimation = animComponent.animation

			effAnimation:Play("texiao01", 0)
		end
	end)
end

function GameWindow:unuseItemMask()
	self.setting_btn_collider.enabled = true

	self._gameView:useItemMask(false)

	self._item_lisenter_index = nil

	self.group_item_tip:SetActive(false)
	self:_clearItemMask()
	self:_releaseItemGirdHintAnimation()

	self._status = ItemConstants.NORMAL

	if self._guide ~= nil and self._guide.isActive then
		self._guide:canHighlightELements(false)
		self._guide:showGuideUI(true)
	end
end

function GameWindow:releaseRocketMask(event)
	local point = event.params.from

	self:unuseItemMask()
	self._gameView:unselectElement(point.x, point.y)
end

function GameWindow:getGuide()
	return self._guide
end

function GameWindow:setGuide(guideID)
	if self._guide then
		self:removeGuide()
	end

	if self._guide == nil then
		self._guide = Guide.new(self, self._gameView, guideID, self._boardScale)

		self._guide:addGameObject(self.guide_area)
	else
		self._guide:setData(self, self._gameView, guideID, self._boardScale)
		self._guide:childrenCreated()
	end

	if self._settingState == 1 then
		self:onSetting()
	end
end

function GameWindow:destroyGuide()
	self._guide:close()

	self._guide = nil
end

function GameWindow:removeGuide()
	if self._guide then
		if GuideHelper.isLastGuideForLevel(self._guide:getGuideID()) then
			self._guide:close()

			self._guide = nil
		else
			self._guide:hide()
		end
	end
end

function GameWindow:onBtnQuestion()
	self:onSetting()
end

function GameWindow:onBtnExit()
	self:onSetting()
	xyd.WindowManager:get():openWindow("exit_comfirm_window", {
		stageLevel = self.stageLevel_
	})
end

function GameWindow:onSoundEffect()
	local soundMgr = xyd.SoundManager.get()
	local bg = soundMgr:getIsSoundOn()

	if bg then
		soundMgr:setIsSoundOn(false)
		self.sound_eff_disable:SetActive(true)
	else
		soundMgr:setIsSoundOn(true)
		self.sound_eff_disable:SetActive(false)
	end
end

function GameWindow:onSoundBg()
	local soundMgr = xyd.SoundManager.get()
	local bg = soundMgr:getIsMusicOn()

	if bg then
		soundMgr:setIsMusicOn(false)
		self.sound_bg_disable:SetActive(true)
	else
		soundMgr:setIsMusicOn(true)
		self.sound_bg_disable:SetActive(false)
	end
end

function GameWindow:onSetting()
	if self._status ~= ItemConstants.NORMAL or self._gameView:getCurrentGuideID() > 0 then
		return
	end

	if self._settingCanTouch then
		xyd.SoundManager.get():playEffect("Common/se_button")

		if self._settingState == 1 then
			self._settingCanTouch = false

			self:hideSetting()

			self._settingState = 0
		else
			self._settingCanTouch = false

			self:showSetting()

			self._settingState = 1
		end
	end
end

function GameWindow:hideSetting()
	self._settingBgGroup:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	local sequence = DG.Tweening.DOTween.Sequence()

	sequence:Insert(0, self.group_sound_bg.transform:DOLocalMoveY(self.setting_btn.transform.localPosition.y, 10 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
	sequence:Insert(0, self.group_sound_effect.transform:DOLocalMoveY(self.setting_btn.transform.localPosition.y, 10 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
	sequence:Insert(0, self.group_question.transform:DOLocalMoveY(self.setting_btn.transform.localPosition.y, 10 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
	sequence:Insert(0, self.group_exit.transform:DOLocalMoveY(self.setting_btn.transform.localPosition.y, 10 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
	sequence:Insert(0, self.bg_shezhi.transform:DOScaleY(0, 10 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear):OnComplete(function ()
		self.bg_shezhi:SetActive(false)
	end))

	local function getter()
		return self.bg_shezhi:GetComponent(typeof(UISprite)).color
	end

	local function setter(value)
		self.bg_shezhi:GetComponent(typeof(UISprite)).color = value
	end

	sequence:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 0, 10 * xyd.TweenDeltaTime))
	sequence:AppendCallback(function ()
		self.group_sound_bg:SetActive(false)
		self.group_sound_effect:SetActive(false)
		self.group_question:SetActive(false)
		self.group_exit:SetActive(false)

		self._settingCanTouch = true
	end)
end

function GameWindow:showSetting()
	self._settingBgGroup:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

	self.group_sound_bg:SetActive(true)
	self.group_sound_effect:SetActive(true)
	self.group_question:SetActive(true)
	self.group_exit:SetActive(true)

	local bg_shezhi_color = self.bg_shezhi:GetComponent(typeof(UISprite)).color
	self.bg_shezhi:GetComponent(typeof(UISprite)).color = Color.New(bg_shezhi_color.r, bg_shezhi_color.g, bg_shezhi_color.b, 0.33)
	local sequence = DG.Tweening.DOTween.Sequence()

	sequence:Insert(0, self.group_sound_bg.transform:DOLocalMoveY(self.setting_btn.transform.localPosition.y + 130, 6 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.OutQuad))
	sequence:Insert(0, self.group_sound_effect.transform:DOLocalMoveY(self.setting_btn.transform.localPosition.y + 260, 6 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.OutQuad))
	sequence:Insert(0, self.group_question.transform:DOLocalMoveY(self.setting_btn.transform.localPosition.y + 390, 6 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.OutQuad))
	sequence:Insert(0, self.group_exit.transform:DOLocalMoveY(self.setting_btn.transform.localPosition.y + 520, 6 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.OutQuad))
	sequence:Insert(6 * xyd.TweenDeltaTime, self.group_sound_bg.transform:DOLocalMoveY(self.setting_btn.transform.localPosition.y + 120, 9 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.OutQuad))
	sequence:Insert(6 * xyd.TweenDeltaTime, self.group_sound_effect.transform:DOLocalMoveY(self.setting_btn.transform.localPosition.y + 240, 9 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.OutQuad))
	sequence:Insert(6 * xyd.TweenDeltaTime, self.group_question.transform:DOLocalMoveY(self.setting_btn.transform.localPosition.y + 360, 9 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.OutQuad))
	sequence:Insert(6 * xyd.TweenDeltaTime, self.group_exit.transform:DOLocalMoveY(self.setting_btn.transform.localPosition.y + 480, 9 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.OutQuad))
	sequence:Insert(0, self.bg_shezhi.transform:DOScaleY(1.07, 6 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.OutQuad):OnComplete(function ()
		self.bg_shezhi:SetActive(true)
	end))
	sequence:Insert(6 * xyd.TweenDeltaTime, self.bg_shezhi.transform:DOScaleY(1, 9 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.OutQuad))

	local function getter()
		return self.bg_shezhi:GetComponent(typeof(UISprite)).color
	end

	local function setter(value)
		self.bg_shezhi:GetComponent(typeof(UISprite)).color = value
	end

	sequence:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 2 * xyd.TweenDeltaTime))
	sequence:AppendCallback(function ()
		self._settingCanTouch = true
	end)
end

function GameWindow:getStatus()
	return self._status
end

function GameWindow:clearMouseData()
	self.lastMousePos = nil
	self.curMousePos = nil
	self.lastLogicPoint = nil
end

function GameWindow:touchAble()
	return self.canTouch
end

function GameWindow:isGameOver()
	return self._gameOver
end

function GameWindow:useItemReachLimitById(id)
	local index = self.bottomItemListMap[id]
	self.item_reach_limit[index + 1] = true

	self.item_reach_limit_img[index + 1]:SetActive(true)
end

function GameWindow:useItemById(id)
	local item = self._ingameItemManager:getItemById(id)
	local index = self.bottomItemListMap[id]

	self._board:increaseItemUsedCount(index)

	self.expired_time_cache[index + 1] = nil
	local count = item:getTotalNum()

	self:setItemNumByIndex(index, count)

	if self._guide ~= nil and self._guide.isActive then
		self:removeGuide()
		self._gameView:tryNextGuide()
	end
end

function GameWindow:timerCallback()
	local curTime = os.time()
	local i = 0

	while i < 4 do
		self:timerHelper(i, curTime)

		i = i + 1
	end
end

function GameWindow:timerHelper(index, curTime)
	local expireTime = self.expired_time_cache[index + 1]

	if expireTime == nil or expireTime - curTime <= 0 then
		local selfInfo = self.selfInfo_
		local itemID = self._bottomItemList[index + 1]
		local itemIDStr = tostring(self._bottomItemList[index + 1])
		local itemTimeIDStr = tostring(self._bottomItemList[index + 1] + ItemConstants.LIMITED_TIME_OFFSET)
		local itemCount = selfInfo:getItemNumByID(itemIDStr)
		local itemTimeCount = selfInfo:getItemNumByID(itemTimeIDStr)
		local item = self._ingameItemManager:getItemById(itemID)

		if not itemTimeCount or itemTimeCount <= 0 then
			if self.hasTimerOnItem[index + 1] then
				self.timer_group[index + 1]:SetActive(false)
				self.labelItemNum[index + 1]:SetActive(true)
				self.labelItemNumTimer[index + 1]:SetActive(false)
				xyd.setUISprite(self.time_limited_img[index + 1], xyd.MappingData.icon_shuliang, "icon_shuliang")

				self.hasTimerOnItem[index + 1] = false
			end

			self:updateItemCountByIndex(index, item:getTotalNum())

			return
		end

		if not self.hasTimerOnItem[index + 1] then
			xyd.setUISprite(self.time_limited_img[index + 1], xyd.MappingData.icon_xianshi, "icon_xianshi")

			self.hasTimerOnItem[index + 1] = true
		end

		expireTime = selfInfo:getItemExpireTimeByID(itemTimeIDStr)
		self.expired_time_cache[index + 1] = expireTime

		self:updateItemCountByIndex(index, item:getTotalNum())
	end

	local cd = expireTime - curTime
	self.timer_label[index + 1].text = xyd.secondsToString(cd, xyd.SecondsStrType.WITH_HOUR)
end

function GameWindow:updateItemCountByIndex(index, count)
	self:setItemNumByIndex(index, count)
end

function GameWindow:shakeBoard(intensity)
	if self.shakeTween then
		self.shakeTween:Kill(true)
	end

	local moveTime = xyd.TweenDeltaTime
	local trans = self.group_board.transform
	self.shakeTween = DG.Tweening.DOTween.Sequence()

	self.shakeTween:Append(trans:DOLocalMove(Vector3(self.GROUP_BOARD_X - 2 * intensity, self.GROUP_BOARD_Y - 4 * intensity, 0), moveTime))
	self.shakeTween:Append(trans:DOLocalMove(Vector3(self.GROUP_BOARD_X + 2 * intensity, self.GROUP_BOARD_Y + 4 * intensity, 0), moveTime))
	self.shakeTween:Append(trans:DOLocalMove(Vector3(self.GROUP_BOARD_X - 2 * intensity, self.GROUP_BOARD_Y - 4 * intensity, 0), moveTime))
	self.shakeTween:Append(trans:DOLocalMove(Vector3(self.GROUP_BOARD_X + 2 * intensity, self.GROUP_BOARD_Y + 4 * intensity, 0), moveTime))
	self.shakeTween:Append(trans:DOLocalMove(Vector3(self.GROUP_BOARD_X - 2 * intensity, self.GROUP_BOARD_Y - 4 * intensity, 0), moveTime))
	self.shakeTween:Append(trans:DOLocalMove(Vector3(self.GROUP_BOARD_X, self.GROUP_BOARD_Y, 0), moveTime))
end

function GameWindow:getCollectNum(missionID)
	return self._board:getCollectNum(missionID)
end

function GameWindow:getBottomItemGroup(itemID)
	if itemID == ItemConstants.WAND then
		return self.group_item2
	end

	if itemID == ItemConstants.HAMMER then
		return self.group_item0
	end

	if itemID == ItemConstants.STICKER then
		if self._guide ~= nil and self._guide.isActive and self._guide:isItemGuide() then
			return self.group_item3_row
		end

		return self.group_item3
	end

	if itemID == ItemConstants.SWAPPER then
		return self.group_item1
	end

	return nil
end

function GameWindow:setBottomItemInUse(itemID)
	if itemID == ItemConstants.WAND then
		self._item_lisenter_index = 2
	end
end

function GameWindow:clearBottmItemInUse()
	self._item_lisenter_index = nil
end

function GameWindow:getItemByID(itemID)
	return self._ingameItemManager:getItemById(itemID)
end

function GameWindow:updateItemCountByID(itemID)
	local item = self._ingameItemManager:getItemById(itemID)
	local index = self.bottomItemListMap[itemID]

	if item and index ~= nil then
		self:updateItemCountByIndex(index, item:getTotalNum())
	end
end

function GameWindow:_useHammerHint(event)
	local groupIndex = self.bottomItemListMap[ItemConstants.HAMMER]

	if self.item_reach_limit[groupIndex + 1] then
		return
	end

	local x = event.params.x
	local y = event.params.y
	self._itemGridHintPos = Point.new(x, y)

	self:_itemHintAnimation(self.group_item0)

	self._itemHintGroupIndex = groupIndex
end

function GameWindow:_itemHintAnimation(group)
	if self._showItemHint then
		return
	end

	self._showItemHint = true
	local tmppos = group.transform.parent.transform:TransformPoint(group.transform.localPosition)
	local tmp = self.window_.transform:InverseTransformPoint(tmppos)

	DBResManager.get():newEffect(self.window_, EffectConstants.ITEM_USE_HINT, function (success, eff)
		if success then
			eff.transform.localPosition = Vector3(tmp.x, tmp.y, 0)
			eff.transform.localScale = Vector3(100, 100, 100)
			self._itemHintEff = eff
			local animComponent = eff:GetComponent(typeof(DragonBones.UnityArmatureComponent))
			animComponent.renderTarget = self.effectTarget
			local effAnimation = animComponent.animation

			effAnimation:Play("texiao01", 0)
		end
	end)
end

function GameWindow:_releaseItemGirdHintAnimation(dispose)
	if dispose == nil then
		dispose = false
	end

	if self._itemGridHintEff then
		local animComponent = self._itemGridHintEff:GetComponent(typeof(DragonBones.UnityArmatureComponent))

		animComponent.animation:Stop()
		self._itemGridHintEff:SetActive(false)

		if dispose == false then
			DBResManager.get():pushEffect(self._itemGridHintEff)
		end

		self._itemGridHintEff = nil
	end
end

function GameWindow:_realseItemHintAnimation(dispose)
	if dispose == nil then
		dispose = false
	end

	if not self._showItemHint then
		return
	end

	if self._itemHintEff then
		local animComponent = self._itemHintEff:GetComponent(typeof(DragonBones.UnityArmatureComponent))

		animComponent.animation:Stop()
		self._itemHintEff:SetActive(false)

		if dispose == false then
			DBResManager.get():pushEffect(self._itemHintEff)
		end

		self._itemHintEff = nil
	end

	if self._itemGridHintPos then
		self._itemGridHintPos = nil
	end

	self:_releaseItemGirdHintAnimation()

	self._showItemHint = false
end

function GameWindow:onWindowOpen(event)
	if event.params then
		local windowName = event.params.windowName

		if windowName == "pre_game_window" or windowName == "win_game_window" or windowName == "cooking_window" or windowName == "end_game_window" then
			self:_hideAllIcons()
		end
	end
end

function GameWindow:onH5InGameWindow(event)
	if event.data and event.data.window_name then
		if self._h5InGameWindows[event.data.window_name] then
			if event.data.window_state == 0 then
				self._h5InGameWindows[event.data.window_name] = false

				self:_showAllIcons()
			end
		elseif event.data.window_state == 1 then
			self._h5InGameWindows[event.data.window_name] = true

			self:_hideAllIcons()
		end
	end
end

function GameWindow:_hideAllIcons()
	self.group_top:SetActive(false)
	self.setting_group:SetActive(false)
	self.group_bottom:SetActive(false)
	self.bg_bottom:SetActive(false)

	self.cur_item_click_index = nil
end

function GameWindow:_showAllIcons()
	self.group_top:SetActive(true)
	self.setting_group:SetActive(true)
	self.group_bottom:SetActive(true)
	self.bg_bottom:SetActive(true)
end

function GameWindow:updateFPS(fps, avg, all)
	self.fps_label.text = "FPS: " .. tostring(fps) .. " AVG: " .. tostring(avg) .. "\n" .. tostring(all[1]) .. ", " .. tostring(all[2]) .. ", " .. tostring(all[3]) .. ", " .. tostring(all[4]) .. ", " .. tostring(all[5]) .. ", " .. tostring(all[6]) .. ", " .. tostring(all[7]) .. ", " .. tostring(all[8]) .. ", " .. tostring(all[9]) .. ", " .. tostring(all[10]) .. ", "
end

function GameWindow:updateTouchHandle()
	if not self.canTouch then
		return
	end

	if UNITY_EDITOR or UNITY_STANDALONE then
		self:updateDesktop()
	else
		self:updateMobile()
	end
end

local OP_NONE = 0
local OP_DOWN = 1
local OP_MOVE = 2
local OP_UP = 3
local OP_CANCEL = 4

function GameWindow:updateDesktop()
	local isOverUI = XYDUtils.IsMouseOverUI()

	if isOverUI then
		return
	end

	local currPos = nil
	local phase = OP_NONE

	if Input.GetMouseButtonDown(0) then
		currPos = Input.mousePosition
		phase = OP_DOWN
	elseif Input.GetMouseButton(0) then
		currPos = Input.mousePosition
		phase = OP_MOVE
	elseif Input.GetMouseButtonUp(0) then
		currPos = Input.mousePosition
		phase = OP_UP
	end

	self:processInput(phase, currPos)
end

function GameWindow:updateMobile()
	local isOverUI = XYDUtils.IsFingerOverUI()

	if isOverUI then
		return
	end

	local currPos, currPos2 = nil
	local phase = OP_NONE
	local touchCount = Input.touchCount

	if touchCount == 1 then
		local touch = Input.GetTouch(0)
		currPos = touch.position

		if touch.phase == TouchPhase.Began then
			phase = OP_DOWN
		elseif touch.phase == TouchPhase.Moved or touch.phase == TouchPhase.Stationary then
			phase = OP_MOVE
		elseif touch.phase == TouchPhase.Ended or touch.phase == TouchPhase.Canceled then
			phase = OP_UP
		end
	end

	self:processInput(phase, currPos)
end

function GameWindow:processInput(phase, position)
	if phase == OP_NONE then
		return
	end

	local touchEvent = {}
	local rate = 1080 / UnityEngine.Screen.width
	touchEvent.stageX = position.x
	touchEvent.stageY = xyd.getHeight() - position.y
	touchEvent.localX = (position.x * rate - (xyd.getFixedWidth() / 2 + self.group_board.transform.localPosition.x)) / self._boardScale
	touchEvent.localY = (xyd.getFixedHeight() / 2 + self.group_board.transform.localPosition.y - position.y * rate) / self._boardScale

	if phase == OP_DOWN then
		if self:touchWithinBoardRange(touchEvent) then
			self:onOpDown(touchEvent)
		end
	elseif phase == OP_MOVE then
		self:onDragOnMainField(touchEvent)
	elseif phase == OP_UP and self:touchWithinBoardRange(touchEvent) then
		self:onOpUp(touchEvent)
	end
end

function GameWindow:touchWithinBoardRange(touchEvent)
	if touchEvent.localX >= 0 and touchEvent.localX <= self.BOARD_MAX_WIDTH and touchEvent.localY >= 0 and touchEvent.localY <= self.BOARD_MAX_HEIGHT then
		return true
	end

	return false
end

function GameWindow:setAnnaHead()
	local effName = EffectConstants.ANNA_AVANTAR

	SpineManager.get():newEffect(self.group_head, effName, function (success, eff)
		if success then
			eff.transform.localPosition = Vector3(0, -180, 20)
			eff.transform.localScale = Vector3(50, 50, 100)
			local SpineController = eff:GetComponent(typeof(SpineAnim))
			SpineController.RenderTarget = self.headmask
			SpineController.targetDelta = 1

			SpineController:playOnTrack(0, "idle", -1)
			self.head:SetActive(false)

			self._headEff = eff

			self.bg_head:SetActive(false)

			if not self.headTimer then
				self.headTimer = Timer.New(handler(self, function ()
					xyd.EventDispatcher:inner():dispatchEvent({
						params = 2,
						name = xyd.event.ANNA_HEAD_STATE
					})
				end), 8, -1)

				self.headTimer:Start()
			end
		end
	end)
end

function GameWindow:annaHeadState(event)
	local state = event.params
	local effName = nil

	if tolua.isnull(self._headEff) then
		return
	end

	if state == 4 then
		effName = "encourage"
	end

	if state == 3 then
		effName = "praise"
	end

	if state == 2 then
		if self._board:getGameMode():getMovesLeft() <= 3 then
			return
		end

		effName = "smile"
	end

	local SpineController = self._headEff:GetComponent(typeof(SpineAnim))

	SpineController:playOnTrack(state, effName, 1)
end

function GameWindow:updateAllItem()
	local i = 0

	while i < GameWindow.INGAME_ITEM_NUM do
		self:initItemNumByIndex(i, self["item_num_" .. tostring(tostring(i))])

		self.bottomItemListMap[self._bottomItemList[i + 1]] = i

		self:setItemIconByIndex(i)

		i = i + 1
	end
end

return GameWindow
