package com.alm.inspectionModule.settingsModule.repo;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.alm.inspectionModule.settingsModule.entity.AssemblyCodeEntity;

@Repository
public interface AssemblyCodeRepo extends JpaRepository<AssemblyCodeEntity, Long> {

    boolean existsByAssemblyCodeAndAssemblyCodeDeleteFlag(String assemblyCode, Boolean assemblyCodeDeleteFlag);

    List<AssemblyCodeEntity> findByAssemblyCodeDeleteFlag(Boolean deleteFlag);

}
