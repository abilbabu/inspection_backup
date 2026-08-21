package com.alm.inspectionModule.vehicleInspection.serviceImpl;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;

import com.alm.inspectionModule.exception.ItemNotFoundException;
import com.alm.inspectionModule.settingsModule.dto.TaskComponentDTO;
import com.alm.inspectionModule.settingsModule.entity.AssemblyCodeEntity;
import com.alm.inspectionModule.settingsModule.entity.InspectionTaskComponentEntity;
import com.alm.inspectionModule.settingsModule.entity.RepairGroupEntity;
import com.alm.inspectionModule.settingsModule.repo.AssemblyCodeRepo;
import com.alm.inspectionModule.settingsModule.repo.RepairGroupRepo;
import com.alm.inspectionModule.settingsModule.repo.TaskComponentRepo;
import com.alm.inspectionModule.utils.TokenService;
import com.alm.inspectionModule.vehicleInspection.dto.InspectionFormMasterDTO;
import com.alm.inspectionModule.vehicleInspection.dto.InspectionFormComponentMappingDTO;
import com.alm.inspectionModule.vehicleInspection.entity.InspectionFormMasterEntity;
import com.alm.inspectionModule.vehicleInspection.entity.InspectionFormComponentMappingEntity;
import com.alm.inspectionModule.vehicleInspection.repo.InspectionFormRepo;
import com.alm.inspectionModule.vehicleInspection.repo.InspectionFormComponentMappingRepo;
import com.alm.inspectionModule.vehicleInspection.service.InspectionFormService;

import jakarta.transaction.Transactional;

@Service
public class InspectionFormServiceImpl implements InspectionFormService {

    @Autowired
    private InspectionFormRepo inspectionFormRepository;

    @Autowired
    private InspectionFormComponentMappingRepo inspectionFormComponentMappingRepo;

    @Autowired
    private TokenService tokenService;

    @Autowired
    private InspectionFormRepo InspectionFormRepository;

    @Autowired
    private TaskComponentRepo taskComponentRepo;

    @Autowired
    private AssemblyCodeRepo assemblyCodeRepo;

    @Autowired
    private RepairGroupRepo repairGroupRepo;

    @Override
    @Transactional
    public long saveInspectionForm(InspectionFormMasterDTO dto, String token) {
        Jwt jwt = tokenService.decodeJWTToken(token.substring(7));
        Long userId = jwt.getClaim("scope");
        LocalDateTime now = LocalDateTime.now();
        InspectionFormMasterEntity master;
        if (dto.getInspectionFormId() == null) {
            master = new InspectionFormMasterEntity();
            master.setInspectionFormCreatedBy(userId);
            master.setInspectionFormCreatedOn(now);
        } else {
            master = InspectionFormRepository.findById(dto.getInspectionFormId())
                    .orElseThrow(() -> new RuntimeException("Inspection Form not found"));
            master.getComponentMappings().forEach(m -> {
                m.setInspectionFormComponentDeleteFlag(true);
                m.setInspectionFormComponentUpdatedBy(userId);
                m.setInspectionFormComponentUpdatedOn(now);
            });
            master.getComponentMappings().clear();
        }
        master.setInspectionFormName(dto.getInspectionFormName());
        master.setInspectionFormCategoryId(dto.getInspectionFormCategoryId());
        master.setInspectionFormDescription(dto.getInspectionFormDescription());
        master.setInspectionFormApprovalFlag(dto.getInspectionFormApprovalFlag());
        master.setInspectionFormOdometerFlag(dto.getInspectionFormOdometerFlag());
        master.setInspectionFormUpdatedBy(userId);
        master.setInspectionFormUpdatedOn(now);
        master.setInspectionFormdeleteFlag(false);
        if (dto.getComponentMappings() != null) {
            for (InspectionFormComponentMappingDTO mapDTO : dto.getComponentMappings()) {
                InspectionTaskComponentEntity taskComponent = taskComponentRepo
                        .findById(mapDTO.getInspectionFormComponentId()).orElseThrow(() -> new RuntimeException(
                                "Task Component not found with id " + mapDTO.getInspectionFormComponentId()));
                InspectionFormComponentMappingEntity mapping = new InspectionFormComponentMappingEntity();
                mapping.setInspectionForm(master);
                mapping.setTaskComponent(taskComponent);
                mapping.setInspectionFormComponentCategoryId(mapDTO.getInspectionFormComponentCategoryId());
                mapping.setInspectionFormComponentSortOrder(mapDTO.getInspectionFormComponentSortOrder());
                mapping.setInspectionFormComponentCreatedBy(userId);
                mapping.setInspectionFormComponentCreatedOn(now);
                mapping.setInspectionFormComponentUpdatedBy(userId);
                mapping.setInspectionFormComponentUpdatedOn(now);
                mapping.setInspectionFormComponentDeleteFlag(false);
                master.getComponentMappings().add(mapping);
            }
        }
        InspectionFormMasterEntity saved = InspectionFormRepository.save(master);
        return saved.getInspectionFormId();
    }

    @Override
    public List<InspectionFormMasterDTO> listInspectionForms() {
        List<InspectionFormMasterEntity> entities = InspectionFormRepository
                .findByInspectionFormdeleteFlagFalseOrderByInspectionFormCreatedOnDesc();
        return entities.stream().map(entity -> {
            InspectionFormMasterDTO dto = new InspectionFormMasterDTO();
            dto.setInspectionFormId(entity.getInspectionFormId());
            dto.setInspectionFormName(entity.getInspectionFormName());
            dto.setInspectionFormCategoryId(entity.getInspectionFormCategoryId());
            dto.setInspectionFormDescription(entity.getInspectionFormDescription());
            dto.setInspectionFormApprovalFlag(entity.getInspectionFormApprovalFlag());
            dto.setInspectionFormOdometerFlag(entity.getInspectionFormOdometerFlag());
            dto.setInspectionFormCreatedOn(entity.getInspectionFormCreatedOn());
            dto.setInspectionFormCreatedBy(entity.getInspectionFormCreatedBy());
            return dto;
        }).toList();
    }

    @Override
    @Transactional
    public InspectionFormMasterDTO getInspectionFormById(Long inspectionFormId, String query) {
        InspectionFormMasterEntity master = InspectionFormRepository
                .findByInspectionFormIdAndInspectionFormdeleteFlagFalse(inspectionFormId)
                .orElseThrow(() -> new ItemNotFoundException("Inspection Form not found with id " + inspectionFormId));
        Map<String, AssemblyCodeEntity> assemblyCodeMap = assemblyCodeRepo.findByAssemblyCodeDeleteFlag(false).stream()
                .collect(Collectors.toMap(AssemblyCodeEntity::getAssemblyCode, a -> a, (a, b) -> a));
        Map<Long, RepairGroupEntity> repairGroupMap = repairGroupRepo.findByRepairGroupDeleteFlag(false).stream()
                .collect(Collectors.toMap(RepairGroupEntity::getRepairGroupId, r -> r, (a, b) -> a));
        InspectionFormMasterDTO dto = new InspectionFormMasterDTO();
        dto.setInspectionFormId(master.getInspectionFormId());
        dto.setInspectionFormName(master.getInspectionFormName());
        dto.setInspectionFormCategoryId(master.getInspectionFormCategoryId());
        dto.setInspectionFormDescription(master.getInspectionFormDescription());
        dto.setInspectionFormApprovalFlag(master.getInspectionFormApprovalFlag());
        dto.setInspectionFormCreatedBy(master.getInspectionFormCreatedBy());
        dto.setInspectionFormCreatedOn(master.getInspectionFormCreatedOn());
        List<InspectionFormComponentMappingDTO> componentDTOs = new ArrayList<>();
        List<InspectionFormComponentMappingEntity> mappings;
        if (query != null && !query.trim().isEmpty()) {
            String cleanQuery = query.replaceAll("[\\s-]", "").trim();
            if (cleanQuery.isEmpty()) {
                cleanQuery = query.trim();
            }
            mappings = inspectionFormComponentMappingRepo.searchAssignedComponents(inspectionFormId, cleanQuery);
        } else {
            mappings = master.getComponentMappings();
        }
        if (mappings != null) {
            for (InspectionFormComponentMappingEntity e : mappings) {
                if (Boolean.TRUE.equals(e.getInspectionFormComponentDeleteFlag())) {
                    continue;
                }
                InspectionFormComponentMappingDTO cDto = new InspectionFormComponentMappingDTO();
                cDto.setInspectionFormComponentMappingId(e.getInspectionFormComponentMappingId());
                cDto.setInspectionFormComponentCategoryId(e.getInspectionFormComponentCategoryId());
                cDto.setInspectionFormComponentSortOrder(e.getInspectionFormComponentSortOrder());
                InspectionTaskComponentEntity tc = e.getTaskComponent();
                TaskComponentDTO tcDto = new TaskComponentDTO();
                tcDto.setItcId(tc.getItcId());
                tcDto.setItcName(tc.getItcName());
                tcDto.setItcDescription(tc.getItcDescription());
                tcDto.setAllowGood(tc.getAllowGood());
                tcDto.setAllowRepair(tc.getAllowRepair());
                tcDto.setAllowReplace(tc.getAllowReplace());
                tcDto.setAllowPoor(tc.getAllowPoor());
                tcDto.setAllowPhoto(tc.getAllowPhoto());
                tcDto.setAllowAudio(tc.getAllowAudio());
                tcDto.setAllowMultipleImage(tc.getAllowMultipleImage());
                tcDto.setAllowVideo(tc.getAllowVideo());
                tcDto.setPhotoMandatory(tc.getPhotoMandatory());
                tcDto.setAudioMandatory(tc.getAudioMandatory());
                tcDto.setAllowNotApplicable(tc.getAllowNotApplicable());
                tcDto.setInstructionText(tc.getInstructionText());
                tcDto.setItcCategoryId(tc.getItcCategoryId());
                tcDto.setItcCreatedOn(tc.getItcCreatedOn());
                tcDto.setItcCreatedBy(tc.getItcCreatedBy());
                tcDto.setItcUpdatedOn(tc.getItcUpdatedOn());
                tcDto.setItcUpdatedBy(tc.getItcUpdatedBy());
                tcDto.setItcDeleteFlag(tc.getItcDeleteFlag());
                tcDto.setItcAssemblyCode(tc.getItcAssemblyCode());
                if (tc.getItcAssemblyCode() != null) {
                    AssemblyCodeEntity ac = assemblyCodeMap.get(tc.getItcAssemblyCode());
                    if (ac != null) {
                        tcDto.setAssemblyCodeName(ac.getAssemblyCode());
                        tcDto.setAssemblyCodeDesc(ac.getAssemblyCodeDesc());
                    }
                }
                tcDto.setItcRepairGroup(tc.getItcRepairGroup());
                if (tc.getItcRepairGroup() != null) {
                    try {
                        Long rgId = Long.parseLong(tc.getItcRepairGroup());
                        RepairGroupEntity rg = repairGroupMap.get(rgId);
                        if (rg != null) {
                            tcDto.setRepairGroupName(rg.getRepairGroupName());
                            tcDto.setRepairGroupDesc(rg.getRepairGroupDesc());
                        }
                    } catch (NumberFormatException ignored) {
                    }
                }
                cDto.setTaskComponent(tcDto);
                componentDTOs.add(cDto);
            }
        }
        dto.setComponentMappings(componentDTOs);
        return dto;
    }

    @Override
    @Transactional
    public void deleteInspectionForm(Long inspectionFormId, String token) {
        Jwt jwt = tokenService.decodeJWTToken(token.substring(7));
        Long userId = jwt.getClaim("scope");
        LocalDateTime now = LocalDateTime.now();
        InspectionFormMasterEntity master = inspectionFormRepository
                .findByInspectionFormIdAndInspectionFormdeleteFlagFalse(inspectionFormId)
                .orElseThrow(() -> new ItemNotFoundException("Inspection Form not found"));
        master.setInspectionFormdeleteFlag(true);
        master.setInspectionFormUpdatedBy(userId);
        master.setInspectionFormUpdatedOn(now);
        if (master.getComponentMappings() != null) {
            master.getComponentMappings().forEach(mapping -> {
                mapping.setInspectionFormComponentDeleteFlag(true);
                mapping.setInspectionFormComponentUpdatedBy(userId);
                mapping.setInspectionFormComponentUpdatedOn(now);
            });
        }
        inspectionFormRepository.save(master);
    }

    @Override
    public List<InspectionFormMasterDTO> searchInspectionForms(String name) {
        if (name != null && name.trim().isEmpty()) {
            name = null;
        }
        List<InspectionFormMasterEntity> entities = inspectionFormRepository.searchForms(name);
        return entities.stream().map(entity -> {
            InspectionFormMasterDTO dto = new InspectionFormMasterDTO();
            dto.setInspectionFormId(entity.getInspectionFormId());
            dto.setInspectionFormName(entity.getInspectionFormName());
            dto.setInspectionFormCategoryId(entity.getInspectionFormCategoryId());
            dto.setInspectionFormDescription(entity.getInspectionFormDescription());
            dto.setInspectionFormApprovalFlag(entity.getInspectionFormApprovalFlag());
            dto.setInspectionFormOdometerFlag(entity.getInspectionFormOdometerFlag());
            dto.setInspectionFormCreatedOn(entity.getInspectionFormCreatedOn());
            dto.setInspectionFormCreatedBy(entity.getInspectionFormCreatedBy());
            return dto;
        }).toList();
    }
}