package com.alm.inspectionModule.settingsModule.serviceImpl;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;

import com.alm.inspectionModule.exception.ConstrainViolationException;
import com.alm.inspectionModule.exception.InternalErrorException;
import com.alm.inspectionModule.exception.ItemExistsException;
import com.alm.inspectionModule.exception.ItemNotFoundException;
import com.alm.inspectionModule.exception.NotNullException;
import com.alm.inspectionModule.settingsModule.dto.AssemblyCodeDTO;
import com.alm.inspectionModule.settingsModule.dto.AvailabilityDTO;
import com.alm.inspectionModule.settingsModule.dto.CustomerTypeDTO;
import com.alm.inspectionModule.settingsModule.dto.ExpirationTimeDTO;
import com.alm.inspectionModule.settingsModule.dto.FuelTypeDTO;
import com.alm.inspectionModule.settingsModule.dto.ImageSettingsListDTO;
import com.alm.inspectionModule.settingsModule.dto.InspectionImageDTO;
import com.alm.inspectionModule.settingsModule.dto.InspectionSettingsDTO;
import com.alm.inspectionModule.settingsModule.dto.ItemTypeDTO;
import com.alm.inspectionModule.settingsModule.dto.RepairGroupDTO;
import com.alm.inspectionModule.settingsModule.dto.ServiceTypeDTO;
import com.alm.inspectionModule.settingsModule.dto.TaskCategoryDTO;
import com.alm.inspectionModule.settingsModule.dto.TaskComponentDTO;
import com.alm.inspectionModule.settingsModule.dto.TransmissionTypeDTO;
import com.alm.inspectionModule.settingsModule.dto.VehicleEssentialsDTO;
import com.alm.inspectionModule.settingsModule.dto.VendorDTO;
import com.alm.inspectionModule.settingsModule.entity.AssemblyCodeEntity;
import com.alm.inspectionModule.settingsModule.entity.AvailabilityEntity;
import com.alm.inspectionModule.settingsModule.entity.CustomerTypeEntity;
import com.alm.inspectionModule.settingsModule.entity.ExpirationTimeEntity;
import com.alm.inspectionModule.settingsModule.entity.FuelTypeEntity;
import com.alm.inspectionModule.settingsModule.entity.InspectionImageMasterEntity;
import com.alm.inspectionModule.settingsModule.entity.InspectionSettingsMasterEntity;
import com.alm.inspectionModule.settingsModule.entity.InspectionTaskComponentEntity;
import com.alm.inspectionModule.settingsModule.entity.ItemTypeEntity;
import com.alm.inspectionModule.settingsModule.entity.PlateCodeEntity;
import com.alm.inspectionModule.settingsModule.entity.PlateEmirateEntity;
import com.alm.inspectionModule.settingsModule.entity.RepairGroupEntity;
import com.alm.inspectionModule.settingsModule.entity.ServiceTypeEntity;
import com.alm.inspectionModule.settingsModule.entity.TaskCategoryEntity;
import com.alm.inspectionModule.settingsModule.entity.TransmissionTypeEntity;
import com.alm.inspectionModule.settingsModule.entity.VehicleEssentialsEntity;
import com.alm.inspectionModule.settingsModule.entity.VendorEntity;
import com.alm.inspectionModule.settingsModule.repo.AssemblyCodeRepo;
import com.alm.inspectionModule.settingsModule.repo.AvailabilityRepo;
import com.alm.inspectionModule.settingsModule.repo.CustomerTypeRepo;
import com.alm.inspectionModule.settingsModule.repo.ExpirationTimeRepository;
import com.alm.inspectionModule.settingsModule.repo.FuelTypeRepo;
import com.alm.inspectionModule.settingsModule.repo.InspectionSettingsMasterRepo;
import com.alm.inspectionModule.settingsModule.repo.ItemTypeRepo;
import com.alm.inspectionModule.settingsModule.repo.PlateCodeRepo;
import com.alm.inspectionModule.settingsModule.repo.PlateEmirateRepo;
import com.alm.inspectionModule.settingsModule.repo.RepairGroupRepo;
import com.alm.inspectionModule.settingsModule.repo.ServiceTypeRepo;
import com.alm.inspectionModule.settingsModule.repo.TaskCategoryRepo;
import com.alm.inspectionModule.settingsModule.repo.TaskComponentRepo;
import com.alm.inspectionModule.settingsModule.repo.TransmissionTypeRepo;
import com.alm.inspectionModule.settingsModule.repo.VehicleEssentialRepo;
import com.alm.inspectionModule.settingsModule.repo.VendorRepo;
import com.alm.inspectionModule.settingsModule.service.INSPSettingsService;
import com.alm.inspectionModule.utils.TokenService;
import com.amazonaws.services.kms.model.NotFoundException;

import jakarta.transaction.Transactional;
import jakarta.validation.Valid;

@Service
public class INSPSettingsServiceImpl implements INSPSettingsService {

    @Autowired
    private PlateEmirateRepo plateEmirateRepo;

    @Autowired
    private PlateCodeRepo plateCodeRepo;

    @Autowired
    private TaskCategoryRepo taskCategoryRepo;

    @Autowired
    private TokenService tokenService;

    @Autowired
    private TaskComponentRepo taskComponentRepo;

    @Autowired
    private FuelTypeRepo fuelTypeRepo;

    @Autowired
    private TransmissionTypeRepo transmissionTypeRepo;

    @Autowired
    private ServiceTypeRepo serviceTypeRepo;

    @Autowired
    private CustomerTypeRepo customerTypeRepo;

    @Autowired
    private VehicleEssentialRepo vehicleEssentialRepo;

    @Autowired
    private InspectionSettingsMasterRepo inspectionSettingsMasterRepo;

    @Autowired
    private ExpirationTimeRepository expirationTimeRepo;

    @Autowired
    private ItemTypeRepo itemTypeRepo;

    @Autowired
    private VendorRepo vendorRepository;

    @Autowired
    private AvailabilityRepo availabilityRepo;

    @Autowired
    private AssemblyCodeRepo assemblyCodeRepo;

    @Autowired
    private RepairGroupRepo repairGroupRepo;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    public Map<String, List<String>> getEmiratePlateCodes(String token) {
        tokenService.validateToken(token);
        List<PlateEmirateEntity> emirates = plateEmirateRepo.findByPeDeleteFlagFalse();
        Map<String, List<String>> resultMap = new java.util.LinkedHashMap<>();
        for (PlateEmirateEntity em : emirates) {
            List<PlateCodeEntity> codes = plateCodeRepo.findByPcEmirateAndPcDeleteFlagFalse(em);
            List<String> codeStrings = codes.stream()
                    .map(PlateCodeEntity::getPcCode)
                    .collect(Collectors.toList());
            resultMap.put(em.getPeName(), codeStrings);
        }
        return resultMap;
    }

    @Override
    public long saveTaskCategory(@Valid TaskCategoryDTO taskCategory, String token) {
        TaskCategoryEntity tsentries = new TaskCategoryEntity();
        try {
            BeanUtils.copyProperties(taskCategory, tsentries);
            Jwt jwtDetails = tokenService.decodeJWTToken(token.substring(7));
            tsentries.setTaskCategoryCreatedBy(jwtDetails.getClaim("scope"));
            tsentries.setTaskCategoryUpdatedBy(jwtDetails.getClaim("scope"));
            TaskCategoryEntity ret = taskCategoryRepo.save(tsentries);
            return ret.getTaskCategoryId();
        } catch (DataIntegrityViolationException e) {
            String rootCauseMessage = e.getMostSpecificCause().getMessage();
            if (rootCauseMessage.contains("unique constraint") || rootCauseMessage.contains("Duplicate entry")) {
                throw new ItemExistsException("Duplicate entry detected.");
            } else if (rootCauseMessage.contains("foreign key constraint")) {
                throw new ConstrainViolationException("Invalid reference detected.");
            } else if (rootCauseMessage.contains("cannot be null")) {
                throw new NotNullException("Required field missing.");
            } else {
                throw e;
            }
        } catch (Exception ex) {
            throw ex;
        }
    }

    @Override
    public List<TaskCategoryDTO> getAllTaskCategoryList() {
        List<TaskCategoryDTO> taskCategoryDTO = new ArrayList<>();
        try {
            List<TaskCategoryEntity> taxingData = taskCategoryRepo.findByTaskCategorydeleteFlag(false);
            for (TaskCategoryEntity entity : taxingData) {
                TaskCategoryDTO dto = new TaskCategoryDTO();
                BeanUtils.copyProperties(entity, dto);
                taskCategoryDTO.add(dto);
            }
        } catch (Exception ex) {
            throw ex;
        }
        return taskCategoryDTO;
    }

    @Override
    public TaskCategoryDTO getTaskCategoryById(long taskCategoryId) {
        return taskCategoryRepo.findById(taskCategoryId).map(entity -> {
            TaskCategoryDTO taxingDetailsDTO = new TaskCategoryDTO();
            BeanUtils.copyProperties(entity, taxingDetailsDTO);
            return taxingDetailsDTO;
        }).orElseThrow(() -> new ItemNotFoundException("Task Category not found with id " + taskCategoryId));
    }

    @Override
    public TaskCategoryDTO updateTaskCategory(@Valid TaskCategoryDTO taskCategory, String token) {
        try {
            TaskCategoryEntity taxingEntity = taskCategoryRepo.findById(taskCategory.getTaskCategoryId())
                    .orElseThrow(() -> new ItemNotFoundException(
                            "Task Category not found with id " + taskCategory.getTaskCategoryId()));
            Jwt jwtDetails = tokenService.decodeJWTToken(token.substring(7));
            taxingEntity.setTaskCategoryUpdatedBy(jwtDetails.getClaim("scope"));
            taxingEntity.setTaskCategorydeleteFlag(taskCategory.getTaskCategorydeleteFlag());
            taxingEntity.setTaskCategoryDescription(taskCategory.getTaskCategoryDescription());
            taxingEntity.setTaskCategoryName(taskCategory.getTaskCategoryName());
            taxingEntity.setTaskCategoryUpdatedOn(LocalDateTime.now());
            TaskCategoryEntity savedEntity = taskCategoryRepo.save(taxingEntity);
            TaskCategoryDTO responseDto = new TaskCategoryDTO();
            BeanUtils.copyProperties(savedEntity, responseDto);
            return responseDto;
        } catch (DataIntegrityViolationException e) {
            String rootCauseMessage = e.getMostSpecificCause().getMessage();
            if (rootCauseMessage.contains("unique constraint") || rootCauseMessage.contains("Duplicate entry")) {
                throw new ItemExistsException("Duplicate entry detected.");
            } else if (rootCauseMessage.contains("foreign key constraint")) {
                throw new ConstrainViolationException("Invalid reference detected.");
            } else if (rootCauseMessage.contains("cannot be null")) {
                throw new NotNullException("Required field missing.");
            } else {
                throw e;
            }
        } catch (Exception ex) {
            throw ex;
        }
    }

    @Override
    public TaskCategoryDTO deleteTaskCategory(@Valid Long taskCategoryId, String token) {
        TaskCategoryDTO tcDetail = new TaskCategoryDTO();
        try {
            Optional<TaskCategoryEntity> tcMaster = taskCategoryRepo.findById(taskCategoryId);
            Jwt jwtDetails = tokenService.decodeJWTToken(token.substring(7));
            tcMaster.get().setTaskCategoryUpdatedBy(jwtDetails.getClaim("scope"));
            tcMaster.get().setTaskCategorydeleteFlag(true);
            TaskCategoryEntity ret = taskCategoryRepo.save(tcMaster.get());
            BeanUtils.copyProperties(tcMaster.get(), tcDetail);
            if (ret != null)
                return tcDetail;
            else
                return null;
        } catch (DataIntegrityViolationException e) {
            String rootCauseMessage = e.getMostSpecificCause().getMessage();
            if (rootCauseMessage.contains("unique constraint") || rootCauseMessage.contains("Duplicate entry")) {
                throw new ItemExistsException("Duplicate entry detected.");
            } else if (rootCauseMessage.contains("foreign key constraint")) {
                throw new ConstrainViolationException("Invalid reference detected.");
            } else if (rootCauseMessage.contains("cannot be null")) {
                throw new NotNullException("Required field missing.");
            } else {
                throw e;
            }
        } catch (Exception ex) {
            throw ex;
        }
    }

    @Override
    @Transactional
    public List<TaskComponentDTO> getComponentList() {
        List<InspectionTaskComponentEntity> entities = taskComponentRepo
                .findByItcDeleteFlagFalseOrderByItcCreatedOnDesc();
        List<TaskComponentDTO> list = new ArrayList<>();
        for (InspectionTaskComponentEntity entity : entities) {
            TaskComponentDTO dto = new TaskComponentDTO();
            dto.setItcId(entity.getItcId());
            dto.setItcName(entity.getItcName());
            dto.setItcDescription(entity.getItcDescription());
            dto.setItcCategoryId(entity.getItcCategoryId());
            dto.setItcRepairGroup(entity.getItcRepairGroup());
            dto.setItcAssemblyCode(entity.getItcAssemblyCode());
            if (entity.getItcAssemblyCode() != null) {
                Optional<AssemblyCodeEntity> assemblyOpt = assemblyCodeRepo
                        .findById(Long.valueOf(entity.getItcAssemblyCode()));
                if (assemblyOpt.isPresent()) {
                    AssemblyCodeEntity assembly = assemblyOpt.get();
                    dto.setAssemblyCodeName(assembly.getAssemblyCode());
                    dto.setAssemblyCodeDesc(assembly.getAssemblyCodeDesc());
                }
            }
            if (entity.getItcRepairGroup() != null) {
                Optional<RepairGroupEntity> repairOpt = repairGroupRepo
                        .findById(Long.valueOf(entity.getItcRepairGroup()));
                if (repairOpt.isPresent()) {
                    RepairGroupEntity repair = repairOpt.get();
                    dto.setRepairGroupName(repair.getRepairGroupName());
                    dto.setRepairGroupDesc(repair.getRepairGroupDesc());
                }
            }
            dto.setAllowGood(entity.getAllowGood());
            dto.setAllowRepair(entity.getAllowRepair());
            dto.setAllowReplace(entity.getAllowReplace());
            dto.setAllowPoor(entity.getAllowPoor());
            dto.setAllowPhoto(entity.getAllowPhoto());
            dto.setAllowAudio(entity.getAllowAudio());
            dto.setAllowMultipleImage(entity.getAllowMultipleImage());
            dto.setAllowVideo(entity.getAllowVideo());
            dto.setPhotoMandatory(entity.getPhotoMandatory());
            dto.setAudioMandatory(entity.getAudioMandatory());
            dto.setAllowNotApplicable(entity.getAllowNotApplicable());
            dto.setInstructionText(entity.getInstructionText());
            dto.setItcCreatedOn(entity.getItcCreatedOn());
            dto.setItcCreatedBy(entity.getItcCreatedBy());
            list.add(dto);
        }
        return list;
    }

    @Override
    @Transactional
    public void deleteTaskComponent(Long itcId, String token) {
        Jwt jwt = tokenService.decodeJWTToken(token.substring(7));
        Long userId = ((Number) jwt.getClaim("scope")).longValue();
        InspectionTaskComponentEntity entity = taskComponentRepo.findById(itcId)
                .orElseThrow(() -> new RuntimeException("Component not found"));
        entity.setItcDeleteFlag(true);
        entity.setItcUpdatedBy(userId);
        entity.setItcUpdatedOn(LocalDateTime.now());
        taskComponentRepo.save(entity);
    }

    @Override
    @Transactional
    public Long createTaskComponent(@Valid TaskComponentDTO dto, String token) {
        InspectionTaskComponentEntity entity = new InspectionTaskComponentEntity();
        if (Boolean.TRUE.equals(dto.getPhotoMandatory()) && Boolean.FALSE.equals(dto.getAllowPhoto())) {
            throw new RuntimeException("Photo cannot be mandatory when photo upload is disabled");
        }
        if (Boolean.TRUE.equals(dto.getAllowMultipleImage()) && Boolean.FALSE.equals(dto.getAllowPhoto())) {
            throw new RuntimeException("Multiple image upload cannot be enabled when photo upload is disabled");
        }
        if (Boolean.TRUE.equals(dto.getAudioMandatory()) && Boolean.FALSE.equals(dto.getAllowAudio())) {
            throw new RuntimeException("Audio cannot be mandatory when audio upload is disabled");
        }
        try {
            BeanUtils.copyProperties(dto, entity);
            Jwt jwt = tokenService.decodeJWTToken(token.substring(7));
            Long userId = jwt.getClaim("scope");
            entity.setItcCreatedBy(userId);
            entity.setItcCreatedOn(LocalDateTime.now());
            entity.setItcUpdatedBy(userId);
            entity.setItcUpdatedOn(LocalDateTime.now());
            entity.setItcDeleteFlag(false);
            InspectionTaskComponentEntity saved = taskComponentRepo.save(entity);
            return saved.getItcId();
        } catch (DataIntegrityViolationException e) {
            String rootCauseMessage = e.getMostSpecificCause().getMessage();
            if (rootCauseMessage.contains("unique constraint") || rootCauseMessage.contains("Duplicate entry")) {
                throw new ItemExistsException("Task component already exists.");
            } else if (rootCauseMessage.contains("foreign key constraint")) {
                throw new ConstrainViolationException("Invalid category reference.");
            } else if (rootCauseMessage.contains("cannot be null")) {
                throw new NotNullException("Required field missing.");
            } else {
                throw e;
            }
        } catch (Exception ex) {
            throw ex;
        }
    }

    @Override
    @Transactional
    public TaskComponentDTO getTaskComponentById(Long itcId) {
        InspectionTaskComponentEntity entity = taskComponentRepo.findByItcIdAndItcDeleteFlagFalse(itcId)
                .orElseThrow(() -> new ItemNotFoundException("Task Component not found"));
        TaskComponentDTO dto = new TaskComponentDTO();
        dto.setItcId(entity.getItcId());
        dto.setItcName(entity.getItcName());
        dto.setItcDescription(entity.getItcDescription());
        dto.setItcCategoryId(entity.getItcCategoryId());
        dto.setItcAssemblyCode(entity.getItcAssemblyCode());
        dto.setItcRepairGroup(entity.getItcRepairGroup());
        dto.setAllowGood(entity.getAllowGood());
        dto.setAllowRepair(entity.getAllowRepair());
        dto.setAllowReplace(entity.getAllowReplace());
        dto.setAllowPoor(entity.getAllowPoor());
        dto.setAllowPhoto(entity.getAllowPhoto());
        dto.setAllowAudio(entity.getAllowAudio());
        dto.setPhotoMandatory(entity.getPhotoMandatory());
        dto.setAudioMandatory(entity.getAudioMandatory());
        dto.setAllowMultipleImage(entity.getAllowMultipleImage());
        dto.setAllowVideo(entity.getAllowVideo());
        dto.setAllowNotApplicable(entity.getAllowNotApplicable());
        dto.setInstructionText(entity.getInstructionText());
        dto.setVideoDuration(entity.getVideoDuration());
        dto.setItcCreatedOn(entity.getItcCreatedOn());
        dto.setItcCreatedBy(entity.getItcCreatedBy());
        dto.setItcUpdatedOn(entity.getItcUpdatedOn());
        dto.setItcUpdatedBy(entity.getItcUpdatedBy());
        dto.setItcDeleteFlag(entity.getItcDeleteFlag());
        return dto;
    }

    @Override
    @Transactional
    public Long updateTaskComponent(TaskComponentDTO dto, String token) {
        Jwt jwt = tokenService.decodeJWTToken(token.substring(7));
        Long userId = Long.valueOf(jwt.getClaim("scope").toString());
        InspectionTaskComponentEntity entity = taskComponentRepo.findByItcIdAndItcDeleteFlagFalse(dto.getItcId())
                .orElseThrow(() -> new ItemNotFoundException("Task Component not found"));
        if (Boolean.TRUE.equals(dto.getPhotoMandatory()) && Boolean.FALSE.equals(dto.getAllowPhoto())) {
            throw new RuntimeException("Photo cannot be mandatory when photo upload is disabled");
        }
        if (Boolean.TRUE.equals(dto.getAllowMultipleImage()) && Boolean.FALSE.equals(dto.getAllowPhoto())) {
            throw new RuntimeException("Multiple image upload cannot be enabled when photo upload is disabled");
        }
        if (Boolean.TRUE.equals(dto.getAudioMandatory()) && Boolean.FALSE.equals(dto.getAllowAudio())) {
            throw new RuntimeException("Audio cannot be mandatory when audio upload is disabled");
        }
        entity.setItcName(dto.getItcName());
        entity.setItcDescription(dto.getItcDescription());
        entity.setItcCategoryId(dto.getItcCategoryId());
        entity.setItcAssemblyCode(dto.getItcAssemblyCode());
        entity.setItcRepairGroup(dto.getItcRepairGroup());
        entity.setAllowGood(dto.getAllowGood());
        entity.setAllowRepair(dto.getAllowRepair());
        entity.setAllowReplace(dto.getAllowReplace());
        entity.setAllowPoor(dto.getAllowPoor());
        entity.setAllowPhoto(dto.getAllowPhoto());
        entity.setAllowAudio(dto.getAllowAudio());
        entity.setAllowMultipleImage(dto.getAllowMultipleImage());
        entity.setAllowVideo(dto.getAllowVideo());
        entity.setPhotoMandatory(dto.getPhotoMandatory());
        entity.setAudioMandatory(dto.getAudioMandatory());
        entity.setAllowNotApplicable(dto.getAllowNotApplicable());
        entity.setInstructionText(dto.getInstructionText());
        entity.setVideoDuration(dto.getVideoDuration());
        entity.setItcUpdatedBy(userId);
        entity.setItcUpdatedOn(LocalDateTime.now());
        InspectionTaskComponentEntity saved = taskComponentRepo.save(entity);
        return saved.getItcId();
    }

    @Override
    public FuelTypeDTO saveFuelType(FuelTypeDTO dto, String token) {
        try {
            Optional<FuelTypeEntity> dup = fuelTypeRepo.findByFutNameIgnoreCaseAndFutDeleteFlag(dto.getFutName(),
                    false);
            if (dup.isPresent()) {
                throw new ItemExistsException("Fuel Type already exists");
            }
            Jwt jwt = tokenService.decodeJWTToken(token.substring(7));
            FuelTypeEntity entity = new FuelTypeEntity();
            BeanUtils.copyProperties(dto, entity);
            entity.setFutCreatedBy(jwt.getClaim("scope"));
            entity.setFutUpdatedBy(jwt.getClaim("scope"));
            entity.setFutCreatedOn(LocalDateTime.now());
            entity.setFutUpdatedOn(LocalDateTime.now());
            entity.setFutDeleteFlag(false);
            FuelTypeEntity saved = fuelTypeRepo.save(entity);
            FuelTypeDTO response = new FuelTypeDTO();
            BeanUtils.copyProperties(saved, response);
            return response;
        } catch (DataIntegrityViolationException e) {
            throw new ItemExistsException("Duplicate Fuel Type");
        } catch (Exception ex) {
            throw ex;
        }
    }

    @Override
    public List<FuelTypeDTO> getAllFuelTypes(String token) {
        Jwt jwtDetails = tokenService.validateToken(token); // correct
        List<FuelTypeDTO> list = new ArrayList<>();
        List<FuelTypeEntity> entities = fuelTypeRepo.findByFutDeleteFlagFalse();
        for (FuelTypeEntity e : entities) {
            FuelTypeDTO dto = new FuelTypeDTO();
            BeanUtils.copyProperties(e, dto);
            list.add(dto);
        }
        return list;
    }

    @Override
    public FuelTypeDTO getFuelTypeById(Long id) {
        return fuelTypeRepo.findById(id).map(entity -> {
            FuelTypeDTO dto = new FuelTypeDTO();
            BeanUtils.copyProperties(entity, dto);
            return dto;
        }).orElse(null);
    }

    @Override
    public FuelTypeDTO updateFuelType(FuelTypeDTO dto, String token) {
        try {
            FuelTypeEntity entity = fuelTypeRepo.findById(dto.getFutId())
                    .orElseThrow(() -> new ItemNotFoundException("Fuel Type not found"));
            Jwt jwt = tokenService.decodeJWTToken(token.substring(7));
            entity.setFutName(dto.getFutName());
            entity.setFutDescription(dto.getFutDescription());
            entity.setFutUpdatedBy(jwt.getClaim("scope"));
            entity.setFutUpdatedOn(LocalDateTime.now());
            FuelTypeEntity updated = fuelTypeRepo.save(entity);
            FuelTypeDTO response = new FuelTypeDTO();
            BeanUtils.copyProperties(updated, response);
            return response;
        } catch (Exception ex) {
            throw ex;
        }
    }

    @Override
    public FuelTypeDTO deleteFuelType(Long futId, String token) {
        FuelTypeEntity entity = fuelTypeRepo.findById(futId)
                .orElseThrow(() -> new ItemNotFoundException("Fuel Type not found"));
        Jwt jwt = tokenService.decodeJWTToken(token.substring(7));
        entity.setFutDeleteFlag(true);
        entity.setFutUpdatedBy(jwt.getClaim("scope"));
        entity.setFutUpdatedOn(LocalDateTime.now());
        FuelTypeEntity saved = fuelTypeRepo.save(entity);
        FuelTypeDTO dto = new FuelTypeDTO();
        BeanUtils.copyProperties(saved, dto);
        return dto;
    }

    @Override
    public TransmissionTypeDTO saveTransmissionType(TransmissionTypeDTO dto, String token) {
        try {
            Optional<TransmissionTypeEntity> dup = transmissionTypeRepo
                    .findByTrtNameIgnoreCaseAndTrtDeleteFlag(dto.getTrtName(), false);
            if (dup.isPresent()) {
                throw new ItemExistsException("Transmission Type already exists");
            }
            Jwt jwt = tokenService.decodeJWTToken(token.substring(7));
            TransmissionTypeEntity entity = new TransmissionTypeEntity();
            BeanUtils.copyProperties(dto, entity);
            entity.setTrtCreatedBy(jwt.getClaim("scope"));
            entity.setTrtUpdatedBy(jwt.getClaim("scope"));
            entity.setTrtCreatedOn(LocalDateTime.now());
            entity.setTrtUpdatedOn(LocalDateTime.now());
            entity.setTrtDeleteFlag(false);
            TransmissionTypeEntity saved = transmissionTypeRepo.save(entity);
            TransmissionTypeDTO response = new TransmissionTypeDTO();
            BeanUtils.copyProperties(saved, response);
            return response;
        } catch (DataIntegrityViolationException e) {
            throw new ItemExistsException("Duplicate Transmission Type");
        } catch (Exception ex) {
            throw ex;
        }
    }

    @Override
    public List<TransmissionTypeDTO> getAllTransmissionTypes(String token) {
        Jwt jwtDetails = tokenService.validateToken(token);
        List<TransmissionTypeDTO> list = new ArrayList<>();
        List<TransmissionTypeEntity> entities = transmissionTypeRepo.findByTrtDeleteFlagFalse();
        for (TransmissionTypeEntity e : entities) {
            TransmissionTypeDTO dto = new TransmissionTypeDTO();
            BeanUtils.copyProperties(e, dto);
            list.add(dto);
        }
        return list;
    }

    @Override
    public TransmissionTypeDTO getTransmissionTypeById(Long id) {
        return transmissionTypeRepo.findById(id).map(entity -> {
            TransmissionTypeDTO dto = new TransmissionTypeDTO();
            BeanUtils.copyProperties(entity, dto);
            return dto;
        }).orElse(null);
    }

    @Override
    public TransmissionTypeDTO updateTransmissionType(TransmissionTypeDTO dto, String token) {
        try {
            TransmissionTypeEntity entity = transmissionTypeRepo.findById(dto.getTrtId())
                    .orElseThrow(() -> new ItemNotFoundException("Transmission Type not found"));
            Jwt jwt = tokenService.decodeJWTToken(token.substring(7));
            entity.setTrtName(dto.getTrtName());
            entity.setTrtDescription(dto.getTrtDescription());
            entity.setTrtUpdatedBy(jwt.getClaim("scope"));
            entity.setTrtUpdatedOn(LocalDateTime.now());
            TransmissionTypeEntity updated = transmissionTypeRepo.save(entity);
            TransmissionTypeDTO response = new TransmissionTypeDTO();
            BeanUtils.copyProperties(updated, response);
            return response;
        } catch (Exception ex) {
            throw ex;
        }
    }

    @Override
    public TransmissionTypeDTO deleteTransmissionType(Long trtId, String token) {
        TransmissionTypeEntity entity = transmissionTypeRepo.findById(trtId)
                .orElseThrow(() -> new ItemNotFoundException("Transmission Type not found"));
        Jwt jwt = tokenService.decodeJWTToken(token.substring(7));
        entity.setTrtDeleteFlag(true);
        entity.setTrtUpdatedBy(jwt.getClaim("scope"));
        entity.setTrtUpdatedOn(LocalDateTime.now());
        TransmissionTypeEntity saved = transmissionTypeRepo.save(entity);
        TransmissionTypeDTO dto = new TransmissionTypeDTO();
        BeanUtils.copyProperties(saved, dto);
        return dto;
    }

    @Override
    public ServiceTypeDTO saveServiceType(ServiceTypeDTO dto, String token) {
        try {
            Optional<ServiceTypeEntity> dup = serviceTypeRepo.findBySttNameIgnoreCaseAndSttDeleteFlag(dto.getSttName(),
                    false);
            if (dup.isPresent()) {
                throw new ItemExistsException("Service Type already exists");
            }
            Jwt jwt = tokenService.decodeJWTToken(token.substring(7));
            ServiceTypeEntity entity = new ServiceTypeEntity();
            BeanUtils.copyProperties(dto, entity);
            entity.setSttCreatedBy(jwt.getClaim("scope"));
            entity.setSttUpdatedBy(jwt.getClaim("scope"));
            entity.setSttCreatedOn(LocalDateTime.now());
            entity.setSttUpdatedOn(LocalDateTime.now());
            entity.setSttDeleteFlag(false);
            ServiceTypeEntity saved = serviceTypeRepo.save(entity);
            ServiceTypeDTO response = new ServiceTypeDTO();
            BeanUtils.copyProperties(saved, response);
            return response;
        } catch (DataIntegrityViolationException e) {
            throw new ItemExistsException("Duplicate Service Type");
        } catch (Exception ex) {
            throw ex;
        }
    }

    @Override
    public List<ServiceTypeDTO> getAllServiceTypes(String token) {
        Jwt jwtDetails = tokenService.validateToken(token);
        List<ServiceTypeDTO> list = new ArrayList<>();
        List<ServiceTypeEntity> entities = serviceTypeRepo.findBySttDeleteFlagFalse();
        for (ServiceTypeEntity e : entities) {
            ServiceTypeDTO dto = new ServiceTypeDTO();
            BeanUtils.copyProperties(e, dto);
            list.add(dto);
        }
        return list;
    }

    @Override
    public ServiceTypeDTO getServiceTypeById(Long id) {
        return serviceTypeRepo.findById(id).map(entity -> {
            ServiceTypeDTO dto = new ServiceTypeDTO();
            BeanUtils.copyProperties(entity, dto);
            return dto;
        }).orElse(null);
    }

    @Override
    public ServiceTypeDTO updateServiceType(ServiceTypeDTO dto, String token) {
        try {
            ServiceTypeEntity entity = serviceTypeRepo.findById(dto.getSttId())
                    .orElseThrow(() -> new ItemNotFoundException("Service Type not found"));
            Jwt jwt = tokenService.decodeJWTToken(token.substring(7));
            entity.setSttName(dto.getSttName());
            entity.setSttDescription(dto.getSttDescription());
            entity.setSttUpdatedBy(jwt.getClaim("scope"));
            entity.setSttUpdatedOn(LocalDateTime.now());
            ServiceTypeEntity updated = serviceTypeRepo.save(entity);
            ServiceTypeDTO response = new ServiceTypeDTO();
            BeanUtils.copyProperties(updated, response);
            return response;
        } catch (Exception ex) {
            throw ex;
        }
    }

    @Override
    public ServiceTypeDTO deleteServiceType(Long sttId, String token) {
        ServiceTypeEntity entity = serviceTypeRepo.findById(sttId)
                .orElseThrow(() -> new ItemNotFoundException("Service Type not found"));
        Jwt jwt = tokenService.decodeJWTToken(token.substring(7));
        entity.setSttDeleteFlag(true);
        entity.setSttUpdatedBy(jwt.getClaim("scope"));
        entity.setSttUpdatedOn(LocalDateTime.now());
        ServiceTypeEntity saved = serviceTypeRepo.save(entity);
        ServiceTypeDTO dto = new ServiceTypeDTO();
        BeanUtils.copyProperties(saved, dto);
        return dto;
    }

    @Override
    public CustomerTypeDTO saveCustomerType(CustomerTypeDTO dto, String token) {
        try {
            Optional<CustomerTypeEntity> dup = customerTypeRepo
                    .findByCttNameIgnoreCaseAndCttDeleteFlag(dto.getCttName(), false);
            if (dup.isPresent()) {
                throw new ItemExistsException("Customer Type already exists");
            }
            Jwt jwt = tokenService.decodeJWTToken(token.substring(7));
            CustomerTypeEntity entity = new CustomerTypeEntity();
            BeanUtils.copyProperties(dto, entity);
            entity.setCttCreatedBy(jwt.getClaim("scope"));
            entity.setCttUpdatedBy(jwt.getClaim("scope"));
            entity.setCttCreatedOn(LocalDateTime.now());
            entity.setCttUpdatedOn(LocalDateTime.now());
            entity.setCttDeleteFlag(false);
            CustomerTypeEntity saved = customerTypeRepo.save(entity);
            CustomerTypeDTO response = new CustomerTypeDTO();
            BeanUtils.copyProperties(saved, response);
            return response;
        } catch (DataIntegrityViolationException e) {
            throw new ItemExistsException("Duplicate Customer Type");
        } catch (Exception ex) {
            throw ex;
        }
    }

    @Override
    public List<CustomerTypeDTO> getAllCustomerTypes(String token) {
        Jwt jwtDetails = tokenService.validateToken(token);
        List<CustomerTypeDTO> list = new ArrayList<>();
        List<CustomerTypeEntity> entities = customerTypeRepo.findByCttDeleteFlagFalse();
        for (CustomerTypeEntity e : entities) {
            CustomerTypeDTO dto = new CustomerTypeDTO();
            BeanUtils.copyProperties(e, dto);
            list.add(dto);
        }
        return list;
    }

    @Override
    public CustomerTypeDTO getCustomerTypeById(Long id) {
        return customerTypeRepo.findById(id).map(entity -> {
            CustomerTypeDTO dto = new CustomerTypeDTO();
            BeanUtils.copyProperties(entity, dto);
            return dto;
        }).orElse(null);
    }

    @Override
    public CustomerTypeDTO updateCustomerType(CustomerTypeDTO dto, String token) {
        try {
            CustomerTypeEntity entity = customerTypeRepo.findById(dto.getCttId())
                    .orElseThrow(() -> new ItemNotFoundException("Customer Type not found"));
            Jwt jwt = tokenService.decodeJWTToken(token.substring(7));
            entity.setCttName(dto.getCttName());
            entity.setCttDescription(dto.getCttDescription());
            entity.setCttUpdatedBy(jwt.getClaim("scope"));
            entity.setCttUpdatedOn(LocalDateTime.now());
            CustomerTypeEntity updated = customerTypeRepo.save(entity);
            CustomerTypeDTO response = new CustomerTypeDTO();
            BeanUtils.copyProperties(updated, response);
            return response;
        } catch (Exception ex) {
            throw ex;
        }
    }

    @Override
    public CustomerTypeDTO deleteCustomerType(Long cttId, String token) {
        CustomerTypeEntity entity = customerTypeRepo.findById(cttId)
                .orElseThrow(() -> new ItemNotFoundException("Customer Type not found"));
        Jwt jwt = tokenService.decodeJWTToken(token.substring(7));
        entity.setCttDeleteFlag(true);
        entity.setCttUpdatedBy(jwt.getClaim("scope"));
        entity.setCttUpdatedOn(LocalDateTime.now());
        CustomerTypeEntity saved = customerTypeRepo.save(entity);
        CustomerTypeDTO dto = new CustomerTypeDTO();
        BeanUtils.copyProperties(saved, dto);
        return dto;
    }

    @Override
    public VehicleEssentialsDTO saveVehicleEssentials(@Valid VehicleEssentialsDTO dto, String token) {
        try {
            Optional<VehicleEssentialsEntity> dup = vehicleEssentialRepo
                    .findByVeNameIgnoreCaseAndVeDeleteFlag(dto.getVeName(), false);
            if (dup.isPresent()) {
                throw new ItemExistsException("Customer Type already exists");
            }
            Jwt jwt = tokenService.decodeJWTToken(token.substring(7));
            VehicleEssentialsEntity entity = new VehicleEssentialsEntity();
            BeanUtils.copyProperties(dto, entity);
            entity.setVeCreatedBy(jwt.getClaim("scope"));
            entity.setVeUpdatedBy(jwt.getClaim("scope"));
            entity.setVeCreatedOn(LocalDateTime.now());
            entity.setVeUpdatedOn(LocalDateTime.now());
            entity.setVeDeleteFlag(false);
            VehicleEssentialsEntity saved = vehicleEssentialRepo.save(entity);
            VehicleEssentialsDTO response = new VehicleEssentialsDTO();
            BeanUtils.copyProperties(saved, response);
            return response;
        } catch (DataIntegrityViolationException e) {
            throw new ItemExistsException("Duplicate Customer Type");
        } catch (Exception ex) {
            throw ex;
        }
    }

    @Override
    public List<VehicleEssentialsDTO> getAllVehicleEssentialList(String token) {
        Jwt jwtDetails = tokenService.validateToken(token);
        List<VehicleEssentialsDTO> list = new ArrayList<>();
        List<VehicleEssentialsEntity> entities = vehicleEssentialRepo.findByVeDeleteFlagFalse();
        for (VehicleEssentialsEntity e : entities) {
            VehicleEssentialsDTO dto = new VehicleEssentialsDTO();
            BeanUtils.copyProperties(e, dto);
            list.add(dto);
        }
        return list;
    }

    @Override
    public VehicleEssentialsDTO getVehicleEssentialsById(Long veId) {
        return vehicleEssentialRepo.findById(veId).map(entity -> {
            VehicleEssentialsDTO dto = new VehicleEssentialsDTO();
            BeanUtils.copyProperties(entity, dto);
            return dto;
        }).orElse(null);
    }

    @Override
    public VehicleEssentialsDTO updateVehicleEssentials(@Valid VehicleEssentialsDTO dto, String token) {
        try {
            VehicleEssentialsEntity entity = vehicleEssentialRepo.findById(dto.getVeId())
                    .orElseThrow(() -> new ItemNotFoundException("Vehicle Essentials not found"));
            Jwt jwt = tokenService.decodeJWTToken(token.substring(7));
            entity.setVeName(dto.getVeName());
            entity.setVeDescription(dto.getVeDescription());
            entity.setVeUpdatedBy(jwt.getClaim("scope"));
            entity.setVeUpdatedOn(LocalDateTime.now());
            VehicleEssentialsEntity updated = vehicleEssentialRepo.save(entity);
            VehicleEssentialsDTO response = new VehicleEssentialsDTO();
            BeanUtils.copyProperties(updated, response);
            return response;
        } catch (Exception ex) {
            throw ex;
        }
    }

    @Override
    public VehicleEssentialsDTO deleteVehicleEssentials(Long veId, String token) {
        VehicleEssentialsEntity entity = vehicleEssentialRepo.findById(veId)
                .orElseThrow(() -> new ItemNotFoundException("Vehicle Essentials not found"));
        Jwt jwt = tokenService.decodeJWTToken(token.substring(7));
        entity.setVeDeleteFlag(true);
        entity.setVeUpdatedBy(jwt.getClaim("scope"));
        entity.setVeUpdatedOn(LocalDateTime.now());
        VehicleEssentialsEntity saved = vehicleEssentialRepo.save(entity);
        VehicleEssentialsDTO dto = new VehicleEssentialsDTO();
        BeanUtils.copyProperties(saved, dto);
        return dto;
    }

    @Override
    public long saveInspectionSettings(InspectionSettingsDTO dto, String token) {
        Jwt jwt = tokenService.decodeJWTToken(token.substring(7));
        Long userId = Long.valueOf(jwt.getClaim("scope").toString());
        InspectionSettingsMasterEntity master = new InspectionSettingsMasterEntity();
        master.setInspectionType(dto.getInspectionType());
        master.setInspection360Duration(dto.getInspection360Duration());
        master.setAdditionalImages(dto.getAdditionalImages());
        master.setCreatedBy(userId);
        master.setUpdatedBy(userId);
        master.setCreatedOn(LocalDateTime.now());
        master.setUpdatedOn(LocalDateTime.now());
        if (dto.getImages() != null) {
            List<InspectionImageMasterEntity> children = dto.getImages().stream().map(i -> {
                InspectionImageMasterEntity e = new InspectionImageMasterEntity();
                e.setImageLabel(i.getImageLabel());
                e.setImageCount(i.getImageCount());
                e.setVideoFlag(Boolean.TRUE.equals(i.getVideoFlag()));
                e.setImageMandatory(Boolean.TRUE.equals(i.getImageMandatory()));
                e.setVideoDuration(i.getVideoDuration());
                e.setSortOrder(i.getSortOrder());
                e.setSettings(master);
                return e;
            }).toList();
            master.getImages().addAll(children);
        }
        return inspectionSettingsMasterRepo.save(master).getInspectionId();
    }

    @Override
    public List<InspectionSettingsDTO> getInspectionSettingsList(Integer type, String token) {
        tokenService.decodeJWTToken(token.substring(7));
        List<InspectionSettingsMasterEntity> list = inspectionSettingsMasterRepo.findByTypeWithImages(type);
        return list.stream().map(master -> {
            InspectionSettingsDTO dto = new InspectionSettingsDTO();
            dto.setId(master.getInspectionId());
            dto.setInspectionType(master.getInspectionType());
            dto.setInspection360Duration(master.getInspection360Duration());
            dto.setAdditionalImages(master.getAdditionalImages());
            List<InspectionImageDTO> images = master.getImages().stream()
                    .filter(img -> !Boolean.TRUE.equals(img.getDeleteFlag()))
                    .sorted(Comparator.comparing(InspectionImageMasterEntity::getSortOrder)).map(img -> {
                        InspectionImageDTO i = new InspectionImageDTO();
                        i.setId(img.getImageId());
                        i.setImageLabel(img.getImageLabel());
                        i.setImageCount(img.getImageCount());
                        i.setVideoFlag(img.getVideoFlag());
                        i.setImageMandatory(img.getImageMandatory());
                        i.setVideoDuration(img.getVideoDuration());
                        i.setSortOrder(img.getSortOrder());
                        return i;
                    }).toList();
            dto.setImages(images);
            return dto;
        }).toList();
    }

    @Override
    @Transactional
    public long updateInspectionSettings(InspectionSettingsDTO dto, String token) {
        if (dto.getId() == null)
            throw new NotFoundException("Settings id required for update");
        Jwt jwt = tokenService.decodeJWTToken(token.substring(7));
        Long userId = Long.valueOf(jwt.getClaim("scope").toString());
        InspectionSettingsMasterEntity master = inspectionSettingsMasterRepo.findById(dto.getId())
                .orElseThrow(() -> new NotFoundException("Settings not found"));
        master.setInspectionType(dto.getInspectionType());
        master.setInspection360Duration(dto.getInspection360Duration());
        master.setAdditionalImages(dto.getAdditionalImages());
        master.setUpdatedBy(userId);
        master.setUpdatedOn(LocalDateTime.now());
        Map<Long, InspectionImageMasterEntity> existingMap = master.getImages().stream()
                .filter(x -> x.getImageId() != null)
                .collect(Collectors.toMap(InspectionImageMasterEntity::getImageId, x -> x));
        Set<Long> incomingIds = new HashSet<>();
        if (dto.getImages() != null) {
            incomingIds = dto.getImages().stream().filter(i -> i.getId() != null).map(InspectionImageDTO::getId)
                    .collect(Collectors.toSet());
        }
        for (InspectionImageMasterEntity existing : master.getImages()) {
            if (existing.getImageId() != null && !incomingIds.contains(existing.getImageId())) {
                existing.setDeleteFlag(true);
            }
        }
        List<InspectionImageMasterEntity> finalChildren = new ArrayList<>();
        if (dto.getImages() != null) {
            for (InspectionImageDTO i : dto.getImages()) {
                InspectionImageMasterEntity child;
                if (i.getId() != null && existingMap.containsKey(i.getId())) {
                    child = existingMap.get(i.getId());
                } else {
                    child = new InspectionImageMasterEntity();
                    child.setSettings(master);
                    master.getImages().add(child);
                }
                child.setImageLabel(i.getImageLabel());
                child.setImageCount(i.getImageCount());
                child.setVideoFlag(Boolean.TRUE.equals(i.getVideoFlag()));
                child.setImageMandatory(Boolean.TRUE.equals(i.getImageMandatory()));
                child.setVideoDuration(i.getVideoDuration());
                child.setSortOrder(i.getSortOrder());
                child.setDeleteFlag(false);
                finalChildren.add(child);
            }
        }
        InspectionSettingsMasterEntity saved = inspectionSettingsMasterRepo.save(master);
        return saved.getInspectionId();
    }

    @Override
    public ImageSettingsListDTO getImageSettingsList(String token) {
        tokenService.decodeJWTToken(token.substring(7));
        List<InspectionSettingsDTO> external = getInspectionSettingsList(0, token);
        List<InspectionSettingsDTO> internal = getInspectionSettingsList(1, token);
        return new ImageSettingsListDTO(internal, external);
    }

    @Override
    public long saveExpirationTime(ExpirationTimeDTO dto, String token) {
        ExpirationTimeEntity entity = new ExpirationTimeEntity();
        Jwt jwtDetails = tokenService.decodeJWTToken(token.substring(7));
        entity.setExpTime(dto.getExpTime());
        entity.setExpCreatedBy(jwtDetails.getClaim("scope"));
        entity.setExpUpdatedBy(jwtDetails.getClaim("scope"));
        entity.setExpDeleteFlag(false);
        ExpirationTimeEntity saved = expirationTimeRepo.save(entity);
        return saved.getExpId();
    }

    @Override
    public long updateExpirationTime(ExpirationTimeDTO dto, String token) {
        Optional<ExpirationTimeEntity> optional = expirationTimeRepo.findById(dto.getExpId());
        if (!optional.isPresent()) {
            return 0;
        }
        Jwt jwtDetails = tokenService.decodeJWTToken(token.substring(7));
        ExpirationTimeEntity entity = optional.get();
        entity.setExpTime(dto.getExpTime());
        entity.setExpCreatedBy(jwtDetails.getClaim("scope"));
        entity.setExpUpdatedBy(jwtDetails.getClaim("scope"));
        ExpirationTimeEntity updated = expirationTimeRepo.save(entity);
        return updated.getExpId();
    }

    @Override
    public ExpirationTimeDTO getExpirationTime() {
        Optional<ExpirationTimeEntity> optional = expirationTimeRepo.findTopByExpDeleteFlagFalseOrderByExpIdDesc();
        if (!optional.isPresent()) {
            return null;
        }
        ExpirationTimeEntity entity = optional.get();
        ExpirationTimeDTO dto = new ExpirationTimeDTO();
        dto.setExpId(entity.getExpId());
        dto.setExpTime(entity.getExpTime());
        dto.setExpCreatedOn(entity.getExpCreatedOn());
        dto.setExpCreatedBy(entity.getExpCreatedBy());
        dto.setExpUpdatedOn(entity.getExpUpdatedOn());
        dto.setExpUpdatedBy(entity.getExpUpdatedBy());
        dto.setExpDeleteFlag(entity.getExpDeleteFlag());
        return dto;
    }

    @Override
    public int getExpiryHours() {

        // ✅ Reuse existing method
        ExpirationTimeDTO dto = getExpirationTime();

        // ✅ Fallback if no data
        if (dto == null || dto.getExpTime() == null || dto.getExpTime().trim().isEmpty()) {
            return 2;
        }

        try {
            // ✅ Convert String → int
            return Integer.parseInt(dto.getExpTime().trim());
        } catch (Exception e) {
            return 2; // fallback safety
        }
    }

    @Override
    public long saveItemType(@Valid ItemTypeDTO itemTask, String token) {
        ItemTypeEntity tsentries = new ItemTypeEntity();
        try {
            BeanUtils.copyProperties(itemTask, tsentries);
            Jwt jwtDetails = tokenService.decodeJWTToken(token.substring(7));
            Long userId = Long.parseLong(jwtDetails.getClaim("scope").toString());
            tsentries.setItemTypeCreatedBy(userId);
            tsentries.setItemTypeUpdatedBy(userId);
            tsentries.setItemTypeCreatedOn(LocalDateTime.now());
            tsentries.setItemTypeUpdatedOn(LocalDateTime.now());
            tsentries.setItemTypeDeleteFlag(false);
            ItemTypeEntity ret = itemTypeRepo.save(tsentries);
            return ret.getItemTypeId();
        } catch (DataIntegrityViolationException e) {
            String rootCauseMessage = e.getMostSpecificCause().getMessage();
            if (rootCauseMessage.contains("unique constraint") || rootCauseMessage.contains("Duplicate entry")) {
                throw new ItemExistsException("Duplicate entry detected.");
            } else if (rootCauseMessage.contains("foreign key constraint")) {
                throw new ConstrainViolationException("Invalid reference detected.");
            } else if (rootCauseMessage.contains("cannot be null")) {
                throw new NotNullException("Required field missing.");
            } else {
                throw e;
            }
        } catch (Exception ex) {
            throw ex;
        }
    }

    @Override
    public List<ItemTypeDTO> getAllItemTypeList() {
        List<ItemTypeDTO> itemDTO = new ArrayList<>();
        try {
            List<ItemTypeEntity> taxingData = itemTypeRepo.findByitemTypeDeleteFlag(false);
            for (ItemTypeEntity entity : taxingData) {
                ItemTypeDTO dto = new ItemTypeDTO();
                BeanUtils.copyProperties(entity, dto);
                itemDTO.add(dto);
            }
        } catch (Exception ex) {
            throw ex;
        }
        return itemDTO;
    }

    @Override
    public ItemTypeDTO getItemTypeById(Long long1) {
        return itemTypeRepo.findById(long1).map(entity -> {
            ItemTypeDTO itemDetailsDTO = new ItemTypeDTO();
            BeanUtils.copyProperties(entity, itemDetailsDTO);
            return itemDetailsDTO;
        }).orElseThrow(() -> new ItemNotFoundException("Task Category not found with id " + long1));
    }

    @Override
    public ItemTypeDTO updateItemType(@Valid ItemTypeDTO items, String token) {
        try {
            ItemTypeEntity itemEntity = itemTypeRepo.findById(items.getItemTypeId()).orElseThrow(
                    () -> new ItemNotFoundException("Task Category not found with id " + items.getItemTypeId()));
            Jwt jwtDetails = tokenService.decodeJWTToken(token.substring(7));
            itemEntity.setItemTypeUpdatedBy(jwtDetails.getClaim("scope"));
            itemEntity.setItemTypeDeleteFlag(false);
            itemEntity.setItemTypeCode(items.getItemTypeCode());
            itemEntity.setItemTypeName(items.getItemTypeName());
            itemEntity.setItemTypeUpdatedOn(LocalDateTime.now());
            ItemTypeEntity savedEntity = itemTypeRepo.save(itemEntity);
            ItemTypeDTO responseDto = new ItemTypeDTO();
            BeanUtils.copyProperties(savedEntity, responseDto);
            return responseDto;
        } catch (DataIntegrityViolationException e) {
            String rootCauseMessage = e.getMostSpecificCause().getMessage();
            if (rootCauseMessage.contains("unique constraint") || rootCauseMessage.contains("Duplicate entry")) {
                throw new ItemExistsException("Duplicate entry detected.");
            } else if (rootCauseMessage.contains("foreign key constraint")) {
                throw new ConstrainViolationException("Invalid reference detected.");
            } else if (rootCauseMessage.contains("cannot be null")) {
                throw new NotNullException("Required field missing.");
            } else {
                throw e;
            }
        } catch (Exception ex) {
            throw ex;
        }
    }

    @Override
    public ItemTypeDTO deleteItemType(@Valid Long itemId, String token) {
        ItemTypeDTO tcDetail = new ItemTypeDTO();
        try {
            Optional<ItemTypeEntity> tcMaster = itemTypeRepo.findById(itemId);
            Jwt jwtDetails = tokenService.decodeJWTToken(token.substring(7));
            tcMaster.get().setItemTypeUpdatedBy(jwtDetails.getClaim("scope"));
            tcMaster.get().setItemTypeDeleteFlag(true);
            ItemTypeEntity ret = itemTypeRepo.save(tcMaster.get());
            BeanUtils.copyProperties(tcMaster.get(), tcDetail);
            if (ret != null)
                return tcDetail;
            else
                return null;
        } catch (DataIntegrityViolationException e) {
            String rootCauseMessage = e.getMostSpecificCause().getMessage();
            if (rootCauseMessage.contains("unique constraint") || rootCauseMessage.contains("Duplicate entry")) {
                throw new ItemExistsException("Duplicate entry detected.");
            } else if (rootCauseMessage.contains("foreign key constraint")) {
                throw new ConstrainViolationException("Invalid reference detected.");
            } else if (rootCauseMessage.contains("cannot be null")) {
                throw new NotNullException("Required field missing.");
            } else {
                throw e;
            }
        } catch (Exception ex) {
            throw ex;
        }
    }

    @Override
    public long saveVendor(@Valid VendorDTO vendorDTO, String token) {
        try {
            VendorEntity vendor = new VendorEntity();
            Jwt jwtDetails = tokenService.decodeJWTToken(token.substring(7));
            Long userId = Long.parseLong(jwtDetails.getClaim("scope").toString());
            vendor.setVendorName(vendorDTO.getVendorName());
            vendor.setVendorContactName(vendorDTO.getVendorContactName());
            vendor.setVendorDisplayName(vendorDTO.getVendorDisplayName());
            vendor.setVendorEmail(vendorDTO.getVendorEmail());
            vendor.setVendorContactNumber(vendorDTO.getVendorContactNumber());
            vendor.setVendorWhatsapp(vendorDTO.getVendorWhatsapp());
            vendor.setVendorCountryCode(vendorDTO.getVendorCountryCode());
            vendor.setVendorWbCountryCode(vendorDTO.getVendorWbCountryCode());
            vendor.setVendorPassword(passwordEncoder.encode(vendorDTO.getVendorPassword()));
            vendor.setVendorCreatedBy(userId);
            vendor.setVendorUpdatedBy(userId);
            vendor.setVendorCreatedOn(LocalDateTime.now());
            vendor.setVendorUpdatedOn(LocalDateTime.now());
            vendor.setVendorstatusFlag(true);
            vendor.setVendordeleteFlag(false);
            List<ItemTypeEntity> itemTypes = itemTypeRepo.findAllById(vendorDTO.getItemTypeIds());
            vendor.setItemTypes(itemTypes);
            VendorEntity savedVendor = vendorRepository.save(vendor);
            return savedVendor.getVendorId();
        } catch (DataIntegrityViolationException e) {
            String rootCauseMessage = e.getMostSpecificCause().getMessage();
            if (rootCauseMessage.contains("Duplicate entry")) {
                throw new ItemExistsException("Duplicate Vendor detected.");
            } else if (rootCauseMessage.contains("cannot be null")) {
                throw new NotNullException("Required field missing.");
            } else {
                throw e;
            }
        } catch (Exception ex) {
            throw ex;
        }
    }

    @Override
    public VendorDTO getVendorDetailsById(Long vendorId) {
        VendorEntity vendor = vendorRepository.findById(vendorId)
                .orElseThrow(() -> new ItemNotFoundException("Vendor not found"));
        VendorDTO dto = new VendorDTO();
        dto.setVendorId(vendor.getVendorId());
        dto.setVendorName(vendor.getVendorName());
        dto.setVendorContactName(vendor.getVendorContactName());
        dto.setVendorDisplayName(vendor.getVendorDisplayName());
        dto.setVendorEmail(vendor.getVendorEmail());
        dto.setVendorContactNumber(vendor.getVendorContactNumber());
        dto.setVendorWhatsapp(vendor.getVendorWhatsapp());
        dto.setVendorCountryCode(vendor.getVendorCountryCode());
        dto.setVendorWbCountryCode(vendor.getVendorWbCountryCode());
        dto.setVendorCreatedBy(vendor.getVendorCreatedBy());
        dto.setVendorCreatedOn(vendor.getVendorCreatedOn());
        dto.setVendorUpdatedBy(vendor.getVendorUpdatedBy());
        dto.setVendorUpdatedOn(vendor.getVendorUpdatedOn());
        dto.setVendorstatusFlag(vendor.getVendorstatusFlag());
        dto.setVendordeleteFlag(vendor.getVendordeleteFlag());
        List<Long> itemTypeIds = vendor.getItemTypes().stream().map(ItemTypeEntity::getItemTypeId).toList();
        dto.setItemTypeIds(itemTypeIds);
        List<String> itemTypeNames = vendor.getItemTypes().stream().map(ItemTypeEntity::getItemTypeName).toList();
        dto.setItemTypeNames(itemTypeNames);
        return dto;
    }

    @Override
    public List<VendorDTO> getAllVendorList() {
        List<VendorEntity> vendorEntities = vendorRepository.findByVendordeleteFlagFalseOrderByVendorIdDesc();
        List<VendorDTO> vendorDTOList = new ArrayList<>();
        for (VendorEntity vendor : vendorEntities) {
            VendorDTO dto = new VendorDTO();
            dto.setVendorId(vendor.getVendorId());
            dto.setVendorName(vendor.getVendorName());
            dto.setVendorContactName(vendor.getVendorContactName());
            dto.setVendorDisplayName(vendor.getVendorDisplayName());
            dto.setVendorEmail(vendor.getVendorEmail());
            dto.setVendorContactNumber(vendor.getVendorContactNumber());
            dto.setVendorWhatsapp(vendor.getVendorWhatsapp());
            dto.setVendorCountryCode(vendor.getVendorCountryCode());
            dto.setVendorWbCountryCode(vendor.getVendorWbCountryCode());
            dto.setVendorstatusFlag(vendor.getVendorstatusFlag());
            List<Long> itemTypeIds = vendor.getItemTypes().stream().map(ItemTypeEntity::getItemTypeId)
                    .collect(Collectors.toList());

            dto.setItemTypeIds(itemTypeIds);
            List<String> itemTypeNames = vendor.getItemTypes().stream().map(ItemTypeEntity::getItemTypeName)
                    .collect(Collectors.toList());
            dto.setItemTypeNames(itemTypeNames);
            vendorDTOList.add(dto);
        }
        return vendorDTOList;
    }

    @Override
    public VendorDTO updateVendor(VendorDTO vendorDTO, String token) {
        Optional<VendorEntity> optionalVendor = vendorRepository.findById(vendorDTO.getVendorId());
        if (!optionalVendor.isPresent()) {
            throw new ItemNotFoundException("Vendor not found with ID : " + vendorDTO.getVendorId());
        }
        VendorEntity vendorEntity = optionalVendor.get();
        vendorEntity.setVendorName(vendorDTO.getVendorName());
        vendorEntity.setVendorContactName(vendorDTO.getVendorContactName());
        vendorEntity.setVendorDisplayName(vendorDTO.getVendorDisplayName());
        vendorEntity.setVendorEmail(vendorDTO.getVendorEmail());
        vendorEntity.setVendorContactNumber(vendorDTO.getVendorContactNumber());
        vendorEntity.setVendorWhatsapp(vendorDTO.getVendorWhatsapp());
        vendorEntity.setVendorCountryCode(vendorDTO.getVendorCountryCode());
        vendorEntity.setVendorWbCountryCode(vendorDTO.getVendorWbCountryCode());
        vendorEntity.setVendorstatusFlag(vendorDTO.getVendorstatusFlag());
        vendorEntity.setVendorUpdatedOn(LocalDateTime.now());
        if (vendorDTO.getItemTypeIds() != null && !vendorDTO.getItemTypeIds().isEmpty()) {
            List<ItemTypeEntity> itemTypes = itemTypeRepo.findAllById(vendorDTO.getItemTypeIds());
            vendorEntity.setItemTypes(itemTypes);
        } else {
            vendorEntity.setItemTypes(new ArrayList<>());
        }
        VendorEntity savedVendor = vendorRepository.save(vendorEntity);
        VendorDTO response = new VendorDTO();
        response.setVendorId(savedVendor.getVendorId());
        response.setVendorName(savedVendor.getVendorName());
        response.setVendorContactName(savedVendor.getVendorContactName());
        response.setVendorDisplayName(savedVendor.getVendorDisplayName());
        response.setVendorEmail(savedVendor.getVendorEmail());
        response.setVendorContactNumber(savedVendor.getVendorContactNumber());
        response.setVendorWhatsapp(savedVendor.getVendorWhatsapp());
        response.setVendorCountryCode(savedVendor.getVendorCountryCode());
        response.setVendorWbCountryCode(savedVendor.getVendorWbCountryCode());
        response.setVendorstatusFlag(savedVendor.getVendorstatusFlag());
        response.setItemTypeIds(
                savedVendor.getItemTypes().stream().map(ItemTypeEntity::getItemTypeId).collect(Collectors.toList()));
        return response;
    }

    @Override
    public VendorDTO updateVendorStatus(VendorDTO vendorDTO, String token) {
        VendorEntity vendor = vendorRepository.findByVendorIdAndVendordeleteFlag(vendorDTO.getVendorId(), false);
        if (vendor == null) {
            throw new InternalErrorException("Vendor not found");
        }
        vendor.setVendorstatusFlag(vendorDTO.getVendorstatusFlag());
        VendorEntity updatedVendor = vendorRepository.save(vendor);
        VendorDTO dto = new VendorDTO();
        dto.setVendorId(updatedVendor.getVendorId());
        dto.setVendorstatusFlag(updatedVendor.getVendorstatusFlag());
        return dto;
    }

    @Override
    public long saveAvailability(@Valid AvailabilityDTO availabilityDTO, String token) {

        AvailabilityEntity entity = new AvailabilityEntity();
        try {
            BeanUtils.copyProperties(availabilityDTO, entity);
            Jwt jwtDetails = tokenService.decodeJWTToken(token.substring(7));
            Long userId = Long.parseLong(jwtDetails.getClaim("scope").toString());
            entity.setAvailabilityCreatedBy(userId);
            entity.setAvailabilityUpdatedBy(userId);
            entity.setAvailabilityCreatedOn(LocalDateTime.now());
            entity.setAvailabilityUpdatedOn(LocalDateTime.now());
            entity.setAvailabilityDeleteFlag(false);
            AvailabilityEntity ret = availabilityRepo.save(entity);
            return ret.getAvailabilityId();
        } catch (DataIntegrityViolationException e) {
            String rootCauseMessage = e.getMostSpecificCause().getMessage();
            if (rootCauseMessage.contains("unique constraint") || rootCauseMessage.contains("Duplicate entry")) {
                throw new ItemExistsException("Duplicate entry detected.");
            } else if (rootCauseMessage.contains("foreign key constraint")) {
                throw new ConstrainViolationException("Invalid reference detected.");
            } else if (rootCauseMessage.contains("cannot be null")) {
                throw new NotNullException("Required field missing.");
            } else {
                throw e;
            }
        } catch (Exception ex) {
            throw ex;
        }
    }

    @Override
    public List<AvailabilityDTO> getAllAvailabilityList() {
        List<AvailabilityDTO> dtoList = new ArrayList<>();
        try {
            List<AvailabilityEntity> entityList = availabilityRepo.findByAvailabilityDeleteFlag(false);
            for (AvailabilityEntity entity : entityList) {
                AvailabilityDTO dto = new AvailabilityDTO();
                BeanUtils.copyProperties(entity, dto);
                dtoList.add(dto);
            }
        } catch (Exception ex) {
            throw ex;
        }
        return dtoList;
    }

    @Override
    public AvailabilityDTO getAvailabilityById(Long availabilityId) {
        return availabilityRepo.findById(availabilityId).map(entity -> {
            AvailabilityDTO dto = new AvailabilityDTO();
            BeanUtils.copyProperties(entity, dto);
            return dto;
        }).orElseThrow(() -> new ItemNotFoundException("Availability not found with id " + availabilityId));
    }

    @Override
    public AvailabilityDTO updateAvailability(@Valid AvailabilityDTO availabilityDTO, String token) {
        try {
            AvailabilityEntity entity = availabilityRepo.findById(availabilityDTO.getAvailabilityId())
                    .orElseThrow(() -> new ItemNotFoundException(
                            "Availability not found with id " + availabilityDTO.getAvailabilityId()));
            Jwt jwtDetails = tokenService.decodeJWTToken(token.substring(7));
            Long userId = Long.parseLong(jwtDetails.getClaim("scope").toString());
            entity.setAvailabilityUpdatedBy(userId);
            entity.setAvailabilityName(availabilityDTO.getAvailabilityName());
            entity.setAvailabilityDescription(availabilityDTO.getAvailabilityDescription());
            entity.setAvailabilityUpdatedOn(LocalDateTime.now());
            entity.setAvailabilityDeleteFlag(false);
            AvailabilityEntity savedEntity = availabilityRepo.save(entity);
            AvailabilityDTO responseDto = new AvailabilityDTO();
            BeanUtils.copyProperties(savedEntity, responseDto);
            return responseDto;
        } catch (DataIntegrityViolationException e) {
            String rootCauseMessage = e.getMostSpecificCause().getMessage();
            if (rootCauseMessage.contains("unique constraint") || rootCauseMessage.contains("Duplicate entry")) {
                throw new ItemExistsException("Duplicate entry detected.");
            } else if (rootCauseMessage.contains("foreign key constraint")) {
                throw new ConstrainViolationException("Invalid reference detected.");
            } else if (rootCauseMessage.contains("cannot be null")) {
                throw new NotNullException("Required field missing.");
            } else {
                throw e;
            }
        } catch (Exception ex) {
            throw ex;
        }
    }

    @Override
    public AvailabilityDTO deleteAvailability(Long availabilityId, String token) {
        AvailabilityDTO dto = new AvailabilityDTO();
        try {
            Optional<AvailabilityEntity> availability = availabilityRepo.findById(availabilityId);
            Jwt jwtDetails = tokenService.decodeJWTToken(token.substring(7));
            Long userId = Long.parseLong(jwtDetails.getClaim("scope").toString());
            availability.get().setAvailabilityUpdatedBy(userId);
            availability.get().setAvailabilityDeleteFlag(true);
            availability.get().setAvailabilityUpdatedOn(LocalDateTime.now());
            AvailabilityEntity ret = availabilityRepo.save(availability.get());
            BeanUtils.copyProperties(ret, dto);
            if (ret != null) {
                return dto;
            } else {
                return null;
            }
        } catch (DataIntegrityViolationException e) {
            String rootCauseMessage = e.getMostSpecificCause().getMessage();
            if (rootCauseMessage.contains("unique constraint") || rootCauseMessage.contains("Duplicate entry")) {
                throw new ItemExistsException("Duplicate entry detected.");
            } else if (rootCauseMessage.contains("foreign key constraint")) {
                throw new ConstrainViolationException("Invalid reference detected.");
            } else if (rootCauseMessage.contains("cannot be null")) {
                throw new NotNullException("Required field missing.");
            } else {
                throw e;
            }
        } catch (Exception ex) {
            throw ex;
        }
    }

    private static final int SEARCH_RESULT_LIMIT = 15;

    @Override
    @Transactional
    public List<TaskComponentDTO> searchComponentList(String query) {
        List<TaskComponentDTO> list = new ArrayList<>();

        if (query == null || query.trim().isEmpty()) {
            List<InspectionTaskComponentEntity> entities = taskComponentRepo.findAllActive();
            for (InspectionTaskComponentEntity entity : entities) {
                list.add(mapToDTO(entity));
            }
        } else {
            Pageable limit = PageRequest.of(0, SEARCH_RESULT_LIMIT);
            List<Object[]> results = taskComponentRepo.searchByNameWithPriority(query.trim().toLowerCase(), limit);
            for (Object[] row : results) {
                InspectionTaskComponentEntity entity = (InspectionTaskComponentEntity) row[0];
                list.add(mapToDTO(entity));
            }
        }
        return list;
    }

    private TaskComponentDTO mapToDTO(InspectionTaskComponentEntity entity) {
        TaskComponentDTO dto = new TaskComponentDTO();
        dto.setItcId(entity.getItcId());
        dto.setItcName(entity.getItcName());
        dto.setItcDescription(entity.getItcDescription());
        dto.setItcCategoryId(entity.getItcCategoryId());
        dto.setAllowGood(entity.getAllowGood());
        dto.setAllowRepair(entity.getAllowRepair());
        dto.setAllowReplace(entity.getAllowReplace());
        dto.setAllowPoor(entity.getAllowPoor());
        dto.setAllowPhoto(entity.getAllowPhoto());
        dto.setAllowAudio(entity.getAllowAudio());
        dto.setAllowMultipleImage(entity.getAllowMultipleImage());
        dto.setAllowVideo(entity.getAllowVideo());
        dto.setPhotoMandatory(entity.getPhotoMandatory());
        dto.setAudioMandatory(entity.getAudioMandatory());
        dto.setAllowNotApplicable(entity.getAllowNotApplicable());
        dto.setInstructionText(entity.getInstructionText());
        dto.setItcCreatedOn(entity.getItcCreatedOn());
        dto.setItcCreatedBy(entity.getItcCreatedBy());
        return dto;
    }

    @Override
    public long saveAssemblyCode(@Valid AssemblyCodeDTO assemblyCodeDTO, String token) {
        if (assemblyCodeRepo.existsByAssemblyCodeAndAssemblyCodeDeleteFlag(assemblyCodeDTO.getAssemblyCode(), false)) {
            throw new ItemExistsException("Assembly Code already exists.");
        }
        AssemblyCodeEntity entity = new AssemblyCodeEntity();
        try {
            BeanUtils.copyProperties(assemblyCodeDTO, entity);
            Jwt jwtDetails = tokenService.decodeJWTToken(token.substring(7));
            Long userId = Long.parseLong(jwtDetails.getClaim("scope").toString());
            entity.setAssemblyCodeCreatedBy(userId);
            entity.setAssemblyCodeUpdatedBy(userId);
            entity.setAssemblyCodeCreatedOn(LocalDateTime.now());
            entity.setAssemblyCodeUpdatedOn(LocalDateTime.now());
            entity.setAssemblyCodeDeleteFlag(false);
            AssemblyCodeEntity ret = assemblyCodeRepo.save(entity);
            return ret.getAssemblyCodeId();
        } catch (Exception ex) {
            throw ex;
        }
    }

    @Override
    public List<AssemblyCodeDTO> getAllAssemblyCodeList() {
        List<AssemblyCodeDTO> dtoList = new ArrayList<>();
        List<AssemblyCodeEntity> entityList = assemblyCodeRepo.findByAssemblyCodeDeleteFlag(false);
        for (AssemblyCodeEntity entity : entityList) {
            AssemblyCodeDTO dto = new AssemblyCodeDTO();
            BeanUtils.copyProperties(entity, dto);
            dtoList.add(dto);
        }
        return dtoList;
    }

    @Override
    public AssemblyCodeDTO getAssemblyCodeById(Long assemblyCodeId) {
        return assemblyCodeRepo.findById(assemblyCodeId).map(entity -> {
            AssemblyCodeDTO dto = new AssemblyCodeDTO();
            BeanUtils.copyProperties(entity, dto);
            return dto;
        }).orElseThrow(() -> new ItemNotFoundException("Assembly Code not found with id " + assemblyCodeId));
    }

    @Override
    public AssemblyCodeDTO updateAssemblyCode(@Valid AssemblyCodeDTO assemblyCodeDTO, String token) {
        AssemblyCodeEntity entity = assemblyCodeRepo.findById(assemblyCodeDTO.getAssemblyCodeId())
                .orElseThrow(() -> new ItemNotFoundException(
                        "Assembly Code not found with id " + assemblyCodeDTO.getAssemblyCodeId()));
        Jwt jwtDetails = tokenService.decodeJWTToken(token.substring(7));
        Long userId = Long.parseLong(jwtDetails.getClaim("scope").toString());
        entity.setAssemblyCode(assemblyCodeDTO.getAssemblyCode());
        entity.setAssemblyCodeDesc(assemblyCodeDTO.getAssemblyCodeDesc());
        entity.setAssemblyCodeUpdatedBy(userId);
        entity.setAssemblyCodeUpdatedOn(LocalDateTime.now());
        AssemblyCodeEntity savedEntity = assemblyCodeRepo.save(entity);
        AssemblyCodeDTO dto = new AssemblyCodeDTO();
        BeanUtils.copyProperties(savedEntity, dto);
        return dto;
    }

    @Override
    public AssemblyCodeDTO deleteAssemblyCode(Long assemblyCodeId, String token) {
        AssemblyCodeEntity entity = assemblyCodeRepo.findById(assemblyCodeId)
                .orElseThrow(() -> new ItemNotFoundException("Assembly Code not found with id " + assemblyCodeId));
        Jwt jwtDetails = tokenService.decodeJWTToken(token.substring(7));
        Long userId = Long.parseLong(jwtDetails.getClaim("scope").toString());
        entity.setAssemblyCodeDeleteFlag(true);
        entity.setAssemblyCodeUpdatedBy(userId);
        entity.setAssemblyCodeUpdatedOn(LocalDateTime.now());
        AssemblyCodeEntity savedEntity = assemblyCodeRepo.save(entity);
        AssemblyCodeDTO dto = new AssemblyCodeDTO();
        BeanUtils.copyProperties(savedEntity, dto);
        return dto;
    }

    @Override
    public long saveRepairGroup(@Valid RepairGroupDTO repairGroupDTO, String token) {
        if (repairGroupRepo.existsByRepairGroupNameAndAssemblyCodeIdAndRepairGroupDeleteFlag(
                repairGroupDTO.getRepairGroupName(), repairGroupDTO.getAssemblyCodeId(), false)) {
            throw new ItemExistsException("Repair Group already exists for the selected Assembly Code.");
        }
        try {
            RepairGroupEntity entity = new RepairGroupEntity();
            BeanUtils.copyProperties(repairGroupDTO, entity);
            Jwt jwtDetails = tokenService.decodeJWTToken(token.substring(7));
            Long userId = Long.parseLong(jwtDetails.getClaim("scope").toString());
            entity.setRepairGroupCreatedBy(userId);
            entity.setRepairGroupUpdatedBy(userId);
            entity.setRepairGroupCreatedOn(LocalDateTime.now());
            entity.setRepairGroupUpdatedOn(LocalDateTime.now());
            entity.setRepairGroupDeleteFlag(false);
            RepairGroupEntity saved = repairGroupRepo.save(entity);
            return saved.getRepairGroupId();
        } catch (Exception ex) {
            throw ex;
        }
    }

    @Override
    public List<RepairGroupDTO> getAllRepairGroupList() {
        List<RepairGroupDTO> dtoList = new ArrayList<>();
        List<RepairGroupEntity> entityList = repairGroupRepo.findByRepairGroupDeleteFlag(false);
        for (RepairGroupEntity entity : entityList) {
            RepairGroupDTO dto = new RepairGroupDTO();
            BeanUtils.copyProperties(entity, dto);
            if (entity.getAssemblyCodeId() != null) {
                assemblyCodeRepo.findById(entity.getAssemblyCodeId()).ifPresent(ac -> {
                    dto.setAssemblyCode(ac.getAssemblyCode());
                    dto.setAssemblyCodeDesc(ac.getAssemblyCodeDesc());
                });
            }
            dtoList.add(dto);
        }
        return dtoList;
    }

    @Override
    public RepairGroupDTO getRepairGroupById(Long repairGroupId) {
        return repairGroupRepo.findById(repairGroupId).map(entity -> {
            RepairGroupDTO dto = new RepairGroupDTO();
            BeanUtils.copyProperties(entity, dto);
            return dto;
        }).orElseThrow(() -> new ItemNotFoundException("Repair Group not found"));
    }

    @Override
    public RepairGroupDTO updateRepairGroup(@Valid RepairGroupDTO repairGroupDTO, String token) {
        RepairGroupEntity entity = repairGroupRepo.findById(repairGroupDTO.getRepairGroupId())
                .orElseThrow(() -> new ItemNotFoundException("Repair Group not found"));
        Jwt jwtDetails = tokenService.decodeJWTToken(token.substring(7));
        Long userId = Long.parseLong(jwtDetails.getClaim("scope").toString());
        entity.setRepairGroupName(repairGroupDTO.getRepairGroupName());
        entity.setAssemblyCodeId(repairGroupDTO.getAssemblyCodeId());
        entity.setRepairGroupDesc(repairGroupDTO.getRepairGroupDesc());
        entity.setRepairGroupUpdatedBy(userId);
        entity.setRepairGroupUpdatedOn(LocalDateTime.now());
        RepairGroupEntity saved = repairGroupRepo.save(entity);
        RepairGroupDTO dto = new RepairGroupDTO();
        BeanUtils.copyProperties(saved, dto);
        return dto;
    }

    @Override
    public RepairGroupDTO deleteRepairGroup(Long repairGroupId, String token) {
        RepairGroupEntity entity = repairGroupRepo.findById(repairGroupId)
                .orElseThrow(() -> new ItemNotFoundException("Repair Group not found"));
        Jwt jwtDetails = tokenService.decodeJWTToken(token.substring(7));
        Long userId = Long.parseLong(jwtDetails.getClaim("scope").toString());
        entity.setRepairGroupDeleteFlag(true);
        entity.setRepairGroupUpdatedBy(userId);
        entity.setRepairGroupUpdatedOn(LocalDateTime.now());
        RepairGroupEntity saved = repairGroupRepo.save(entity);
        RepairGroupDTO dto = new RepairGroupDTO();
        BeanUtils.copyProperties(saved, dto);
        return dto;
    }

    @Override
    public List<RepairGroupDTO> getRepairGroupByAssemblyCodeId(Long assemblyCodeId) {
        List<RepairGroupDTO> dtoList = new ArrayList<>();
        List<RepairGroupEntity> entityList = repairGroupRepo
                .findByAssemblyCodeIdAndRepairGroupDeleteFlag(assemblyCodeId, false);
        for (RepairGroupEntity entity : entityList) {
            RepairGroupDTO dto = new RepairGroupDTO();
            BeanUtils.copyProperties(entity, dto);
            dtoList.add(dto);
        }
        return dtoList;
    }
}
