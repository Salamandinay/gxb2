local BaseModel = import(".BaseModel")
local Pet = import("app.models.Pet")
local PetSlot = class("PetSlot", BaseModel)

function PetSlot:ctor()
	PetSlot.super.ctor(self)

	self.list_ = {}
	self.petIDs = {}
	self.petStoryData = {}
end

function PetSlot:reset()
	if PetSlot.INSTANCE then
		PetSlot.INSTANCE:removeEvents()
	end

	PetSlot.INSTANCE = nil
end

function PetSlot:onRegister()
	PetSlot.super:onRegister()
	self:registerEvent(xyd.event.GET_PET_LIST, handler(self, self.onGetList))
	self:registerEvent(xyd.event.ACTIVE_PET, handler(self, self.onActivePet))
	self:registerEvent(xyd.event.PET_LEV_UP, handler(self, self.onPetLevUp))
	self:registerEvent(xyd.event.PET_GRADE_UP, handler(self, self.onPetGradeUp))
	self:registerEvent(xyd.event.PET_SKILL_UP, handler(self, self.onPetSkillUp))
	self:registerEvent(xyd.event.PET_RESTORE, handler(self, self.onRestore))
	self:registerEvent(xyd.event.ACTIVE_PET_EXLEVEL, handler(self, self.onActivePetExlevel))
	self:registerEvent(xyd.event.UPGRADE_PET_EXLEVEL, handler(self, self.onUpgradePetExlevel))
	self:registerEvent(xyd.event.RESET_PET_EXLEVEL, handler(self, self.onResetExLevel))
end

function PetSlot:reqResetExLevel(pet_id)
	local msg = messages_pb.reset_pet_exlevel_req()
	msg.pet_id = pet_id

	xyd.Backend.get():request(xyd.mid.RESET_PET_EXLEVEL, msg)
end

function PetSlot:onResetExLevel(event)
	local petInfo = event.data.pet_info
	local pet = self:getPetByID(petInfo.pet_id)

	if pet then
		pet:populate(petInfo)
	end
end

function PetSlot:reqPetList()
	local msg = messages_pb:get_pet_list_req()

	xyd.Backend.get():request(xyd.mid.GET_PET_LIST, msg)
end

function PetSlot:onGetList(event)
	local list = event.data.list
	self.petIDs = {}
	self.list_ = {}

	for i = 1, #list do
		local info = list[i]
		local isOpen = xyd.tables.petTable:isOpen(info.pet_id)

		if isOpen then
			local pet = Pet.new()

			pet:populate(info)

			self.list_[info.pet_id] = pet

			table.insert(self.petIDs, info.pet_id)
		end
	end
end

function PetSlot:getPetByID(petID)
	return self.list_[petID]
end

function PetSlot:getList()
	return self.list_
end

function PetSlot:getPetIDs()
	return self.petIDs
end

function PetSlot:activePet(petID)
	local msg = messages_pb:active_pet_req()
	msg.pet_id = tonumber(petID)

	xyd.Backend.get():request(xyd.mid.ACTIVE_PET, msg)
end

function PetSlot:onActivePet(event)
	local petInfo = event.data.pet_info
	local pet = self:getPetByID(petInfo.pet_id)

	if pet then
		pet:populate(petInfo)
	end
end

function PetSlot:reqLevUp(petID, num)
	local msg = messages_pb:pet_lev_up_req()
	msg.pet_id = tonumber(petID)
	msg.num = num

	xyd.Backend:get():request(xyd.mid.PET_LEV_UP, msg)
end

function PetSlot:onPetLevUp(event)
	local petInfo = event.data.pet_info
	local pet = self:getPetByID(petInfo.pet_id)

	if pet then
		pet:populate(petInfo)
	end
end

function PetSlot:reqGradeUp(petID)
	local msg = messages_pb:pet_grade_up_req()
	msg.pet_id = tonumber(petID)

	xyd.Backend.get():request(xyd.mid.PET_GRADE_UP, msg)
end

function PetSlot:onPetGradeUp(event)
	local petInfo = event.data.pet_info
	local pet = self:getPetByID(petInfo.pet_id)

	if pet then
		pet:populate(petInfo)
	end
end

function PetSlot:reqPetSkillUp(petID, index, num)
	local msg = messages_pb:pet_skill_up_req()
	msg.pet_id = tonumber(petID)
	msg.num = tonumber(num)
	msg.index = tonumber(index)

	xyd.Backend:get():request(xyd.mid.PET_SKILL_UP, msg)
end

function PetSlot:onPetSkillUp(event)
	local petInfo = event.data.pet_info
	local pet = self:getPetByID(petInfo.pet_id)

	if pet then
		pet:populate(petInfo)
	end
end

function PetSlot:reqRestore(petID)
	local msg = messages_pb:pet_restore_req()
	msg.pet_id = tonumber(petID)

	xyd.Backend:get():request(xyd.mid.PET_RESTORE, msg)
end

function PetSlot:onRestore(event)
	local petInfo = event.data.pet_info
	local pet = self:getPetByID(petInfo.pet_id)

	if pet then
		pet:populate(petInfo)
	end
end

function PetSlot:getStoryData(petId_)
	if self.petStoryData[petId_] then
		return self.petStoryData[petId_]
	end

	local petStoryTable = xyd.tables.petStoryTable
	local petStoryTextTbale = xyd.tables.petStoryTextTable
	local petStoryDatas = {}
	local ids = petStoryTable:getIds()

	for _, id in pairs(ids) do
		local petId = petStoryTable:getPetId(id)

		if petId == petId_ then
			local data = {
				id = id,
				unLockValue = petStoryTable:getUnLockValue(id),
				title = petStoryTextTbale:getTitle(id),
				text = petStoryTextTbale:getText(id)
			}

			table.insert(petStoryDatas, data)
		end
	end

	self.petStoryData[petId_] = petStoryDatas

	return self.petStoryData[petId_]
end

function PetSlot:actviePetExlevel(petID)
	local msg = messages_pb:active_pet_exlevel_req()
	msg.pet_id = tonumber(petID)

	xyd.Backend.get():request(xyd.mid.ACTIVE_PET_EXLEVEL, msg)
end

function PetSlot:onActivePetExlevel(event)
	local petInfo = event.data.pet_info
	local pet = self:getPetByID(petInfo.pet_id)

	if pet then
		pet:populate(petInfo)
	end
end

function PetSlot:upgradePetExlevel(petID, num)
	local msg = messages_pb:upgrade_pet_exlevel_req()
	msg.pet_id = tonumber(petID)
	msg.num = tonumber(num)

	xyd.Backend.get():request(xyd.mid.UPGRADE_PET_EXLEVEL, msg)
end

function PetSlot:onUpgradePetExlevel(event)
	local petInfo = event.data.pet_info
	local pet = self:getPetByID(petInfo.pet_id)

	if pet then
		pet:populate(petInfo)
	end
end

function PetSlot:getAllPetLev()
	local allLev = 0

	for petId, pet in pairs(self.list_) do
		if pet then
			local lev = pet:getLevel()
			allLev = allLev + lev
		end
	end

	return allLev
end

return PetSlot
