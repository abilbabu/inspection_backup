package com.alm.inspectionModule.vehicleInspection.repo;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.alm.inspectionModule.vehicleInspection.entity.InspectionFormComponentMappingEntity;

/**
 * Repository for Inspection Form → Component Mapping
 *
 * DYC - Document Your Code
 */
@Repository
public interface InspectionFormComponentMappingRepo extends JpaRepository<InspectionFormComponentMappingEntity, Long> {

    List<InspectionFormComponentMappingEntity> findByInspectionFormInspectionFormIdAndInspectionFormComponentDeleteFlagFalse(
            Long inspectionFormId);

    @org.springframework.data.jpa.repository.Query("SELECT m FROM InspectionFormComponentMappingEntity m " +
            "WHERE m.inspectionForm.inspectionFormId = :inspectionFormId " +
            "AND m.inspectionFormComponentDeleteFlag = false " +
            "AND m.taskComponent.itcDeleteFlag = false " +
            "AND (LOWER(REPLACE(REPLACE(m.taskComponent.itcName, ' ', ''), '-', '')) LIKE LOWER(CONCAT('%', :query, '%')) "
            +
            "OR LOWER(REPLACE(REPLACE(m.taskComponent.itcComponentNumber, ' ', ''), '-', '')) LIKE LOWER(CONCAT('%', :query, '%')) "
            +
            "OR LOWER(REPLACE(REPLACE(m.taskComponent.itcAssemblyCode, ' ', ''), '-', '')) LIKE LOWER(CONCAT('%', :query, '%')))")
    List<InspectionFormComponentMappingEntity> searchAssignedComponents(
            @org.springframework.data.repository.query.Param("inspectionFormId") Long inspectionFormId,
            @org.springframework.data.repository.query.Param("query") String query);
}
