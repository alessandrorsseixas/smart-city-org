package br.com.smartcity.housecontrol.adapter.out.persistence;

import br.com.smartcity.housecontrol.domain.House;
import org.springframework.data.jpa.repository.JpaRepository;

public interface HouseRepository extends JpaRepository<House, String> {
}
