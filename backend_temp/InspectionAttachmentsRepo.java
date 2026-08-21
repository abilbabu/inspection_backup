package com.alm.inspectionModule.settingsModule.repo;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import com.alm.inspectionModule.settingsModule.entity.InspectionAttachmentsEntity;

/**
 * Repository for Inspection Attachments DYC - Document Your Code
 */
@Repository
public interface InspectionAttachmentsRepo extends JpaRepository<InspectionAttachmentsEntity, Long> {

	@Query("""
			    SELECT ia
			    FROM InspectionAttachmentsEntity ia
			    WHERE ia.iaJobcardId = :jobId
			      AND ia.iaInspectionType = 0
			      AND ia.iaDeleteFlag = false
			      AND ia.iaImageType IN :imageTypes
			""")
	List<InspectionAttachmentsEntity> findBasicInspectionAttachmentsByJobId(@Param("jobId") Long jobId,
			@Param("imageTypes") List<Integer> imageTypes);

	@Query("""
			 SELECT ia
			 FROM InspectionAttachmentsEntity ia
			 WHERE ia.iaJobcardId = :jobId
			   AND ia.iaInspectionTaskId IS NOT NULL
			   AND ia.iaDeleteFlag = false
			""")
	List<InspectionAttachmentsEntity> findTaskAttachmentsByJobId(@Param("jobId") Long jobId);

	@Query("""
				SELECT ia
				FROM InspectionAttachmentsEntity ia
				WHERE ia.iaJobcardId = :jobcardId
				  AND ia.iaInspectionId = :inspectionId
				  AND ia.iaDeleteFlag = false
			""")
	List<InspectionAttachmentsEntity> findAllByJobcardIdAndInspectionId(@Param("jobcardId") Long jobcardId,
			@Param("inspectionId") Long inspectionId);

	List<InspectionAttachmentsEntity> findByIaJobcardIdAndIaDeleteFlag(Long jobId, Boolean deleteFlag);

	@Modifying
	@Transactional
	@Query("""
			UPDATE InspectionAttachmentsEntity ia
			SET ia.iaDeleteFlag = true, ia.iaUpdatedOn = :now, ia.iaUpdatedBy = :userId
			WHERE ia.iaInspectionId = :inspectionId
			  AND ia.iaInspectionTaskId = :taskId
			  AND ia.iaType = :type
			  AND ia.iaDeleteFlag = false
			""")
	void softDeleteAttachments(@Param("inspectionId") Long inspectionId,
			@Param("taskId") Long taskId,
			@Param("type") Long type,
			@Param("now") java.time.LocalDateTime now,
			@Param("userId") Long userId);

}
