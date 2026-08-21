package com.alm.inspectionModule.vehicleInspection.serviceImpl;

import java.time.LocalDateTime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;

import org.apache.commons.io.FilenameUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.security.oauth2.jwt.Jwt;

import com.alm.inspectionModule.exception.ConstrainViolationException;
import com.alm.inspectionModule.exception.InternalErrorException;
import com.alm.inspectionModule.exception.ItemExistsException;
import com.alm.inspectionModule.exception.NotNullException;
import com.alm.inspectionModule.jobcardModule.dto.BasicInspectionAttachmentsDTO;
import com.alm.inspectionModule.jobcardModule.dto.InspectionAttachmentGroupDTO;
import com.alm.inspectionModule.jobcardModule.entity.JobCardEntity;
import com.alm.inspectionModule.jobcardModule.entity.JobCardLogEntity;
import com.alm.inspectionModule.jobcardModule.repo.JobCardLogRepository;
import com.alm.inspectionModule.jobcardModule.repo.JobCardRepository;
import com.alm.inspectionModule.reportModule.entity.InspectionReportEntity;
import com.alm.inspectionModule.reportModule.service.InspectionReportService;
import com.alm.inspectionModule.userModule.entity.UserDetailsEntity;
import com.alm.inspectionModule.userModule.repo.INSPUserDetailsRepository;
import com.alm.inspectionModule.settingsModule.dto.InspectionAttachmentsDTO;
import com.alm.inspectionModule.settingsModule.dto.MediaFileDTO;
import com.alm.inspectionModule.settingsModule.dto.TaskComponentDTO;
import com.alm.inspectionModule.settingsModule.dto.UploadInspectionPayloadDTO;
import com.alm.inspectionModule.settingsModule.entity.AssemblyCodeEntity;
import com.alm.inspectionModule.settingsModule.entity.InspectionAttachmentsEntity;
import com.alm.inspectionModule.settingsModule.entity.InspectionImageMasterEntity;
import com.alm.inspectionModule.settingsModule.entity.InspectionSettingsMasterEntity;
import com.alm.inspectionModule.settingsModule.entity.InspectionTaskComponentEntity;
import com.alm.inspectionModule.settingsModule.entity.RepairGroupEntity;
import com.alm.inspectionModule.settingsModule.entity.TaskCategoryEntity;
import com.alm.inspectionModule.settingsModule.repo.AssemblyCodeRepo;
import com.alm.inspectionModule.settingsModule.repo.InspectionAttachmentsRepo;
import com.alm.inspectionModule.settingsModule.repo.InspectionImageMasterRepo;
import com.alm.inspectionModule.settingsModule.repo.RepairGroupRepo;
import com.alm.inspectionModule.settingsModule.repo.TaskComponentRepo;
import com.alm.inspectionModule.utils.AwsS3Services;
import com.alm.inspectionModule.utils.TokenService;
import com.alm.inspectionModule.vehicleInspection.dto.VehicleInspectionMasterDTO;
import com.alm.inspectionModule.vehicleInspection.dto.VehicleInspectionResponseDTO;
import com.alm.inspectionModule.vehicleInspection.dto.VehicleInspectionTaskDTO;
import com.alm.inspectionModule.vehicleInspection.entity.InspectionFormComponentMappingEntity;
import com.alm.inspectionModule.vehicleInspection.entity.VehicleEssentialDetailsEntity;
import com.alm.inspectionModule.vehicleInspection.entity.VehicleInspectionEntity;
import com.alm.inspectionModule.vehicleInspection.entity.VehicleInspectionMasterEntity;
import com.alm.inspectionModule.vehicleInspection.repo.InspectionFormComponentMappingRepo;
import com.alm.inspectionModule.vehicleInspection.repo.VehicleEssentialDetailsRepo;
import com.alm.inspectionModule.vehicleInspection.repo.VehicleInspectionMasterRepo;
import com.alm.inspectionModule.vehicleInspection.repo.VehicleInspectionRepo;
import com.alm.inspectionModule.vehicleInspection.service.VehicleInspectionService;
import com.alm.inspectionModule.vehicleModule.entity.VehicleEntity;
import com.alm.inspectionModule.vehicleModule.repo.VehicleRepository;

import jakarta.transaction.Transactional;

@Service
public class VehicleInspectionServiceImpl implements VehicleInspectionService {

    @Autowired
    private VehicleInspectionMasterRepo masterRepo;

    @Autowired
    private VehicleInspectionRepo childRepo;

    @Autowired
    private TokenService tokenService;

    @Autowired
    private InspectionAttachmentsRepo attachRepo;

    @Autowired
    private AwsS3Services s3Service;

    @Autowired
    private VehicleEssentialDetailsRepo vehicleEssentialDetailsRepo;

    @Autowired
    private TaskComponentRepo componentRepo;

    @Autowired
    private JobCardRepository jobCardRepo;

    @Autowired
    private InspectionFormComponentMappingRepo inspectionFormComponentMappingRepo;

    @Autowired
    private VehicleRepository vehicleRepo;

    @Autowired
    private InspectionImageMasterRepo imageMasterRepo;

    @Autowired
    private InspectionReportService reportService;

    @Autowired
    private JobCardLogRepository jobCardLogRepository;

    @Autowired
    private INSPUserDetailsRepository userRepository;

    @Autowired
    private AssemblyCodeRepo assemblyCodeRepo;

    @Autowired
    private RepairGroupRepo repairGroupRepo;

    @Autowired
    private com.alm.inspectionModule.jobcardModule.repo.InspectionRepository inspectionReportRepository;

    @Autowired
    private com.alm.inspectionModule.quotationModule.repo.QuotationReportRepository quotationReportRepository;

    private java.util.Map<Long, java.math.BigDecimal> getRejectedComponentIdsForJob(Long jobId) {
        java.util.Map<Long, java.math.BigDecimal> map = new java.util.HashMap<>();
        if (jobId != null) {
            java.util.Optional<com.alm.inspectionModule.jobcardModule.entity.JobCardInspectionEntity> inspectionOpt = inspectionReportRepository
                    .findByJobId(jobId);
            if (inspectionOpt.isPresent()) {
                List<com.alm.inspectionModule.jobcardModule.entity.QuotationReportEntity> quotationItems = quotationReportRepository
                        .findByInspectionReport_IirId(inspectionOpt.get().getIirId());
                if (quotationItems != null) {
                    for (com.alm.inspectionModule.jobcardModule.entity.QuotationReportEntity q : quotationItems) {
                        if (q.getStatus() != null && q.getStatus() == 1) {
                            map.put(q.getComponentItemId(), q.getLabourUnit());
                        }
                    }
                }
            }
        }
        return map;
    }

    @Value("${app.s3.inspection-path}")
    private String inspectionPath;

    @Override
    @Transactional
    public Object saveInspection(Map<String, Object> payload, String token) {
        try {
            Jwt jwtDetails = tokenService.decodeJWTToken(token.substring(7));
            Long userId = Long.valueOf(jwtDetails.getClaim("scope").toString());
            VehicleInspectionMasterEntity master = new VehicleInspectionMasterEntity();
            master.setVimJobId(Long.valueOf(payload.get("vimJobId").toString()));
            master.setVimIfMasterId(Long.valueOf(payload.get("vimIfMasterId").toString()));
            LocalDateTime now = LocalDateTime.now();
            master.setVimCreatedOn(now);
            master.setVimUpdatedOn(now);
            master.setVimCreatedBy(userId);
            master.setVimUpdatedBy(userId);
            master.setVimDeleteFlag(false);
            VehicleInspectionMasterEntity savedMaster = masterRepo.save(master);
            Long masterId = savedMaster.getVimId();
            List<Map<String, Object>> categories = (List<Map<String, Object>>) payload.get("categories");
            if (categories != null) {
                for (Map<String, Object> category : categories) {
                    List<Map<String, Object>> tasks = (List<Map<String, Object>>) category.get("tasks");
                    if (tasks != null) {
                        for (Map<String, Object> task : tasks) {
                            boolean isInserted = task.get("inserted") != null
                                    && Boolean.parseBoolean(task.get("inserted").toString());
                            if (isInserted) {
                                continue;
                            }
                            VehicleInspectionEntity child = new VehicleInspectionEntity();
                            child.setViVimId(masterId);
                            child.setViTaskId(Long.valueOf(task.get("viTaskId").toString()));
                            child.setViGood(Boolean.valueOf(task.get("viGood").toString()));
                            child.setViRepair(Boolean.valueOf(task.get("viRepair").toString()));
                            child.setViPoor(Boolean.valueOf(task.get("viPoor").toString()));
                            child.setViReplace(Boolean.valueOf(task.get("viReplace").toString()));
                            child.setViNote(task.get("viNote") != null ? task.get("viNote").toString() : "");
                            child.setViDescription(
                                    task.get("viDescription") != null ? task.get("viDescription").toString() : "");
                            child.setViCreatedOn(now);
                            child.setViUpdatedOn(now);
                            child.setViCreatedBy(userId);
                            child.setViUpdatedBy(userId);
                            child.setViDeleteFlag(false);
                            childRepo.save(child);
                        }
                    }
                }
            }
            return savedMaster;
        } catch (DataIntegrityViolationException e) {
            String msg = e.getMostSpecificCause().getMessage();
            if (msg.contains("Duplicate entry")) {
                throw new ItemExistsException("Duplicate entry detected.");
            }
            if (msg.contains("foreign key constraint")) {
                throw new ConstrainViolationException("Invalid reference detected.");
            }
            if (msg.contains("cannot be null")) {
                throw new NotNullException("Required field missing.");
            }
            throw e;
        }
    }

    @Override
    @Transactional
    public Object saveSingleTask(Map<String, Object> payload, List<MultipartFile> imageFiles, MultipartFile audioFile,
            MultipartFile videoFile, String token) {
        Jwt jwtDetails = tokenService.decodeJWTToken(token.substring(7));
        Long userId = Long.valueOf(jwtDetails.getClaim("scope").toString());
        LocalDateTime now = LocalDateTime.now();
        Long jobId = Long.valueOf(payload.get("vimJobId").toString());
        Long ifMasterId = null;
        if (payload.get("vimIfMasterId") != null && !payload.get("vimIfMasterId").toString().trim().isEmpty()
                && !payload.get("vimIfMasterId").toString().equals("null")) {
            ifMasterId = Long.valueOf(payload.get("vimIfMasterId").toString());
        }
        Integer inspectionType = payload.get("vimInspectionType") != null
                ? Integer.valueOf(payload.get("vimInspectionType").toString())
                : (ifMasterId != null ? 1 : 2);
        Long technicianId = payload.get("technicianId") != null
                && !payload.get("technicianId").toString().equals("null")
                        ? Long.valueOf(payload.get("technicianId").toString())
                        : userId;
        VehicleInspectionMasterEntity master = null;
        JobCardEntity job = jobCardRepo.findById(jobId).orElseThrow(() -> new RuntimeException("Job not found"));
        Integer currentJobStatus = job.getJobStatus();
        if (currentJobStatus != null) {
            boolean isReinspectionActive = (currentJobStatus == 10 || currentJobStatus == 11 || currentJobStatus == 14
                    || currentJobStatus == 15 || currentJobStatus == 16 || currentJobStatus == 17 || currentJobStatus == 18);
            if (currentJobStatus >= 6 && !isReinspectionActive) {
                throw new RuntimeException("Modification not allowed: Inspection report has been submitted/locked.");
            }
        }
        if (payload.get("status") != null) {
            Integer newStatus = Integer.valueOf(payload.get("status").toString());
            Integer oldStatus = job.getJobStatus();
            if (!newStatus.equals(oldStatus)) {
                job.setJobStatus(newStatus);
                job.setJobUpdatedBy(userId);
                job.setJobUpdatedOn(now);
                jobCardRepo.save(job);
                saveJobLog(jobId, newStatus, userId);
            }
        }
        if (ifMasterId != null) {
            Optional<VehicleInspectionMasterEntity> existingMaster = masterRepo
                    .findByVimJobIdAndVimInspectionTypeAndVimIfMasterIdAndVimDeleteFlag(jobId,
                            inspectionType, ifMasterId, false);
            if (existingMaster.isPresent()) {
                master = existingMaster.get();
            }
        } else {
            Integer jobStatus = job.getJobStatus();
            boolean isReinspection = (jobStatus != null && (jobStatus == 10 || jobStatus == 11 || jobStatus == 12
                    || jobStatus == 14 || jobStatus == 15 || jobStatus == 16 || jobStatus == 17 || jobStatus == 18));
            List<VehicleInspectionMasterEntity> customMasters = masterRepo.findAllCustomInspectionsByJobId(jobId,
                    false);
            if (isReinspection) {
                if (customMasters.size() > 1) {
                    master = customMasters.get(customMasters.size() - 1);
                }
            } else {
                if (!customMasters.isEmpty()) {
                    master = customMasters.get(0);
                }
            }
        }

        if (master != null) {
            master.setVimUpdatedBy(userId);
            master.setVimUpdatedOn(now);
            master = masterRepo.save(master);
        } else {
            master = new VehicleInspectionMasterEntity();
            master.setVimJobId(jobId);
            master.setVimIfMasterId(ifMasterId); // null for custom
            master.setVimInspectionType(inspectionType); // 1 or 2
            master.setVimTechnicianId(technicianId); // set technician
            master.setVimCreatedBy(userId);
            master.setVimUpdatedBy(userId);
            master.setVimCreatedOn(now);
            master.setVimUpdatedOn(now);
            master.setVimDeleteFlag(false);
            if (job.getCustomerComplaint() != null) {
                master.setVimAdditionalComments(job.getCustomerComplaint());
            }
            master = masterRepo.save(master);
        }
        if (payload.get("vimAdditionalComments") != null) {
            String comments = payload.get("vimAdditionalComments").toString();
            master.setVimAdditionalComments(comments);
            master = masterRepo.save(master);

            // Also update the job card's customer complaint
            jobCardRepo.findById(jobId).ifPresent(jcard -> {
                jcard.setCustomerComplaint(comments);
                jobCardRepo.save(jcard);
            });

            // Synchronize all other active inspection masters for this job card
            List<VehicleInspectionMasterEntity> masters = masterRepo.findAllByVimJobIdAndVimDeleteFlag(jobId, false);
            for (VehicleInspectionMasterEntity m : masters) {
                if (!m.getVimId().equals(master.getVimId())) {
                    m.setVimAdditionalComments(comments);
                    masterRepo.save(m);
                }
            }
        }
        Long masterId = master.getVimId();
        Long taskId = Long.valueOf(payload.get("viTaskId").toString());
        Boolean viGood = Boolean.valueOf(payload.get("viGood").toString());
        Boolean viRepair = Boolean.valueOf(payload.get("viRepair").toString());
        Boolean viPoor = Boolean.valueOf(payload.get("viPoor").toString());
        Boolean viReplace = Boolean.valueOf(payload.get("viReplace").toString());
        Boolean viNotApplicable = Boolean.valueOf(payload.get("viNotApplicable").toString());
        String viNote = payload.get("viNote") != null ? payload.get("viNote").toString() : "";
        String viDescription = payload.get("viDescription") != null ? payload.get("viDescription").toString() : "";
        InspectionTaskComponentEntity taskComponent = componentRepo.findById(taskId)
                .orElseThrow(() -> new RuntimeException("Task component not found: " + taskId));

        Optional<VehicleInspectionEntity> existingChild = childRepo.findByViVimIdAndViTaskIdAndViDeleteFlag(masterId,
                taskId, false);
        VehicleInspectionEntity child;
        if (existingChild.isPresent()) {
            child = existingChild.get();
            child.setViUpdatedBy(userId);
            child.setViUpdatedOn(now);
        } else {
            child = new VehicleInspectionEntity();
            child.setViVimId(masterId);
            child.setTaskComponent(taskComponent);
            child.setViCreatedBy(userId);
            child.setViCreatedOn(now);
            child.setViUpdatedBy(userId);
            child.setViUpdatedOn(now);
            child.setViDeleteFlag(false);
        }

        child.setViGood(viGood);
        child.setViRepair(viRepair);
        child.setViPoor(viPoor);
        child.setViReplace(viReplace);
        child.setViNotApplicable(viNotApplicable);
        child.setViNote(viNote);
        child.setViDescription(viDescription);

        if (payload.get("viReInspection") != null) {
            child.setViReInspection(Boolean.valueOf(payload.get("viReInspection").toString()));
        }
        if (payload.get("viReInspectionTime") != null) {
            child.setViReInspectionTime(new java.math.BigDecimal(payload.get("viReInspectionTime").toString()));
        }

        VehicleInspectionEntity savedChild = childRepo.save(child);
        VehicleEntity vehicle = job.getVehicle();
        String folderPath = buildInspectionFolderPath(vehicle.getvVinNo(), jobId);
        if (Boolean.TRUE.equals(taskComponent.getAllowPhoto()) && imageFiles != null && !imageFiles.isEmpty()) {
            attachRepo.softDeleteAttachments(masterId, taskId, 0L, now, userId);
            if (Boolean.FALSE.equals(taskComponent.getAllowMultipleImage())) {
                MultipartFile firstImage = imageFiles.get(0);
                if (firstImage != null && !firstImage.isEmpty()) {
                    String imageUrl = uploadToS3(firstImage, folderPath);
                    saveAttachment(imageUrl, 0, masterId, taskId, jobId, userId);
                }
            } else {
                for (MultipartFile image : imageFiles) {
                    if (image != null && !image.isEmpty()) {
                        String imageUrl = uploadToS3(image, folderPath);
                        saveAttachment(imageUrl, 0, masterId, taskId, jobId, userId);
                    }
                }
            }
        }
        if (audioFile != null && !audioFile.isEmpty()) {
            attachRepo.softDeleteAttachments(masterId, taskId, 1L, now, userId);
            String audioUrl = uploadToS3(audioFile, folderPath);
            saveAttachment(audioUrl, 1, masterId, taskId, jobId, userId);
        }
        if (Boolean.TRUE.equals(taskComponent.getAllowVideo()) && videoFile != null && !videoFile.isEmpty()) {
            attachRepo.softDeleteAttachments(masterId, taskId, 2L, now, userId);
            String videoUrl = uploadToS3(videoFile, folderPath);
            saveAttachment(videoUrl, 2, masterId, taskId, jobId, userId);
        }
        Map<String, Object> response = new HashMap<>();
        response.put("inserted", true);
        response.put("viId", savedChild.getViId());
        response.put("viVimId", masterId);
        response.put("viTaskId", taskId);
        response.put("viGood", viGood);
        response.put("viRepair", viRepair);
        response.put("viPoor", viPoor);
        response.put("viReplace", viReplace);
        response.put("viNote", viNote);
        response.put("viDescription", viDescription);
        return response;
    }

    private String uploadToS3(MultipartFile file, String folderPath) {
        try {
            long maxSize = 100L * 1024 * 1024; // 100 MB
            if (file.getSize() > maxSize)
                throw new RuntimeException("File too large (max 100MB)");
            String original = FilenameUtils.getName(file.getOriginalFilename());
            String unique = System.currentTimeMillis() + "_" + original;
            return s3Service.uploadFile(folderPath + "/" + unique, file);
        } catch (Exception e) {
            throw new InternalErrorException("Failed to upload file to S3: " + e.getMessage());
        }
    }

    private void saveAttachment(String url, int type, Long vimIfMasterId, Long taskId, Long jobId, Long userId) {
        InspectionAttachmentsEntity ia = new InspectionAttachmentsEntity();
        ia.setIaUrl(url);
        ia.setIaType(Long.valueOf(type));
        ia.setIaInspectionId(vimIfMasterId);
        ia.setIaInspectionType(Long.valueOf(0));
        ia.setIaInspectionTaskId(taskId);
        ia.setIaJobcardId(jobId);
        ia.setIaImageType(Long.valueOf(0));
        ia.setIaCreatedOn(LocalDateTime.now());
        ia.setIaUpdatedOn(LocalDateTime.now());
        ia.setIaCreatedBy(userId);
        ia.setIaUpdatedBy(userId);
        ia.setIaDeleteFlag(false);
        attachRepo.save(ia);
    }

    @Override
    @Transactional
    public List<VehicleInspectionResponseDTO> getInspectionsByJobId(Long jobId) {
        List<VehicleInspectionMasterEntity> masterEntities = masterRepo.findAllByVimJobIdAndVimDeleteFlag(jobId, false);
        if (masterEntities.isEmpty()) {
            return Collections.emptyList();
        }
        java.util.Map<Long, java.math.BigDecimal> rejectedComponentMap = getRejectedComponentIdsForJob(jobId);
        JobCardEntity jobCard = jobCardRepo.findById(jobId).orElse(null);
        String customerComplaint = jobCard != null ? jobCard.getCustomerComplaint() : null;
        List<VehicleInspectionResponseDTO> responses = new ArrayList<>();
        for (VehicleInspectionMasterEntity masterEntity : masterEntities) {
            Long ifMasterId = masterEntity.getVimIfMasterId();
            String formName;
            if (ifMasterId == null) {
                formName = "Custom Inspection";
            } else if (ifMasterId == 0L) {
                formName = "Basic Inspection";
            } else {
                formName = masterRepo.findInspectionFormNameByIfMasterId(ifMasterId);
            }
            VehicleInspectionMasterDTO masterDTO = new VehicleInspectionMasterDTO();
            masterDTO.setVimId(masterEntity.getVimId());
            masterDTO.setVimJobId(masterEntity.getVimJobId());
            masterDTO.setVimIfMasterId(masterEntity.getVimIfMasterId());
            masterDTO.setFormName(formName);
            masterDTO.setVimInspectionType(masterEntity.getVimInspectionType());
            masterDTO.setVimDocType(masterEntity.getVimDocType());
            masterDTO.setVimNote(masterEntity.getVimNote());
            masterDTO.setVimEssentialImage(masterEntity.getVimEssentialImage());

            String additionalComments = masterEntity.getVimAdditionalComments();
            if ((additionalComments == null || additionalComments.trim().isEmpty()) && customerComplaint != null) {
                additionalComments = customerComplaint;
                masterEntity.setVimAdditionalComments(additionalComments);
                masterRepo.save(masterEntity);
            }
            masterDTO.setVimAdditionalComments(additionalComments);
            masterDTO.setVimSupervisorComment(masterEntity.getVimSupervisorComment());
            masterDTO.setVimSaComment(masterEntity.getVimSaComment());
            masterDTO.setVimCreatedOn(masterEntity.getVimCreatedOn());
            masterDTO.setVimCreatedBy(masterEntity.getVimCreatedBy());
            masterDTO.setVimUpdatedOn(masterEntity.getVimUpdatedOn());
            masterDTO.setVimUpdatedBy(masterEntity.getVimUpdatedBy());
            masterDTO.setVimTechnicianId(masterEntity.getVimTechnicianId());
            masterDTO.setVimDeleteFlag(masterEntity.getVimDeleteFlag());
            List<VehicleInspectionEntity> taskEntities = childRepo.findAllByViVimId(masterEntity.getVimId());
            List<VehicleInspectionTaskDTO> taskDTOs = new ArrayList<>();
            for (VehicleInspectionEntity task : taskEntities) {
                VehicleInspectionTaskDTO dto = new VehicleInspectionTaskDTO();
                dto.setViId(task.getViId());
                dto.setViVimId(task.getViVimId());
                dto.setViTaskId(task.getViTaskId());
                dto.setTaskName(task.getTaskComponent().getItcName());
                dto.setViGood(task.getViGood());
                dto.setViRepair(task.getViRepair());
                dto.setViPoor(task.getViPoor());
                dto.setViReplace(task.getViReplace());
                dto.setViNotApplicable(task.getViNotApplicable());
                dto.setViNote(task.getViNote());
                dto.setViDescription(task.getViDescription());
                dto.setViModifiedPrevCondition(task.getViModifiedPrevCondition());
                dto.setViModifiedNewCondition(task.getViModifiedNewCondition());
                dto.setViModifiedByName(task.getViModifiedByName());
                dto.setViModifiedDate(task.getViModifiedDate());
                boolean viReInspection = Boolean.TRUE.equals(task.getViReInspection());
                dto.setViReInspection(viReInspection);
                dto.setViReInspectionTime(task.getViReInspectionTime());
                dto.setViCreatedOn(task.getViCreatedOn());
                dto.setViCreatedBy(task.getViCreatedBy());
                dto.setViUpdatedOn(task.getViUpdatedOn());
                dto.setViUpdatedBy(task.getViUpdatedBy());
                dto.setViDeleteFlag(task.getViDeleteFlag());
                taskDTOs.add(dto);
            }
            VehicleInspectionResponseDTO resp = new VehicleInspectionResponseDTO(masterDTO, Collections.emptyList());
            responses.add(resp);
        }
        return responses;
    }

    @Transactional
    public List<Map<String, Object>> getInspectionGroupedByCategory(Long vimId) {
        VehicleInspectionMasterEntity master = masterRepo.findById(vimId).orElse(null);
        Long jobId = (master != null) ? master.getVimJobId() : null;
        java.util.Map<Long, java.math.BigDecimal> rejectedComponentMap = getRejectedComponentIdsForJob(jobId);
        List<Object[]> rows = childRepo.findInspectionWithComponentAndCategory(vimId);
        Map<Long, Map<String, Object>> categoryMap = new LinkedHashMap<>();
        for (Object[] row : rows) {
            VehicleInspectionEntity inspection = (VehicleInspectionEntity) row[0];
            InspectionTaskComponentEntity itc = (InspectionTaskComponentEntity) row[1];
            TaskCategoryEntity category = (TaskCategoryEntity) row[2];

            // Skip components that were rejected for reinspection
            if (rejectedComponentMap.containsKey(itc.getItcId())) {
                continue;
            }
            categoryMap.putIfAbsent(category.getTaskCategoryId(), new HashMap<>());
            Map<String, Object> categoryNode = categoryMap.get(category.getTaskCategoryId());
            categoryNode.putIfAbsent("taskCategoryId", category.getTaskCategoryId());
            categoryNode.putIfAbsent("taskCategoryName", category.getTaskCategoryName());
            categoryNode.putIfAbsent("tasks", new ArrayList<>());
            Map<String, Object> taskNode = new HashMap<>();
            taskNode.put("viId", inspection.getViId());
            taskNode.put("viVimId", inspection.getViVimId());
            taskNode.put("viTaskId", inspection.getViTaskId());
            taskNode.put("taskComponentId", itc.getItcId());
            taskNode.put("taskName", itc.getItcName());
            taskNode.put("description", itc.getItcDescription());
            taskNode.put("viGood", inspection.getViGood());
            taskNode.put("viRepair", inspection.getViRepair());
            taskNode.put("viPoor", inspection.getViPoor());
            taskNode.put("viReplace", inspection.getViReplace());
            taskNode.put("viNote", inspection.getViNote());
            taskNode.put("viDescription", inspection.getViDescription());
            taskNode.put("viNotApplicable", inspection.getViNotApplicable());
            Long compId = itc.getItcId();
            boolean viReInspection = Boolean.TRUE.equals(inspection.getViReInspection())
                    && !rejectedComponentMap.containsKey(compId);
            taskNode.put("viReInspection", viReInspection);
            java.math.BigDecimal reTime = inspection.getViReInspectionTime();
            if (reTime == null && rejectedComponentMap.containsKey(compId)) {
                reTime = rejectedComponentMap.get(compId);
            }
            taskNode.put("viReInspectionTime", reTime);
            Map<String, Object> flags = new HashMap<>();
            flags.put("good", itc.getAllowGood());
            flags.put("repair", itc.getAllowRepair());
            flags.put("replace", itc.getAllowReplace());
            flags.put("poor", itc.getAllowPoor());
            flags.put("photo", itc.getAllowPhoto());
            flags.put("audio", itc.getAllowAudio());
            flags.put("notApplicable", itc.getAllowNotApplicable());
            taskNode.put("inspectionTaskFlags", flags);
            ((List<Map<String, Object>>) categoryNode.get("tasks")).add(taskNode);
        }
        return new ArrayList<>(categoryMap.values());
    }

    @Override
    public List<Map<String, Object>> getInspectionWithTaskCategory(Long vimId) {
        return null;
    }

    @Override
    @Transactional
    public Object uploadInspectionMedia(UploadInspectionPayloadDTO payload, String token) {
        Jwt jwt = tokenService.decodeJWTToken(token.substring(7));
        Long userId = Long.valueOf(jwt.getClaim("scope").toString());
        LocalDateTime now = LocalDateTime.now();
        JobCardEntity job = jobCardRepo.findById(payload.getJobId())
                .orElseThrow(() -> new RuntimeException("Job not found"));
        if (payload.getStatus() != null) {
            Integer newStatus = payload.getStatus();
            Integer oldStatus = job.getJobStatus();
            if (!newStatus.equals(oldStatus)) {
                job.setJobStatus(newStatus);
                job.setJobUpdatedBy(userId);
                job.setJobUpdatedOn(LocalDateTime.now());
                jobCardRepo.save(job);
                saveJobLog(job.getJobId(), newStatus, userId);
            }
        }
        if (payload.getAdditionalComment() != null && !payload.getAdditionalComment().isBlank()) {
            VehicleInspectionMasterEntity inspection = masterRepo
                    .findFirstByVimJobIdAndVimDeleteFlag(payload.getJobId(), false)
                    .orElseThrow(() -> new RuntimeException("Inspection not found"));
            String comments = payload.getAdditionalComment();
            inspection.setVimAdditionalComments(comments);
            inspection.setVimUpdatedBy(userId);
            inspection.setVimUpdatedOn(now);
            masterRepo.save(inspection);

            job.setCustomerComplaint(comments);
            jobCardRepo.save(job);

            // Synchronize all other active inspection masters for this job card
            List<VehicleInspectionMasterEntity> masters = masterRepo
                    .findAllByVimJobIdAndVimDeleteFlag(payload.getJobId(), false);
            for (VehicleInspectionMasterEntity m : masters) {
                if (!m.getVimId().equals(inspection.getVimId())) {
                    m.setVimAdditionalComments(comments);
                    masterRepo.save(m);
                }
            }
        }
        InspectionImageMasterEntity imageMaster = null;
        if (payload.getInspectionImageId() != null) {
            imageMaster = imageMasterRepo.findById(payload.getInspectionImageId()).orElse(null);
        }
        if (imageMaster == null && payload.getAttachType() != 11 && payload.getAttachType() != 12
                && payload.getAttachType() != 15) {
            throw new RuntimeException("Image master not found");
        }
        VehicleEntity vehicle = job.getVehicle();
        String vinNo = vehicle.getvVinNo();
        String folderPath = buildInspectionFolderPath(vinNo, payload.getJobId());
        List<Map<String, Object>> uploadedList = new ArrayList<>();
        if (payload.getMediaFiles() != null) {
            for (MediaFileDTO media : payload.getMediaFiles()) {
                MultipartFile file = media.getFile();
                if (file == null || file.isEmpty())
                    continue;
                String fileUrl;
                try {
                    fileUrl = uploadToS3(file, folderPath);
                } catch (Exception e) {
                    throw new InternalErrorException("S3 upload failed: " + e.getMessage());
                }
                InspectionAttachmentsEntity ia = new InspectionAttachmentsEntity();
                ia.setIaJobcardId(payload.getJobId());
                ia.setIaUrl(fileUrl);
                ia.setIaType(Long.valueOf(media.getType()));
                ia.setIaImageType(Long.valueOf(payload.getAttachType()));
                ia.setIaInspectionType(0L);
                ia.setIaImageId(imageMaster);
                ia.setIaInspectionNote(payload.getInspectionNote() == null ? null : payload.getInspectionNote());
                ia.setIaCreatedOn(now);
                ia.setIaUpdatedOn(now);
                ia.setIaCreatedBy(userId);
                ia.setIaUpdatedBy(userId);
                ia.setIaDeleteFlag(false);
                attachRepo.save(ia);
                Map<String, Object> one = new HashMap<>();
                one.put("url", fileUrl);
                one.put("type", media.getType());
                uploadedList.add(one);
            }
        }
        Map<String, Object> response = new HashMap<>();
        response.put("uploaded", true);
        response.put("jobId", payload.getJobId());
        response.put("count", uploadedList.size());
        response.put("files", uploadedList);
        return response;
    }

    @Override
    @Transactional
    public Object saveVehicleEssentialDetails(Map<String, Object> payload, MultipartFile essentinalImage,
            String token) {
        try {
            Jwt jwtDetails = tokenService.decodeJWTToken(token.substring(7));
            Long userId = Long.valueOf(jwtDetails.getClaim("scope").toString());
            LocalDateTime now = LocalDateTime.now();
            Long jobId = Long.valueOf(payload.get("jobId").toString());
            Long vId = Long.valueOf(payload.get("vId").toString());
            Integer type = Integer.valueOf(payload.get("type").toString());
            Integer docType = Integer.valueOf(payload.get("docType").toString());
            String note = payload.get("note") != null ? payload.get("note").toString() : null;
            if (payload.get("status") != null) {
                Integer jobStatus = Integer.valueOf(payload.get("status").toString());
                JobCardEntity job = jobCardRepo.findById(jobId)
                        .orElseThrow(() -> new RuntimeException("Job not found"));
                job.setJobStatus(jobStatus);
                job.setJobUpdatedBy(userId);
                job.setJobUpdatedOn(now);
                jobCardRepo.save(job);
                saveJobLog(jobId, jobStatus, userId);
            }
            VehicleInspectionMasterEntity master = new VehicleInspectionMasterEntity();
            master.setVimJobId(jobId);
            master.setVimInspectionType(type);
            master.setVimNote(note);
            master.setVimIfMasterId(0L);
            master.setVimCreatedBy(userId);
            master.setVimCreatedOn(now);
            master.setVimDeleteFlag(false);
            master.setVimDocType(docType);
            JobCardEntity job = jobCardRepo.findById(jobId).orElseThrow(() -> new RuntimeException("Job not found"));
            String customerComplaint = payload.get("customerComplaint") != null
                    ? payload.get("customerComplaint").toString()
                    : null;
            if (customerComplaint != null && !customerComplaint.trim().isEmpty()) {
                job.setCustomerComplaint(customerComplaint);
                master.setVimAdditionalComments(customerComplaint);
                jobCardRepo.save(job);
            } else if (job.getCustomerComplaint() != null) {
                master.setVimAdditionalComments(job.getCustomerComplaint());
            }
            VehicleEntity vehicle = job.getVehicle();
            String folderPath = buildInspectionFolderPath(vehicle.getvVinNo(), jobId);
            if (essentinalImage != null && !essentinalImage.isEmpty()) {
                String imageUrl = uploadToS3(essentinalImage, folderPath);
                master.setVimEssentialImage(imageUrl);
            }
            VehicleInspectionMasterEntity savedMaster = masterRepo.save(master);
            Long vimId = savedMaster.getVimId();
            @SuppressWarnings("unchecked")
            List<?> veIdsRaw = (List<?>) payload.get("veId");
            List<Long> veIds = veIdsRaw.stream().map(id -> Long.valueOf(id.toString())).toList();
            for (Long veId : veIds) {
                VehicleEssentialDetailsEntity child = new VehicleEssentialDetailsEntity();
                child.setJobId(jobId);
                child.setVId(vId);
                child.setVeId(veId);
                child.setVimId(vimId);
                child.setVehicleEssentialCreatedBy(userId);
                child.setVehicleEssentialCreatedOn(now);
                child.setVehicleEssentialDeleteFlag(false);
                vehicleEssentialDetailsRepo.save(child);
            }
            Map<String, Object> response = new LinkedHashMap<>();
            response.put("vimId", vimId);
            response.put("jobId", jobId);
            response.put("savedCount", veIds.size());
            response.put("vimEssentialImage", savedMaster.getVimEssentialImage());
            response.put("message", "Vehicle essential details saved successfully");
            return response;
        } catch (Exception e) {
            throw new InternalErrorException("Failed to save vehicle essential details: " + e.getMessage());
        }
    }

    @Override
    @Transactional
    public Object getBasicInspectionByJobId(Long jobId) {
        VehicleInspectionMasterEntity master = masterRepo
                .findTopByVimJobIdAndVimInspectionTypeAndVimDeleteFlagOrderByVimIdDesc(jobId, 0, false)
                .orElseThrow(() -> new RuntimeException("Basic inspection not found for job id : " + jobId));
        Long vimId = master.getVimId();
        List<VehicleEssentialDetailsEntity> essentials = vehicleEssentialDetailsRepo
                .findAllByVimIdAndVehicleEssentialDeleteFlag(vimId, false);
        List<InspectionAttachmentsEntity> attachments = attachRepo.findByIaJobcardIdAndIaDeleteFlag(jobId, false);
        BasicInspectionAttachmentsDTO grouped = groupBasicInspectionAttachments(attachments);
        Map<String, Object> response = new LinkedHashMap<>();
        JobCardEntity jobcard = jobCardRepo.findById(jobId)
                .orElseThrow(() -> new RuntimeException("Jobcard not found"));
        VehicleEntity vehicle = jobcard.getVehicle();
        response.put("vFuelMark", vehicle.getvFuelMark());
        response.put("jobId", jobId);
        response.put("vimId", vimId);
        response.put("jobInspectionType",
                jobcard.getInspectionType() != null ? jobcard.getInspectionType().name() : "GENERAL");
        response.put("inspectionType", 0);
        response.put("note", master.getVimNote());
        response.put("essentinalImage", master.getVimEssentialImage());
        response.put("vimDocType", master.getVimDocType());
        response.put("createdOn", master.getVimCreatedOn());
        String additionalComments = master.getVimAdditionalComments();
        if ((additionalComments == null || additionalComments.trim().isEmpty())
                && jobcard.getCustomerComplaint() != null) {
            additionalComments = jobcard.getCustomerComplaint();
            master.setVimAdditionalComments(additionalComments);
            masterRepo.save(master);
        }
        response.put("vimAdditionalComments", additionalComments != null ? additionalComments : "");
        response.put("essentialDetails", essentials);
        response.put("basicinspectionattachments", grouped);
        return response;
    }

    private BasicInspectionAttachmentsDTO groupBasicInspectionAttachments(List<InspectionAttachmentsEntity> list) {
        Map<Long, InspectionAttachmentGroupDTO> externalMap = new LinkedHashMap<>();
        Map<Long, InspectionAttachmentGroupDTO> internalMap = new LinkedHashMap<>();
        Map<Long, InspectionAttachmentGroupDTO> quickMap = new LinkedHashMap<>();
        InspectionAttachmentGroupDTO additionalGroup = new InspectionAttachmentGroupDTO();
        additionalGroup.setImageMasterId(-50L);
        additionalGroup.setLabel("Additional Images");
        additionalGroup.setAttachments(new ArrayList<>());

        boolean isJobQuick = false;
        if (list != null && !list.isEmpty()) {
            Long jobId = list.stream().map(InspectionAttachmentsEntity::getIaJobcardId).filter(Objects::nonNull)
                    .findFirst().orElse(null);
            if (jobId != null) {
                JobCardEntity job = jobCardRepo.findById(jobId).orElse(null);
                if (job != null && job
                        .getInspectionType() == com.alm.inspectionModule.jobcardModule.entity.InspectionType.QUICK) {
                    isJobQuick = true;
                }
            }
        }

        String cardiagram = null;
        String signature = null;
        if (list == null)
            return new BasicInspectionAttachmentsDTO(List.of(), List.of(), null, null);
        for (InspectionAttachmentsEntity a : list) {
            if (Boolean.TRUE.equals(a.getIaDeleteFlag()))
                continue;
            if (a.getIaInspectionType() == null || a.getIaInspectionType() != 0)
                continue;
            if (a.getIaImageType() != null) {
                if (a.getIaImageType() == 11) {
                    cardiagram = a.getIaUrl();
                    continue;
                }
                if (a.getIaImageType() == 12) {
                    signature = a.getIaUrl();
                    continue;
                }
                if (a.getIaImageType() == 15L) {
                    InspectionAttachmentsDTO dto = new InspectionAttachmentsDTO();
                    dto.setIaId(a.getIaId());
                    dto.setIaUrl(a.getIaUrl());
                    dto.setIaType(a.getIaType());
                    dto.setIaInspectionId(a.getIaInspectionId());
                    dto.setIaInspectionType(a.getIaInspectionType());
                    dto.setIaInspectionTaskId(a.getIaInspectionTaskId());
                    dto.setIaImageType(a.getIaImageType());
                    dto.setIaJobcardId(a.getIaJobcardId());
                    dto.setIaInspectionNote(a.getIaInspectionNote() == null ? "" : a.getIaInspectionNote());
                    dto.setIaImageId(null);
                    dto.setIaCreatedOn(a.getIaCreatedOn());
                    dto.setIaCreatedBy(a.getIaCreatedBy());
                    dto.setIaUpdatedOn(a.getIaUpdatedOn());
                    dto.setIaUpdatedBy(a.getIaUpdatedBy());
                    dto.setIaDeleteFlag(a.getIaDeleteFlag());
                    additionalGroup.getAttachments().add(dto);
                    continue;
                }
            }
            InspectionImageMasterEntity master = a.getIaImageId();
            if (master == null)
                continue;
            InspectionSettingsMasterEntity settings = master.getSettings();
            if (settings == null)
                continue;
            boolean isExternal = settings.getInspectionId() == 1;
            boolean isQuick = false;
            if (a.getIaImageType() != null) {
                isQuick = a.getIaImageType() == 14L || (isJobQuick && a.getIaImageType() == 0L);
            } else if (isJobQuick) {
                isQuick = true;
            }
            Map<Long, InspectionAttachmentGroupDTO> target;
            if (isQuick) {
                target = quickMap;
            } else {
                target = isExternal ? externalMap : internalMap;
            }
            Long masterId = master.getImageId();
            InspectionAttachmentGroupDTO group = target.computeIfAbsent(masterId, id -> {
                InspectionAttachmentGroupDTO g = new InspectionAttachmentGroupDTO();
                g.setImageMasterId(master.getImageId());
                g.setLabel(master.getImageLabel());
                g.setImageCount(master.getImageCount());
                g.setVideoFlag(master.getVideoFlag());
                g.setVideoDuration(master.getVideoDuration());
                g.setAttachments(new ArrayList<>());
                return g;
            });
            InspectionAttachmentsDTO dto = new InspectionAttachmentsDTO();
            dto.setIaId(a.getIaId());
            dto.setIaUrl(a.getIaUrl());
            dto.setIaType(a.getIaType());
            dto.setIaInspectionId(a.getIaInspectionId());
            dto.setIaInspectionType(a.getIaInspectionType());
            dto.setIaInspectionTaskId(a.getIaInspectionTaskId());
            dto.setIaImageType(a.getIaImageType());
            dto.setIaJobcardId(a.getIaJobcardId());
            dto.setIaInspectionNote(a.getIaInspectionNote());
            dto.setIaImageId(null);
            dto.setIaCreatedOn(a.getIaCreatedOn());
            dto.setIaCreatedBy(a.getIaCreatedBy());
            dto.setIaUpdatedOn(a.getIaUpdatedOn());
            dto.setIaUpdatedBy(a.getIaUpdatedBy());
            dto.setIaDeleteFlag(a.getIaDeleteFlag());
            group.getAttachments().add(dto);
        }
        BasicInspectionAttachmentsDTO result = new BasicInspectionAttachmentsDTO(new ArrayList<>(externalMap.values()),
                new ArrayList<>(internalMap.values()), cardiagram, signature);
        result.setQuickInspectionImages(new ArrayList<>(quickMap.values()));
        if (!additionalGroup.getAttachments().isEmpty()) {
            result.setAdditionalImages(List.of(additionalGroup));
        } else {
            result.setAdditionalImages(List.of());
        }
        return result;
    }

    @Override
    @Transactional
    public Object getInspectionStatusByJobId(Long jobId) {
        List<VehicleInspectionMasterEntity> inspectionMasters = masterRepo.findAllByVimJobIdAndVimDeleteFlag(jobId,
                false);
        if (inspectionMasters.isEmpty()) {
            throw new RuntimeException("No inspections found for this job");
        }
        java.util.Map<Long, java.math.BigDecimal> rejectedComponentMap = getRejectedComponentIdsForJob(jobId);
        List<InspectionAttachmentsEntity> allTaskAttachments = attachRepo.findTaskAttachmentsByJobId(jobId);
        Map<Long, List<InspectionAttachmentsEntity>> attachmentMap = allTaskAttachments.stream()
                .collect(Collectors.groupingBy(InspectionAttachmentsEntity::getIaInspectionTaskId));
        Map<String, AssemblyCodeEntity> assemblyCodeMap = assemblyCodeRepo.findAll().stream()
                .collect(Collectors.toMap(AssemblyCodeEntity::getAssemblyCode, a -> a, (a, b) -> a));
        Map<Long, RepairGroupEntity> repairGroupMap = repairGroupRepo.findAll().stream()
                .collect(Collectors.toMap(RepairGroupEntity::getRepairGroupId, r -> r, (a, b) -> a));
        List<Map<String, Object>> inspections = new ArrayList<>();
        for (VehicleInspectionMasterEntity master : inspectionMasters) {
            Long vimId = master.getVimId();
            Long inspectionFormId = master.getVimIfMasterId();
            List<InspectionFormComponentMappingEntity> mappings = inspectionFormComponentMappingRepo
                    .findByInspectionFormInspectionFormIdAndInspectionFormComponentDeleteFlagFalse(inspectionFormId);
            List<VehicleInspectionTaskDTO> completed = new ArrayList<>();
            List<TaskComponentDTO> pending = new ArrayList<>();
            if (!mappings.isEmpty()) {
                List<Long> componentIds = mappings.stream().map(m -> m.getTaskComponent().getItcId()).toList();
                List<InspectionTaskComponentEntity> allComponents = componentRepo.findAllById(componentIds);
                List<VehicleInspectionEntity> completedTasks = childRepo.findAllByViVimId(vimId);
                Map<Long, VehicleInspectionEntity> completedTaskMap = completedTasks.stream()
                        .filter(v -> v.getTaskComponent() != null || v.getViTaskId() != null)
                        .collect(Collectors.toMap(
                                v -> v.getTaskComponent() != null ? v.getTaskComponent().getItcId() : v.getViTaskId(),
                                v -> v));
                for (InspectionTaskComponentEntity component : allComponents) {
                    Long componentId = component.getItcId();
                    if (completedTaskMap.containsKey(componentId)) {
                        VehicleInspectionEntity vi = completedTaskMap.get(componentId);
                        VehicleInspectionTaskDTO dto = new VehicleInspectionTaskDTO();
                        dto.setViId(vi.getViId());
                        dto.setViVimId(vi.getViVimId());
                        dto.setViTaskId(componentId);
                        dto.setTaskName(component.getItcName());
                        dto.setViGood(vi.getViGood());
                        dto.setViRepair(vi.getViRepair());
                        dto.setViPoor(vi.getViPoor());
                        dto.setViReplace(vi.getViReplace());
                        dto.setViNotApplicable(vi.getViNotApplicable());
                        dto.setViNote(vi.getViNote());
                        dto.setViDescription(vi.getViDescription());
                        dto.setViModifiedPrevCondition(vi.getViModifiedPrevCondition());
                        dto.setViModifiedNewCondition(vi.getViModifiedNewCondition());
                        dto.setViModifiedByName(vi.getViModifiedByName());
                        dto.setViModifiedDate(vi.getViModifiedDate());
                        boolean viReInspection = Boolean.TRUE.equals(vi.getViReInspection())
                                && !rejectedComponentMap.containsKey(componentId);
                        dto.setViReInspection(viReInspection);
                        java.math.BigDecimal reTime = vi.getViReInspectionTime();
                        if (reTime == null && rejectedComponentMap.containsKey(componentId)) {
                            reTime = rejectedComponentMap.get(componentId);
                        }
                        dto.setViReInspectionTime(reTime);
                        dto.setItcAssemblyCode(component.getItcAssemblyCode());
                        dto.setItcRepairGroup(component.getItcRepairGroup());
                        if (component.getItcAssemblyCode() != null) {
                            AssemblyCodeEntity ac = assemblyCodeMap.get(component.getItcAssemblyCode());
                            if (ac != null) {
                                dto.setAssemblyCodeName(ac.getAssemblyCode());
                                dto.setAssemblyCodeDesc(ac.getAssemblyCodeDesc());
                            }
                        }
                        if (component.getItcRepairGroup() != null) {
                            try {
                                Long rgId = Long.parseLong(component.getItcRepairGroup());
                                RepairGroupEntity rg = repairGroupMap.get(rgId);
                                if (rg != null) {
                                    dto.setRepairGroupName(rg.getRepairGroupName());
                                    dto.setRepairGroupDesc(rg.getRepairGroupDesc());
                                }
                            } catch (NumberFormatException ignored) {
                            }
                        }
                        List<Map<String, Object>> attachments = attachmentMap
                                .getOrDefault(componentId, Collections.emptyList()).stream().map(a -> {
                                    Map<String, Object> m = new LinkedHashMap<>();
                                    m.put("id", a.getIaId());
                                    m.put("url", a.getIaUrl());
                                    m.put("type", a.getIaType());
                                    m.put("imageType", a.getIaImageType());
                                    return m;
                                }).toList();
                        dto.setAttachments(attachments);
                        completed.add(dto);
                    } else {
                        TaskComponentDTO dto = toTaskComponentDTO(component, assemblyCodeMap, repairGroupMap);
                        pending.add(dto);
                    }
                }
            } else {
                List<VehicleInspectionEntity> completedTasks = childRepo.findAllByViVimId(vimId);
                for (VehicleInspectionEntity vi : completedTasks) {
                    InspectionTaskComponentEntity tc = vi.getTaskComponent();
                    VehicleInspectionTaskDTO dto = new VehicleInspectionTaskDTO();
                    dto.setViId(vi.getViId());
                    dto.setViVimId(vi.getViVimId());
                    dto.setViTaskId(vi.getTaskComponent().getItcId());
                    dto.setTaskName(vi.getTaskComponent().getItcName());
                    dto.setViGood(vi.getViGood());
                    dto.setViRepair(vi.getViRepair());
                    dto.setViPoor(vi.getViPoor());
                    dto.setViReplace(vi.getViReplace());
                    dto.setViNotApplicable(vi.getViNotApplicable());
                    dto.setViNote(vi.getViNote());
                    dto.setViDescription(vi.getViDescription());
                    dto.setViModifiedPrevCondition(vi.getViModifiedPrevCondition());
                    dto.setViModifiedNewCondition(vi.getViModifiedNewCondition());
                    dto.setViModifiedByName(vi.getViModifiedByName());
                    dto.setViModifiedDate(vi.getViModifiedDate());
                    Long compId = vi.getTaskComponent().getItcId();
                    boolean viReInspection = Boolean.TRUE.equals(vi.getViReInspection())
                            && !rejectedComponentMap.containsKey(compId);
                    dto.setViReInspection(viReInspection);
                    java.math.BigDecimal reTime = vi.getViReInspectionTime();
                    if (reTime == null && rejectedComponentMap.containsKey(compId)) {
                        reTime = rejectedComponentMap.get(compId);
                    }
                    dto.setViReInspectionTime(reTime);
                    dto.setItcAssemblyCode(tc.getItcAssemblyCode());
                    dto.setItcRepairGroup(tc.getItcRepairGroup());
                    if (tc.getItcAssemblyCode() != null) {
                        AssemblyCodeEntity ac = assemblyCodeMap.get(tc.getItcAssemblyCode());
                        if (ac != null) {
                            dto.setAssemblyCodeName(ac.getAssemblyCode());
                            dto.setAssemblyCodeDesc(ac.getAssemblyCodeDesc());
                        }
                    }
                    if (tc.getItcRepairGroup() != null) {
                        try {
                            Long rgId = Long.parseLong(tc.getItcRepairGroup());
                            RepairGroupEntity rg = repairGroupMap.get(rgId);
                            if (rg != null) {
                                dto.setRepairGroupName(rg.getRepairGroupName());
                                dto.setRepairGroupDesc(rg.getRepairGroupDesc());
                            }
                        } catch (NumberFormatException ignored) {
                        }
                    }
                    List<Map<String, Object>> attachments = attachmentMap
                            .getOrDefault(vi.getTaskComponent().getItcId(), Collections.emptyList()).stream().map(a -> {
                                Map<String, Object> m = new LinkedHashMap<>();
                                m.put("id", a.getIaId());
                                m.put("url", a.getIaUrl());
                                m.put("type", a.getIaType());
                                m.put("imageType", a.getIaImageType());
                                return m;
                            }).toList();
                    dto.setAttachments(attachments);
                    completed.add(dto);
                }
            }
            Map<String, Object> masterMap = new LinkedHashMap<>();
            masterMap.put("vimId", master.getVimId());
            masterMap.put("vimInspectionType", master.getVimInspectionType());
            masterMap.put("vimIfMasterId", master.getVimIfMasterId());

            Map<String, Object> inspectionNode = new LinkedHashMap<>();
            inspectionNode.put("vimId", vimId);
            inspectionNode.put("inspectionFormId", inspectionFormId);
            inspectionNode.put("master", masterMap);
            inspectionNode.put("completedCount", completed.size());
            inspectionNode.put("pendingCount", pending.size());
            inspectionNode.put("completedTasks", completed);
            inspectionNode.put("pendingTasks", pending);
            inspections.add(inspectionNode);
        }
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("jobId", jobId);
        response.put("inspectionCount", inspections.size());
        response.put("inspections", inspections);
        return response;
    }

    private String buildInspectionFolderPath(String vinNo, Long jobId) {
        if (vinNo == null || vinNo.isBlank()) {
            throw new IllegalArgumentException("VIN number is required to build inspection folder path");
        }
        if (jobId == null || jobId <= 0) {
            throw new IllegalArgumentException("Valid jobId is required to build inspection folder path");
        }
        return inspectionPath + "/" + vinNo + "/job_" + jobId;
    }

    private TaskComponentDTO toTaskComponentDTO(InspectionTaskComponentEntity e,
            Map<String, AssemblyCodeEntity> assemblyCodeMap, Map<Long, RepairGroupEntity> repairGroupMap) {
        TaskComponentDTO dto = new TaskComponentDTO();
        dto.setItcId(e.getItcId());
        dto.setItcName(e.getItcName());
        dto.setItcDescription(e.getItcDescription());
        dto.setAllowGood(e.getAllowGood());
        dto.setAllowRepair(e.getAllowRepair());
        dto.setAllowReplace(e.getAllowReplace());
        dto.setAllowPoor(e.getAllowPoor());
        dto.setAllowNotApplicable(e.getAllowNotApplicable());
        dto.setAllowPhoto(e.getAllowPhoto());
        dto.setAllowAudio(e.getAllowAudio());
        dto.setPhotoMandatory(e.getPhotoMandatory());
        dto.setAudioMandatory(e.getAudioMandatory());
        dto.setItcCategoryId(e.getItcCategoryId());
        dto.setItcAssemblyCode(e.getItcAssemblyCode());
        dto.setItcRepairGroup(e.getItcRepairGroup());
        if (e.getItcAssemblyCode() != null) {
            AssemblyCodeEntity ac = assemblyCodeMap.get(e.getItcAssemblyCode());
            if (ac != null) {
                dto.setAssemblyCodeName(ac.getAssemblyCode());
                dto.setAssemblyCodeDesc(ac.getAssemblyCodeDesc());
            }
        }
        if (e.getItcRepairGroup() != null) {
            try {
                Long rgId = Long.parseLong(e.getItcRepairGroup());
                RepairGroupEntity rg = repairGroupMap.get(rgId);
                if (rg != null) {
                    dto.setRepairGroupName(rg.getRepairGroupName());
                    dto.setRepairGroupDesc(rg.getRepairGroupDesc());
                }
            } catch (NumberFormatException ignored) {
            }
        }
        return dto;
    }

    @Override
    public List<String> searchVehicleRegNo(String keyword) {

        if (keyword == null || keyword.trim().isEmpty()) {
            return Collections.emptyList();
        }

        keyword = keyword.trim();

        List<VehicleEntity> vehicles = vehicleRepo.searchVehicleRegNo(keyword, PageRequest.of(0, 20));

        return vehicles.stream().map(VehicleEntity::getvRegNo).filter(Objects::nonNull).distinct()
                .collect(Collectors.toList());
    }

    @Transactional
    public Object uploadCustomerSignature(String shareToken, MultipartFile file) {
        LocalDateTime now = LocalDateTime.now();
        InspectionReportEntity shareLink = reportService.validateToken(shareToken);
        Long jobId = shareLink.getJobId();
        JobCardEntity job = jobCardRepo.findById(jobId).orElseThrow(() -> new RuntimeException("Job not found"));
        VehicleEntity vehicle = job.getVehicle();
        String vinNo = vehicle.getvVinNo();
        String folderPath = buildInspectionFolderPath(vinNo, jobId);
        String fileUrl;
        try {
            fileUrl = uploadToS3(file, folderPath);
        } catch (Exception e) {
            throw new RuntimeException("S3 upload failed: " + e.getMessage());
        }
        InspectionAttachmentsEntity ia = new InspectionAttachmentsEntity();
        ia.setIaJobcardId(jobId);
        ia.setIaUrl(fileUrl);
        ia.setIaType(0L);
        ia.setIaImageType(13L);
        ia.setIaInspectionType(0L);
        ia.setIaCreatedBy(0L);
        ia.setIaUpdatedBy(0L);
        ia.setIaCreatedOn(now);
        ia.setIaUpdatedOn(now);
        ia.setIaDeleteFlag(false);
        attachRepo.save(ia);
        Map<String, Object> response = new HashMap<>();
        response.put("uploaded", true);
        response.put("url", fileUrl);
        return response;
    }

    private void saveJobLog(Long jobId, Integer status, Long userId) {
        JobCardLogEntity log = new JobCardLogEntity();
        log.setJobId(jobId);
        log.setJobStatus(status);
        log.setCreatedBy(userId);
        log.setCreatedOn(LocalDateTime.now());
        log.setUpdatedBy(userId);
        log.setUpdatedOn(LocalDateTime.now());
        log.setDeleteFlag(false);
        jobCardLogRepository.save(log);
    }

    @Override
    @Transactional
    public Object updateComponentCondition(Map<String, Object> payload, String token) {
        Long viId = Long.valueOf(payload.get("viId").toString());
        String newCondition = payload.get("newCondition").toString(); // "Good", "Repair", "Replace", "Poor", "Not
                                                                      // Applicable"

        VehicleInspectionEntity vi = childRepo.findById(viId)
                .orElseThrow(() -> new RuntimeException("Vehicle inspection task not found"));

        // Determine previous condition
        String prevCondition = "Good";
        if (Boolean.TRUE.equals(vi.getViRepair())) {
            prevCondition = "Repair";
        } else if (Boolean.TRUE.equals(vi.getViReplace())) {
            prevCondition = "Replace";
        } else if (Boolean.TRUE.equals(vi.getViPoor())) {
            prevCondition = "Poor";
        } else if (Boolean.TRUE.equals(vi.getViNotApplicable())) {
            prevCondition = "Not Applicable";
        }

        // Update flags based on newCondition
        vi.setViGood("Good".equalsIgnoreCase(newCondition));
        vi.setViRepair("Repair".equalsIgnoreCase(newCondition));
        vi.setViReplace("Replace".equalsIgnoreCase(newCondition));
        vi.setViPoor("Poor".equalsIgnoreCase(newCondition));
        vi.setViNotApplicable("Not Applicable".equalsIgnoreCase(newCondition) || "N/A".equalsIgnoreCase(newCondition));

        // Extract user info
        Jwt jwtDetails = tokenService.decodeJWTToken(token.startsWith("Bearer ") ? token.substring(7) : token);
        Long userId = Long.valueOf(jwtDetails.getClaim("scope").toString());
        UserDetailsEntity user = userRepository.findById(userId).orElse(null);
        String rolePrefix = "User";
        String userName = "Unknown User";
        if (user != null) {
            userName = user.getUserName();
            int dept = user.getUserDepartment();
            if (dept == 1) {
                rolePrefix = "Administrator";
            } else if (dept == 2) {
                rolePrefix = "Supervisor";
            } else if (dept == 3) {
                rolePrefix = "Service Advisor";
            } else if (dept == 4) {
                rolePrefix = "Technician";
            } else if (dept == 5) {
                rolePrefix = "Job Controller";
            }
        }
        String modifiedBy = rolePrefix + " " + userName;

        // Save audit info
        vi.setViModifiedPrevCondition(prevCondition);
        vi.setViModifiedNewCondition(newCondition);
        vi.setViModifiedByName(modifiedBy);
        vi.setViModifiedDate(LocalDateTime.now());
        vi.setViUpdatedOn(LocalDateTime.now());
        vi.setViUpdatedBy(userId);

        childRepo.save(vi);
        return "SUCCESS";
    }
}
