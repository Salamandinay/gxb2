local ActivitySpaceExplorePartnerUpWindow = class("ActivitySpaceExplorePartnerUpWindow", import(".BaseWindow"))

function ActivitySpaceExplorePartnerUpWindow:ctor(name, params)
	if not params.level or params.level == 0 then
		params.level = 1
	end

	function params.playOpenAnimationTweenCal(alpha)
		if self.personEffect then
			self.personEffect:setAlpha(alpha)
		end
	end

	function params.playCloseAnimationTweenCal(alpha)
		if self.personEffect then
			self.personEffect:setAlpha(alpha)
		end
	end

	ActivitySpaceExplorePartnerUpWindow.super.ctor(self, name, params)
end

function ActivitySpaceExplorePartnerUpWindow:initWindow()
	self:getUIComponent()
	self:registerEvent()
	self:layout()
end

function ActivitySpaceExplorePartnerUpWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.e_Image = self.groupAction:ComponentByName("e:Image", typeof(UISprite))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.upBtn = self.groupAction:NodeByName("upBtn").gameObject
	self.upBtn_button_label = self.upBtn:ComponentByName("button_label", typeof(UILabel))
	self.upBtn_button_boxCollider = self.upBtn:GetComponent(typeof(UnityEngine.BoxCollider))
	self.getBtn = self.groupAction:NodeByName("getBtn").gameObject
	self.getBtn_button_label = self.getBtn:ComponentByName("button_label", typeof(UILabel))
	self.upCon = self.groupAction:NodeByName("upCon").gameObject
	self.levelImg = self.upCon:ComponentByName("levelImg", typeof(UISprite))
	self.lineImg = self.upCon:ComponentByName("lineImg", typeof(UISprite))
	self.nameLabel = self.upCon:ComponentByName("nameLabel", typeof(UILabel))
	self.levelLabel = self.upCon:ComponentByName("levelLabel", typeof(UILabel))
	self.personEffect = self.upCon:ComponentByName("personEffect", typeof(UITexture))
	self.centerCon = self.groupAction:NodeByName("centerCon").gameObject
	self.centerConBg = self.centerCon:ComponentByName("centerConBg", typeof(UISprite))
	self.resetBtn = self.groupAction:NodeByName("resetBtn").gameObject
	self.attr_blood = self.centerCon:NodeByName("attr_blood").gameObject
	self.labelName_blood = self.attr_blood:ComponentByName("labelName", typeof(UILabel))
	self.labelValue_blood = self.attr_blood:ComponentByName("labelValue", typeof(UILabel))
	self.labelValueNext_blood = self.attr_blood:ComponentByName("labelValueNext", typeof(UILabel))
	self.arrow_blood = self.attr_blood:ComponentByName("arrow", typeof(UISprite))
	self.attr_attack = self.centerCon:NodeByName("attr_attack").gameObject
	self.labelName_attack = self.attr_attack:ComponentByName("labelName", typeof(UILabel))
	self.labelValue_attack = self.attr_attack:ComponentByName("labelValue", typeof(UILabel))
	self.labelValueNext_attack = self.attr_attack:ComponentByName("labelValueNext", typeof(UILabel))
	self.arrow_attack = self.attr_attack:ComponentByName("arrow", typeof(UISprite))
	self.attr_guard = self.centerCon:NodeByName("attr_guard").gameObject
	self.labelName_guard = self.attr_guard:ComponentByName("labelName", typeof(UILabel))
	self.labelValue_guard = self.attr_guard:ComponentByName("labelValue", typeof(UILabel))
	self.labelValueNext_guard = self.attr_guard:ComponentByName("labelValueNext", typeof(UILabel))
	self.arrow_guard = self.attr_guard:ComponentByName("arrow", typeof(UISprite))
	self.effectCon = self.centerCon:ComponentByName("effectCon", typeof(UITexture))
	self.attr_skill = self.centerCon:NodeByName("attr_skill").gameObject
	self.imgBg_skill = self.attr_skill:ComponentByName("imgBg", typeof(UISprite))
	self.labelName_skill = self.attr_skill:ComponentByName("labelName", typeof(UILabel))
	self.skillBg = self.attr_skill:ComponentByName("skillBg", typeof(UISprite))
	self.skill_label = self.skillBg:ComponentByName("skill_label", typeof(UILabel))
	self.itemCon = self.groupAction:NodeByName("itemCon").gameObject
	self.itemShowCon = self.itemCon:NodeByName("itemShowCon").gameObject
	self.puzzleLabelCon = self.itemCon:NodeByName("puzzleLabelCon").gameObject
	self.puzzleLabelCon_UILayout = self.itemCon:ComponentByName("puzzleLabelCon", typeof(UILayout))
	self.puzzleLabelLeft = self.puzzleLabelCon:ComponentByName("puzzleLabelLeft", typeof(UILabel))
	self.puzzleLabelRight = self.puzzleLabelCon:ComponentByName("puzzleLabelRight", typeof(UILabel))

	if xyd.Global.lang == "fr_fr" then
		self.labelName_skill.width = 130
		self.imgBg_skill.gameObject:GetComponent(typeof(UIWidget)).width = 146

		self.imgBg_skill.gameObject:X(-9)
	end

	if self.params_.is_short then
		self.e_Image.height = 500

		self.itemCon:SetActive(false)
		self.upBtn:SetActive(false)
		self:hideNextValueShow()
		self.resetBtn:SetActive(false)
	end
end

function ActivitySpaceExplorePartnerUpWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	UIEventListener.Get(self.upBtn.gameObject).onClick = handler(self, self.onLevelTouchUp)
	UIEventListener.Get(self.resetBtn.gameObject).onClick = handler(self, self.onResetTouchUp)

	self.eventProxy_:addEventListener(xyd.event.SPACE_EXPLORE_LEVEL_UP, handler(self, self.levelUpBack))
end

function ActivitySpaceExplorePartnerUpWindow:layout()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPACE_EXPLORE)
	self.labelTitle.text = __("PARTNER_DETAIL")
	self.labelName_blood.text = __("HP")
	self.labelName_attack.text = __("ATKP")
	self.labelName_guard.text = __("ARMP")
	self.labelName_skill.text = __("TRAVEL_MAIN_TEXT06")
	self.upBtn_button_label.text = __("LEV_UP")
	self.id = self.params_.id
	local nameId = xyd.tables.activitySpaceExplorePartnerTable:getNameId(self.id)
	self.nameLabel.text = xyd.tables.partnerTextTable:getName(nameId)
	local modelId = xyd.tables.activitySpaceExplorePartnerTable:getPartnerModel(self.id)
	local modelName = xyd.tables.modelTable:getModelName(modelId)
	self.personEffect = xyd.Spine.new(self.personEffect.gameObject)

	self.personEffect:setInfo(modelName, function ()
		self.personEffect:play("idle", 0)

		local scale = xyd.tables.modelTable:getScale(modelId)

		self.personEffect:SetLocalScale(scale, scale, scale)
		self.personEffect:SetLocalPosition(37, -24, 0)
	end)

	local type = xyd.tables.activitySpaceExplorePartnerTable:getGrade(self.id)

	xyd.setUISpriteAsync(self.levelImg, nil, "activity_space_explore_icon_level_" .. type, nil, )

	local skill_ids = xyd.tables.activitySpaceExplorePartnerTable:getSkillId(self.id)

	if not next(skill_ids) then
		self.skill_label.text = __("ACTIVITY_SPACE_NO_SKILL")
	end

	self:updateAttr()

	if not self.is_short then
		local level_cost_arr = xyd.tables.activitySpaceExplorePartnerTable:getLvCost1(self.id)
		local item = {
			notShowGetWayBtn = true,
			show_has_num = true,
			itemID = level_cost_arr[1],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			scale = Vector3(0.79, 0.79, 1),
			uiRoot = self.itemShowCon.gameObject
		}
		local icon = xyd.getItemIcon(item)

		self:updateCostNum()
	end
end

function ActivitySpaceExplorePartnerUpWindow:onLevelTouchUp()
	if self.activityData and self.activityData:getEndTime() <= xyd.getServerTime() then
		xyd.alertTips(__("ACTIVITY_END_YET"))

		return
	end

	local now_num = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_SPACE_EXPLORE_UP_PARTNER)
	local need_num = self:getNeedConstNum()

	if now_num < need_num then
		xyd.alert(xyd.AlertType.TIPS, __("SPACE_EXPLORE_TEXT_10"))
		self:updateAttr(self.level)
		self:updateCostNum()

		return
	end

	local msg = messages_pb:space_explore_level_up_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_SPACE_EXPLORE
	msg.table_id = tonumber(self.id)
	msg.num = tonumber(1)

	xyd.Backend.get():request(xyd.mid.SPACE_EXPLORE_LEVEL_UP, msg)
end

function ActivitySpaceExplorePartnerUpWindow:onResetTouchUp()
	if self.activityData and self.activityData:getEndTime() <= xyd.getServerTime() then
		xyd.alertTips(__("ACTIVITY_END_YET"))

		return
	end

	if self.level == 1 then
		xyd.alert(xyd.AlertType.TIPS, __("SPACE_EXPLORE_TEXT_28"))

		return
	end

	local costArr = xyd.tables.miscTable:split2num("space_explore_restore_cost", "value", "#")

	xyd.alert(xyd.AlertType.YES_NO, __("SPACE_EXPLORE_TEXT_27", tonumber(costArr[2])), function (yes_no)
		if yes_no then
			local now_num = xyd.models.backpack:getItemNumByID(tonumber(costArr[1]))
			local need_num = tonumber(costArr[2])

			if now_num < need_num then
				xyd.alert(xyd.AlertType.TIPS, __("SPIRIT_UPGRADE_FAIL", xyd.tables.itemTextTable:getName(tonumber(costArr[1]))))

				return
			end

			local msg = messages_pb:space_explore_level_up_req()
			msg.activity_id = xyd.ActivityID.ACTIVITY_SPACE_EXPLORE
			msg.table_id = tonumber(self.id)
			msg.num = 1 - tonumber(self.level)

			xyd.Backend.get():request(xyd.mid.SPACE_EXPLORE_LEVEL_UP, msg)
		end
	end)
end

function ActivitySpaceExplorePartnerUpWindow:levelUpBack(event)
	local data = xyd.decodeProtoBuf(event.data)

	if tonumber(data.table_id) == tonumber(self.id) then
		self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPACE_EXPLORE)
		local index = -1
		local ids = xyd.tables.activitySpaceExplorePartnerTable:getIDs()

		for i in pairs(ids) do
			if data.id == tonumber(ids[i]) then
				index = i

				break
			end
		end

		if index ~= -1 then
			self.level = self.activityData.detail.partner[index]
		elseif data.num > 0 then
			self.level = self.level + 1
			local max_lev = xyd.tables.activitySpaceExplorePartnerTable:getMaxLv(self.id)

			if max_lev < self.level then
				self.level = max_lev
			end
		else
			self.level = self.level + data.num

			if self.level < 0 then
				self.level = 1
			end
		end

		if data.num < 0 then
			self:showNextValueShow()

			self.upBtn_button_label.text = __("LEV_UP")
			self.upBtn_button_boxCollider.enabled = true

			xyd.applyChildrenOrigin(self.upBtn.gameObject)
			self.itemCon:SetActive(true)
		end

		self:playUpEffect()
		self:updateAttr(self.level)
		self:updateCostNum()
		self:waitForTime(0.2, function ()
			self:updateCostNum()
			self:updateAttr(self.level)
		end)
	end
end

function ActivitySpaceExplorePartnerUpWindow:updateCostNum()
	local now_num = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_SPACE_EXPLORE_UP_PARTNER)
	local need_num = self:getNeedConstNum()
	self.puzzleLabelLeft.text = tostring(now_num)
	self.puzzleLabelRight.text = "/" .. tostring(need_num)

	if now_num < need_num then
		self.puzzleLabelLeft.color = Color.New2(3422556671.0)
	else
		self.puzzleLabelLeft.color = Color.New2(960513791)
	end

	self.puzzleLabelCon_UILayout:Reposition()
end

function ActivitySpaceExplorePartnerUpWindow:getNeedConstNum()
	return xyd.tables.activitySpaceExplorePartnerTable:getLvCost1(self.id)[2] + (self.level - 1) * xyd.tables.activitySpaceExplorePartnerTable:getLvCost2(self.id)[2]
end

function ActivitySpaceExplorePartnerUpWindow:updateAttr(updateLevel)
	local level = updateLevel
	level = level or self.params_.level

	if not level or level <= 0 then
		level = 1
	end

	self.level = level
	local max_lev = xyd.tables.activitySpaceExplorePartnerTable:getMaxLv(self.id)

	if max_lev <= level then
		level = max_lev

		self:hideNextValueShow()

		self.upBtn_button_label.text = __("ACTIVITY_SPACE_MAX_LEVEL")
		self.upBtn_button_boxCollider.enabled = false

		xyd.applyChildrenGrey(self.upBtn.gameObject)
		self.itemCon:SetActive(false)

		self.levelLabel.text = "LV." .. max_lev
		self.labelValue_blood.text = xyd.tables.activitySpaceExplorePartnerTable:getBaseHp(self.id) + xyd.tables.activitySpaceExplorePartnerTable:getGrowHp(self.id) * (level - 1)
		self.labelValue_attack.text = xyd.tables.activitySpaceExplorePartnerTable:getBaseAtk(self.id) + xyd.tables.activitySpaceExplorePartnerTable:getGrowAtk(self.id) * (level - 1)
		self.labelValue_guard.text = xyd.tables.activitySpaceExplorePartnerTable:getBaseArm(self.id) + xyd.tables.activitySpaceExplorePartnerTable:getGrowArm(self.id) * (level - 1)
	else
		self.labelValue_blood.text = xyd.tables.activitySpaceExplorePartnerTable:getBaseHp(self.id) + xyd.tables.activitySpaceExplorePartnerTable:getGrowHp(self.id) * (level - 1)
		self.labelValue_attack.text = xyd.tables.activitySpaceExplorePartnerTable:getBaseAtk(self.id) + xyd.tables.activitySpaceExplorePartnerTable:getGrowAtk(self.id) * (level - 1)
		self.labelValue_guard.text = xyd.tables.activitySpaceExplorePartnerTable:getBaseArm(self.id) + xyd.tables.activitySpaceExplorePartnerTable:getGrowArm(self.id) * (level - 1)
		local next_level = level + 1
		self.labelValueNext_blood.text = xyd.tables.activitySpaceExplorePartnerTable:getBaseHp(self.id) + xyd.tables.activitySpaceExplorePartnerTable:getGrowHp(self.id) * (next_level - 1)
		self.labelValueNext_attack.text = xyd.tables.activitySpaceExplorePartnerTable:getBaseAtk(self.id) + xyd.tables.activitySpaceExplorePartnerTable:getGrowAtk(self.id) * (next_level - 1)
		self.labelValueNext_guard.text = xyd.tables.activitySpaceExplorePartnerTable:getBaseArm(self.id) + xyd.tables.activitySpaceExplorePartnerTable:getGrowArm(self.id) * (next_level - 1)
		self.levelLabel.text = "LV." .. level
	end

	local skill_ids = xyd.tables.activitySpaceExplorePartnerTable:getSkillId(self.id)

	if next(skill_ids) then
		local skill_lv_Arr = xyd.tables.activitySpaceExplorePartnerTable:getSkillLv(self.id)
		local values = {}

		for _, skill_id in ipairs(skill_ids) do
			local type = xyd.tables.activitySpaceExploreSkillTable:getType1(skill_id)

			if type ~= 4 and type ~= 5 then
				local skill_lv_index = 1

				for i in pairs(skill_lv_Arr) do
					if skill_lv_Arr[i] <= level then
						skill_lv_index = skill_lv_index + 1
					else
						break
					end
				end

				local skill_value = xyd.tables.activitySpaceExploreSkillTable:getValue(skill_id)[skill_lv_index] * 100 .. "%"

				table.insert(values, skill_value)
			end
		end

		local skillTextId = xyd.tables.activitySpaceExplorePartnerTable:getSkillTextId(self.id)
		self.skill_label.text = xyd.tables.activitySpaceExploreSkillTextTable:getDesc(skillTextId, values)
	end
end

function ActivitySpaceExplorePartnerUpWindow:hideNextValueShow()
	self.labelValueNext_blood:SetActive(false)
	self.labelValueNext_attack:SetActive(false)
	self.labelValueNext_guard:SetActive(false)
	self.arrow_blood:SetActive(false)
	self.arrow_attack:SetActive(false)
	self.arrow_guard:SetActive(false)
	self.labelValue_blood:X(340)
	self.labelValue_attack:X(340)
	self.labelValue_guard:X(340)
end

function ActivitySpaceExplorePartnerUpWindow:showNextValueShow()
	self.labelValueNext_blood:SetActive(true)
	self.labelValueNext_attack:SetActive(true)
	self.labelValueNext_guard:SetActive(true)
	self.arrow_blood:SetActive(true)
	self.arrow_attack:SetActive(true)
	self.arrow_guard:SetActive(true)
	self.labelValue_blood:X(156)
	self.labelValue_attack:X(156)
	self.labelValue_guard:X(156)
end

function ActivitySpaceExplorePartnerUpWindow:playUpEffect()
	if self.isEffectPlaying then
		return
	end

	self.isEffectPlaying = true

	if not self.up_effect then
		self.up_effect = xyd.Spine.new(self.effectCon.gameObject)

		self.up_effect:setInfo("fx_ui_saoxing", function ()
			self.up_effect:play("texiao01", 1, 1, function ()
				self.isEffectPlaying = false
			end)
		end)
	else
		self.up_effect:play("texiao01", 1, 1, function ()
			self.isEffectPlaying = false
		end)
	end
end

function ActivitySpaceExplorePartnerUpWindow:willClose()
	ActivitySpaceExplorePartnerUpWindow.super.willClose(self)

	local activitySpaceUpWd = xyd.WindowManager.get():getWindow("activity_space_explore_team_window")

	if activitySpaceUpWd then
		activitySpaceUpWd:updateOneLevel(self.id, self.level)
	end

	local mapWd = xyd.WindowManager.get():getWindow("activity_space_explore_map_window")

	if mapWd then
		mapWd:checkIfCanUpPartner()
	end
end

return ActivitySpaceExplorePartnerUpWindow
