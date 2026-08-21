package com.alm.inspectionModule.vehicleInspection.repo;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import com.alm.inspectionModule.vehicleInspection.entity.VehicleInspectionEntity;
import com.alm.inspectionModule.vehicleModule.entity.VehicleEntity;

/**
 * Repository for insp_vehicle_inspection table. DYC — Document Your Code.
 */
@Repository
public interface VehicleInspectionRepo extends JpaRepository<VehicleInspectionEntity, Long> {

    List<VehicleInspectionEntity> findAllByViVimId(Long viVimId);

    java.util.Optional<VehicleInspectionEntity> findByViVimIdAndViTaskIdAndViDeleteFlag(Long viVimId, Long viTaskId,
            Boolean deleteFlag);

    @Query("""
                SELECT vi, itc, tc
                FROM VehicleInspectionEntity vi
                LEFT JOIN vi.taskComponent itc
                       ON itc.itcDeleteFlag = false
                LEFT JOIN TaskCategoryEntity tc
                       ON tc.taskCategoryId = itc.itcCategoryId
                      AND tc.taskCategorydeleteFlag = false
                WHERE vi.viVimId = :vimId
                  AND vi.viDeleteFlag = false
            """)
    List<Object[]> findInspectionWithComponentAndCategory(@Param("vimId") Long vimId);

}
